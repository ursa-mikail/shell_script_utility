function start_js_app() {
    # Navigate to the project directory
    # cd /path/to/random-number-app
    
    # Start the Node.js server in the background
    node server.js &

    # Give the server a moment to start
    sleep 2

    # Open the application in Chrome
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome http://localhost:3000
}

function stop_js_app() {
    # Find the PID of the node process running server.js
    pid=$(pgrep -f "node server.js")
    
    if [ -z "$pid" ]; then
        echo "No node server.js process found"
    else
        # Kill the process
        kill "$pid"
        echo "Stopped node server.js process with PID: $pid"
    fi
}

function start_flask_app() {
    export FLASK_APP=app.py
    export FLASK_ENV=development
    flask run

    # Give the server a moment to start
    sleep 2

    # Open the application in Chrome
    #/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome http://localhost:5000
    #open -a "Google Chrome" http://127.0.0.1:5000
}

function stop_flask_app() {
    # Find the PID of the py process running app.py
    # pids=$(pgrep -f "/opt/anaconda3/bin/python /opt/anaconda3/bin/flask run")
    #pids=$(pgrep -f "python app.py")
    pids=$(pgrep -f "python app.py" | tr '\n' ' ')  # Convert newlines to spaces

    if [ -z "$pids" ]; then
        echo "No running Flask app found."
    else
        # Kill all matching PIDs
        echo "Stopping Flask app with PIDs: $pids"
        kill $pids
        echo "Flask app stopped."
    fi

    # if there is only 1 instance running
    pids=$(pgrep -f "python app.py")

    if [ -z "$pids" ]; then
        echo "No running Flask app found."
    else
        # Kill all matching PIDs
        echo "Stopping Flask app with PIDs: $pids"
        kill $pids
        echo "Flask app stopped."
    fi
}

function start_python_venv() {
    python3 -m venv venv
    source venv/bin/activate

    echo "start_python_venv [started]"
    # python3 -m pip install <package.name>
    # python3 -m pip install --upgrade pip
}  


function stop_python_venv() {
    deactivate 
    
    # Find the PIDs and ensure they are space-separated
    pids=$(pgrep -f "venv/bin/python")

    if [ -z "$pids" ]; then
        echo "No running [venv/bin/python] found."
    else
        # Kill all matching PIDs safely
        echo "Stopping [venv/bin/python] with PIDs: $pids"
        echo "$pids" | xargs kill -9
        echo "[venv/bin/python] stopped."
    fi

    ps aux | grep "venv/bin/python"
}

function python_install_package(){
  python3 -m pip install "$1"
}

echo ""
: <<'END'
install sshpass (only works on systems that allow password-based automation):

macOS (with Homebrew):
brew install hudochenkov/sshpass/sshpass

Ubuntu/Debian:
sudo apt install sshpass

Usage:
ssh_send_file n.txt               # Sends n.txt to /home/m/ on remote
ssh_get_file /home/m/n.txt        # Downloads n.txt from remote to current dir

You can also specify paths:
ssh_send_file notes.pdf /home/m/docs/
ssh_get_file /home/m/docs/notes.pdf ~/Downloads/

% ssh_send_file Makefile ./generate_large_primes
% ssh_send_file generate_large_primes.cu ./generate_large_primes

# Set once: password and host (refer: $HOME"/scripts/config_secrets.sh")
:'
export SSH_HOST="<user_id@ip>"
export SSH_PASS="<SSH_PASS>"
export SSH_KEY="$HOME/ssh_keys/jumpbox_key"
'
END
echo ""

# Send a file: local → remote
function ssh_send_file() {
  local file="$1"
  local remote_path="${2:-/home/m/}"
  sshpass -p "$SSH_PASS" scp "$file" "$SSH_HOST:$remote_path"
}

# Get a file: remote → local
function ssh_get_file() {
  local remote_file="$1"
  local local_path="${2:-./}"
  sshpass -p "$SSH_PASS" scp "$SSH_HOST:$remote_file" "$local_path"
}

echo ""
: <<'END'
ssh_zip_folder_and_send myfolder             # Sends myfolder.zip to /home/m/
% ssh_zip_folder_and_send time trial_utilities/ 

ssh_get_zip_and_unzip /home/m/myfolder.zip   # Downloads and unzips to current dir

ssh_get_folder_and_zip /home/m/myfolder     # Fetches and unzips to current dir
ssh_get_folder_and_zip /home/m/myfolder ~/Downloads/
'
END
echo ""

# Zip local folder and send it to remote
function ssh_zip_folder_and_send() {
  local folder="$1"
  local zipname="${folder}.zip"
  local remote_path="${2:-/home/m/}"

  if [ ! -d "$folder" ]; then
    echo "Folder '$folder' does not exist."
    return 1
  fi

  zip -r "$zipname" "$folder"
  sshpass -p "$SSH_PASS" scp "$zipname" "$SSH_HOST:$remote_path"
  rm "$zipname"
}

# Get a remote zip file and unzip it locally
function ssh_get_zip_and_unzip() {
  local remote_zip_path="$1"  # e.g., /home/m/project.zip
  local local_dir="${2:-./}"
  local zipfile=$(basename "$remote_zip_path")

  sshpass -p "$SSH_PASS" scp "$SSH_HOST:$remote_zip_path" "$local_dir"
  unzip -o "$local_dir/$zipfile" -d "$local_dir"
  rm "$local_dir/$zipfile"
}

# Get a folder from remote: zip it there, copy it back here
function ssh_get_folder_and_zip() {
  local remote_folder="$1"             # e.g. /home/m/myfolder
  local local_dest="${2:-./}"          # local destination (optional)
  local zipname="$(basename "$remote_folder").zip"
  local remote_zip="/tmp/$zipname"

  # Zip folder remotely
  sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "zip -r '$remote_zip' '$remote_folder'"

  # Copy zip file back
  sshpass -p "$SSH_PASS" scp "$SSH_HOST:$remote_zip" "$local_dest"

  # Clean up remote zip
  sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "rm '$remote_zip'"

  # Optionally unzip here
  unzip -o "$local_dest/$zipname" -d "$local_dest"
  rm "$local_dest/$zipname"
}


## -----------------------------------------------------------------------------------------------
# Extended function: zip, send, run, and get logs back
function ssh_run_and_collect() {
  local folder="$1"
  local remote_command="$2"
  local local_log_file="${3:-logs_from_remote.log}"
  local remote_path="${4:-/home/m/}"
  local zipname="${folder}.zip"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Validate inputs
  if [ ! -d "$folder" ]; then
    echo "ERROR: Folder '$folder' does not exist."
    return 1
  fi
  
  if [ -z "$remote_command" ]; then
    echo "ERROR: Remote command not specified."
    return 1
  fi
  
  echo "[$timestamp] Starting automated run for folder: $folder"
  
  # Step 1: Zip and send folder
  echo "[$timestamp] Zipping and sending folder..."
  zip -r "$zipname" "$folder" >/dev/null 2>&1
  if ! sshpass -p "$SSH_PASS" scp "$zipname" "$SSH_HOST:$remote_path"; then
    echo "ERROR: Failed to send zip file"
    rm -f "$zipname"
    return 1
  fi
  rm "$zipname"
  echo "[$timestamp] Folder sent successfully"
  
  # Step 2: Unzip on remote
  echo "[$timestamp] Unzipping on remote..."
  if ! sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "cd $remote_path && unzip -o ${zipname} && rm ${zipname}"; then
    echo "ERROR: Failed to unzip on remote"
    return 1
  fi
  echo "[$timestamp] Unzipped successfully"
  
  # Step 3: Build if Makefile exists
  echo "[$timestamp] Checking for Makefile and building..."
  sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "cd ${remote_path}${folder} && if [ -f Makefile ]; then make all 2>&1; fi"
  
  # Step 4: Run command on remote and capture output
  echo "[$timestamp] Running command: $remote_command"
  local remote_log="/tmp/run_output_$$.log"
  local run_command="cd ${remote_path}${folder} && { $remote_command; } 2>&1 | tee $remote_log"
  
  if ! sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "$run_command"; then
    echo "WARNING: Remote command may have failed (non-zero exit code)"
  fi
  
  # Step 5: Retrieve logs and append to local file
  echo "[$timestamp] Retrieving logs..."
  {
    echo "========================================="
    echo "Run started: $timestamp"
    echo "Folder: $folder"
    echo "Command: $remote_command"
    echo "Host: $SSH_HOST"
    echo "========================================="
  } >> "$local_log_file"
  
  if sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "cat $remote_log" >> "$local_log_file" 2>/dev/null; then
    echo "[$timestamp] Logs retrieved and appended to $local_log_file"
  else
    echo "WARNING: Could not retrieve remote logs"
  fi
  
  # Add separator and cleanup remote log
  echo -e "\n========================================\n" >> "$local_log_file"
  sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "rm -f $remote_log" 2>/dev/null
  
  echo "[$timestamp] Automated run completed"
}

# Convenience function specifically for CUDA projects
function ssh_run_cuda() {
  local folder="$1"
  local arg1="${2:-}"   # optional argument 1 (e.g., GPU count or matrix size)
  local arg2="${3:-}"   # optional argument 2 (if needed)
  local local_log_file="${4:-cuda_logs.log}"

  # Extract target binary name from Makefile (fallback: gen_large_rand)
  local target=$(grep -m1 '^TARGET=' "$folder/Makefile" | cut -d= -f2 | xargs)
  if [[ -z "$target" ]]; then
    target="gen_large_rand"
  fi

  # Construct run command
  local make_and_run="make clean && make && ./${target}"
  if [[ -n "$arg1" ]]; then
    make_and_run+=" $arg1"
  fi
  if [[ -n "$arg2" ]]; then
    make_and_run+=" $arg2"
  fi

  # Execute on remote
  ssh_run_and_collect "$folder" "$make_and_run" "$local_log_file"
}

# Run CUDA from current directory (sends parent folder)
function ssh_run_cuda_here() {
  local gpu_count="${1:-1}"
  local num_numbers="${2:-1}"
  local local_log_file="${3:-cuda_logs.log}"
  
  local current_folder=$(basename "$PWD")
  local parent_dir=$(dirname "$PWD")
  
  echo "Running CUDA project '$current_folder' from current directory"
  cd "$parent_dir"
  ssh_run_cuda "$current_folder" "$gpu_count" "$num_numbers" "$local_log_file"
  cd "$current_folder"
}

# Function to just retrieve and append existing remote logs
function ssh_get_logs() {
  local remote_log_path="$1"
  local local_log_file="${2:-logs_from_remote.log}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo "[$timestamp] Retrieving logs from: $remote_log_path"
  {
    echo "========================================="
    echo "Logs retrieved: $timestamp"
    echo "Remote path: $remote_log_path"
    echo "Host: $SSH_HOST"
    echo "========================================="
  } >> "$local_log_file"
  
  if sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "cat $remote_log_path" >> "$local_log_file" 2>/dev/null; then
    echo "[$timestamp] Logs appended to $local_log_file"
  else
    echo "ERROR: Could not retrieve logs from $remote_log_path"
    return 1
  fi
  
  echo -e "\n========================================\n" >> "$local_log_file"
}

# ssh_run_cuda_multi
# Build and run multiple CUDA binaries in a folder remotely
# Usage:
#   ssh_run_cuda_multi <folder> [arg1] [arg2] [base_log_file]
# Example:
#   ssh_run_cuda_multi "parallel_reduction_add" 4 1024 "cuda_results.log"
function ssh_run_cuda_multi() {
    local folder="$1"
    local arg1="${2:-}"
    local arg2="${3:-}"
    local base_log="${4:-cuda_logs.log}"
    
    if [[ -z "$folder" ]]; then
        echo "Usage: ssh_run_cuda_multi <folder> [arg1] [arg2] [base_log_file]"
        return 2
    fi
    
    local makefile="$folder/Makefile"
    if [[ ! -f "$makefile" ]]; then
        echo "Makefile not found in $folder"
        return 2
    fi
    
    # -----------------------------
    # Build everything first
    # -----------------------------
    echo "Building all targets..."
    # The remote system puts us directly in the folder, so just run make
    ssh_run_and_collect "$folder" "make clean && make" "$base_log"
    
    # -----------------------------
    # Detect targets after building by expanding Makefile variables
    # -----------------------------
    local targets=""
    
    # Method 1: Use make to expand the TARGETS variable
    targets=$(cd "$folder" && make -f Makefile --dry-run --print-data-base 2>/dev/null | \
              grep -A1 "^TARGETS :=" | tail -n1 | sed 's/^#[[:space:]]*//')
    
    # Method 2: If that doesn't work, try parsing and expanding manually
    if [[ -z "$targets" ]]; then
        local srcs_line targets_line
        srcs_line=$(grep -E '^[[:space:]]*SRCS[[:space:]]*=' "$makefile" | head -n1 | cut -d'=' -f2- | xargs)
        targets_line=$(grep -E '^[[:space:]]*TARGETS[[:space:]]*=' "$makefile" | head -n1 | cut -d'=' -f2- | xargs)
        
        if [[ "$targets_line" == '$(SRCS:.cu=)' ]]; then
            # Expand the variable manually
            targets=$(echo "$srcs_line" | sed 's/\.cu//g')
        else
            targets="$targets_line"
        fi
    fi
    
    # Method 3: Fallback - detect executables that were actually built
    if [[ -z "$targets" ]]; then
        echo "Could not parse TARGETS from Makefile, detecting built executables..."
        targets=$(find "$folder" -maxdepth 1 -type f -executable ! -name "*.sh" ! -name "Makefile" -printf '%f\n' 2>/dev/null | tr '\n' ' ')
    fi
    
    # Final fallback
    if [[ -z "$targets" ]]; then
        echo "No targets found, using default"
        targets="main"  # or whatever default makes sense
    fi
    
    echo "Detected targets: $targets"
    
    # -----------------------------
    # Run each target with optional args
    # -----------------------------
    # Convert targets string to array (zsh compatible way)
    local target_array
    target_array=(${=targets})  # zsh word splitting
    
    for t in "${target_array[@]}"; do
        [[ -z "$t" ]] && continue  # Skip empty strings
        
        local run_cmd="./'$t'"  # We're already in the right directory
        [[ -n "$arg1" ]] && run_cmd+=" $arg1"
        [[ -n "$arg2" ]] && run_cmd+=" $arg2"
        
        # unique log per target
        local log="${base_log%.*}_${t}.log"
        [[ "$log" == "$base_log" ]] && log="${base_log}_${t}.log"
        
        echo "==> Running target '$t'; logging to $log"
        ssh_run_and_collect "$folder" "$run_cmd" "$log"
    done
}

# Usage: debug_ssh_run_cuda_multi "parallel_reduction_add"
# Debug version to see what's actually happening
function debug_ssh_run_cuda_multi() {
    local folder="$1"
    echo "=== DEBUGGING ==="
    ssh_run_and_collect "$folder" "pwd && ls -la && find . -name 'Makefile' && find . -name '*.cu'" "debug.log"
    cat debug.log
}


echo ""
: <<'END'

Key Features

Complete Automation: Zips → Sends → Unzips → Runs → Retrieves logs
Timestamped Logs: Each run is clearly marked with timestamps
Append-Only Logging: Preserves all previous runs in the log file
Error Handling: Checks for failures at each step

# Run your CUDA project with 2 GPUs, generating 5 numbers
ssh_run_cuda "my_cuda_project" 2 5 "cuda_results.log"

# Custom command with specific log file
ssh_run_and_collect "my_cuda_project" "make clean && make && ./gen_large_rand 4 10" "large_run_logs.log"

# Just retrieve existing logs from remote
ssh_get_logs "/home/m/output.txt" "retrieved_logs.log"


ssh_run_cuda "generate_large_random_numbers" 2 5 "cuda_results.log"

END
echo ""




echo ""
: <<'END'

# Basic UEFI build
make run_uefi

# Which would call:
ssh_run_uefi "secure_uefi_helloworld"

# Debug build
ssh_run_uefi "secure_uefi_helloworld" "debug"

# With secure boot
ssh_run_uefi "secure_uefi_helloworld" "release" "true"

# Build and run in QEMU (if available on remote)
ssh_run_uefi_qemu "secure_uefi_helloworld"

# Build and sign with keys
ssh_build_and_sign_uefi "secure_uefi_helloworld"

END
echo ""



#!/bin/bash
# ============================================================================
# UEFI SSH Functions - Works with Your Existing SSH Setup
# Add these functions to your existing script
# ============================================================================

# Detect which SSH method to use
function get_ssh_cmd() {
    if [ -n "$SSH_PASS" ]; then
        echo "sshpass -p '$SSH_PASS' ssh $SSH_HOST"
    elif [ -n "$SSH_KEY" ]; then
        echo "ssh -i '$SSH_KEY' $SSH_HOST"
    else
        echo "ssh $SSH_HOST"
    fi
}

function get_scp_cmd() {
    if [ -n "$SSH_PASS" ]; then
        echo "sshpass -p '$SSH_PASS' scp"
    elif [ -n "$SSH_KEY" ]; then
        echo "scp -i '$SSH_KEY'"
    else
        echo "scp"
    fi
}

function get_rsync_cmd() {
    if [ -n "$SSH_PASS" ]; then
        echo "sshpass -p '$SSH_PASS' rsync"
    elif [ -n "$SSH_KEY" ]; then
        echo "rsync -e 'ssh -i $SSH_KEY'"
    else
        echo "rsync"
    fi
}

# ============================================================================
# UEFI Build Function - Simple Build on Remote with Logging
# ============================================================================
function ssh_run_uefi() {
    local folder="$1"
    local build_command="${2:-make all}"
    local remote_path="${3:-/home/m/}"
    
    # Create logs directory
    mkdir -p logs
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="logs/${folder}_build_${timestamp}.log"
    
    echo "════════════════════════════════════════════════════════════════════"
    echo "UEFI Remote Build: $folder"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Start logging
    {
        echo "════════════════════════════════════════════════════════════════════"
        echo "UEFI Build Log - $(date)"
        echo "Folder: $folder"
        echo "Command: $build_command"
        echo "Remote: $SSH_HOST:${remote_path}${folder}"
        echo "════════════════════════════════════════════════════════════════════"
        echo ""
    } | tee "$log_file"
    
    # Validate folder
    if [ ! -d "$folder" ]; then
        echo "ERROR: Folder '$folder' does not exist." | tee -a "$log_file"
        return 1
    fi
    
    local SSH_CMD=$(get_ssh_cmd)
    local RSYNC_CMD=$(get_rsync_cmd)
    
    # Transfer files
    echo "[1/3] Transferring files to remote..." | tee -a "$log_file"
    eval "$RSYNC_CMD -avz --delete \
        --exclude='.git' \
        --exclude='*.o' \
        --exclude='*.so' \
        --exclude='*.efi' \
        --exclude='obj/' \
        ./${folder}/ ${SSH_HOST}:${remote_path}${folder}/" 2>&1 | tee -a "$log_file" | grep -E "(sending|sent|total)"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "ERROR: File transfer failed" | tee -a "$log_file"
        return 1
    fi
    
    echo "✓ Files transferred" | tee -a "$log_file"
    echo "" | tee -a "$log_file"
    
    # Build on remote
    echo "[2/3] Building on remote..." | tee -a "$log_file"
    eval "$SSH_CMD 'cd ${remote_path}${folder} && $build_command'" 2>&1 | tee -a "$log_file"
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -ne 0 ]; then
        echo "" | tee -a "$log_file"
        echo "ERROR: Build failed (exit code: $exit_code)" | tee -a "$log_file"
        echo "Full log saved to: $log_file" | tee -a "$log_file"
        return $exit_code
    fi
    
    echo "" | tee -a "$log_file"
    echo "[3/3] Listing generated files..." | tee -a "$log_file"
    eval "$SSH_CMD 'cd ${remote_path}${folder} && ls -lh *.efi *.sig 2>/dev/null || echo \"No .efi files found\"'" 2>&1 | tee -a "$log_file"
    
    echo "" | tee -a "$log_file"
    echo "════════════════════════════════════════════════════════════════════" | tee -a "$log_file"
    echo "✓ Build complete!" | tee -a "$log_file"
    echo "Log saved to: $log_file" | tee -a "$log_file"
    echo "════════════════════════════════════════════════════════════════════" | tee -a "$log_file"
    
    return 0
}

# ============================================================================
# UEFI Build and Sign Function with Logging
# ============================================================================
function ssh_build_and_sign_uefi() {
    local folder="$1"
    local remote_path="${2:-/home/m/}"
    
    # Create logs directory
    mkdir -p logs
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="logs/${folder}_signed_${timestamp}.log"
    
    echo "════════════════════════════════════════════════════════════════════"
    echo "UEFI Build, Sign & Verify: $folder"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    
    # Start logging
    {
        echo "════════════════════════════════════════════════════════════════════"
        echo "UEFI Build, Sign & Verify Log - $(date)"
        echo "Folder: $folder"
        echo "Remote: $SSH_HOST:${remote_path}${folder}"
        echo "════════════════════════════════════════════════════════════════════"
        echo ""
    } | tee "$log_file"
    
    if [ ! -d "$folder" ]; then
        echo "ERROR: Folder '$folder' does not exist." | tee -a "$log_file"
        return 1
    fi
    
    local SSH_CMD=$(get_ssh_cmd)
    local RSYNC_CMD=$(get_rsync_cmd)
    
    # Transfer files
    echo "[1/5] Transferring files..." | tee -a "$log_file"
    eval "$RSYNC_CMD -avz --delete \
        --exclude='.git' \
        --exclude='*.o' \
        --exclude='*.so' \
        --exclude='*.efi' \
        --exclude='obj/' \
        ./${folder}/ ${SSH_HOST}:${remote_path}${folder}/" 2>&1 | tee -a "$log_file" | grep -E "(sending|sent|total)"
    
    echo "✓ Files transferred" | tee -a "$log_file"
    echo "" | tee -a "$log_file"
    
    # Build, sign, and verify
    echo "[2/5] Building..." | tee -a "$log_file"
    eval "$SSH_CMD 'cd ${remote_path}${folder} && make clean && make all'" 2>&1 | tee -a "$log_file"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "ERROR: Build failed" | tee -a "$log_file"
        echo "Log saved to: $log_file" | tee -a "$log_file"
        return 1
    fi
    
    echo "" | tee -a "$log_file"
    echo "[3/5] Signing..." | tee -a "$log_file"
    eval "$SSH_CMD 'cd ${remote_path}${folder} && make sign'" 2>&1 | tee -a "$log_file"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "ERROR: Signing failed" | tee -a "$log_file"
        echo "Log saved to: $log_file" | tee -a "$log_file"
        return 1
    fi
    
    echo "" | tee -a "$log_file"
    echo "[4/5] Verifying signatures..." | tee -a "$log_file"
    eval "$SSH_CMD 'cd ${remote_path}${folder} && make verify'" 2>&1 | tee -a "$log_file"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "ERROR: Verification failed" | tee -a "$log_file"
        echo "Log saved to: $log_file" | tee -a "$log_file"
        return 1
    fi
    
    echo "" | tee -a "$log_file"
    echo "[5/5] Summary..." | tee -a "$log_file"
    eval "$SSH_CMD 'cd ${remote_path}${folder} && echo \"Generated files:\" && ls -lh *.efi *.sig && echo \"\" && echo \"Keys:\" && ls -lh keys/*.pem'" 2>&1 | tee -a "$log_file"
    
    echo "" | tee -a "$log_file"
    echo "════════════════════════════════════════════════════════════════════" | tee -a "$log_file"
    echo "✓ Build, sign, and verify complete!" | tee -a "$log_file"
    echo "Log saved to: $log_file" | tee -a "$log_file"
    echo "════════════════════════════════════════════════════════════════════" | tee -a "$log_file"
    
    return 0
}

# ============================================================================
# UEFI QEMU Execution Function
# ============================================================================
function ssh_run_uefi_qemu() {
    local folder="$1"
    local timeout="${2:-30}"
    local remote_path="${3:-/home/m/}"
    
    echo "════════════════════════════════════════════════════════════════════"
    echo "UEFI QEMU Execution: $folder"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    
    if [ ! -d "$folder" ]; then
        echo "ERROR: Folder '$folder' does not exist."
        return 1
    fi
    
    local SSH_CMD=$(get_ssh_cmd)
    local RSYNC_CMD=$(get_rsync_cmd)
    
    # Transfer files
    echo "[1/6] Transferring files..."
    eval "$RSYNC_CMD -avz --delete \
        --exclude='.git' \
        --exclude='*.o' \
        --exclude='*.so' \
        --exclude='*.efi' \
        --exclude='obj/' \
        ./${folder}/ ${SSH_HOST}:${remote_path}${folder}/" 2>&1 | grep -E "(sending|sent|total)"
    
    echo "✓ Files transferred"
    echo ""
    
    # Build
    echo "[2/6] Building..."
    eval "$SSH_CMD 'cd ${remote_path}${folder} && make clean && make all'"
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Build failed"
        return 1
    fi
    
    # Sign
    echo ""
    echo "[3/6] Signing..."
    eval "$SSH_CMD 'cd ${remote_path}${folder} && make sign'"
    
    # Verify
    echo ""
    echo "[4/6] Verifying..."
    eval "$SSH_CMD 'cd ${remote_path}${folder} && make verify'"
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Verification failed - aborting QEMU execution"
        return 1
    fi
    
    # Prepare QEMU disk
    echo ""
    echo "[5/6] Preparing QEMU disk image..."
    eval "$SSH_CMD 'cd ${remote_path}${folder} && \
        rm -f disk.img && \
        dd if=/dev/zero of=disk.img bs=1M count=10 2>/dev/null && \
        mkfs.fat -F 32 disk.img >/dev/null 2>&1 && \
        mcopy -i disk.img *.efi ::/ 2>/dev/null && \
        echo \"helloworld.efi\" > startup.nsh && \
        mcopy -i disk.img startup.nsh ::/ 2>/dev/null && \
        echo \"✓ Disk image ready\"'"
    
    # Run in QEMU
    echo ""
    echo "[6/6] Running in QEMU (timeout: ${timeout}s)..."
    echo "────────────────────────────────────────────────────────────────────"
    eval "$SSH_CMD 'cd ${remote_path}${folder} && \
        timeout ${timeout}s qemu-system-x86_64 \
            -bios /usr/share/ovmf/OVMF.fd \
            -drive file=disk.img,format=raw,if=ide \
            -net none \
            -nographic \
            -monitor none \
            -serial stdio 2>/dev/null || true'"
    echo "────────────────────────────────────────────────────────────────────"
    
    echo ""
    echo "════════════════════════════════════════════════════════════════════"
    echo "✓ QEMU execution complete!"
    echo "════════════════════════════════════════════════════════════════════"
    
    return 0
}

# ============================================================================
# Download UEFI Artifacts from Remote
# ============================================================================
function ssh_download_uefi() {
    local folder="$1"
    local remote_path="${2:-/home/m/}"
    local local_dest="${3:-./${folder}/remote_builds}"
    
    echo "Downloading UEFI artifacts from remote..."
    
    local SCP_CMD=$(get_scp_cmd)
    
    mkdir -p "$local_dest"
    
    eval "$SCP_CMD ${SSH_HOST}:${remote_path}${folder}/*.efi ${SSH_HOST}:${remote_path}${folder}/*.sig $local_dest/ 2>/dev/null" || true
    
    if [ -f "$local_dest/helloworld.efi" ]; then
        echo "✓ Downloaded to: $local_dest/"
        ls -lh "$local_dest/"
        return 0
    else
        echo "⚠ No files downloaded (may not exist on remote)"
        return 1
    fi
}

# ============================================================================
# Complete Pipeline - Build, Sign, Verify, Download
# ============================================================================
function ssh_uefi_pipeline() {
    local folder="$1"
    local run_qemu="${2:-false}"
    local remote_path="${3:-/home/m/}"
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                UEFI Complete Pipeline                              ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Build and sign
    ssh_build_and_sign_uefi "$folder" "$remote_path"
    
    if [ $? -ne 0 ]; then
        echo ""
        echo "✗ Pipeline failed at build/sign stage"
        return 1
    fi
    
    # Download artifacts
    echo ""
    ssh_download_uefi "$folder" "$remote_path"
    
    # Optionally run QEMU
    if [ "$run_qemu" == "true" ]; then
        echo ""
        ssh_run_uefi_qemu "$folder" 30 "$remote_path"
    fi
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                    ✓ Pipeline Complete!                           ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    return 0
}

# ============================================================================
# Show Help
# ============================================================================
function uefi_help() {
    echo ""
    echo "════════════════════════════════════════════════════════════════════"
    echo "UEFI SSH Functions - Available Commands"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Basic Usage:"
    echo "  ssh_run_uefi <folder> [command] [remote_path]"
    echo "    Example: ssh_run_uefi \"secure_uefi_helloworld\" \"make all\""
    echo ""
    echo "Build and Sign:"
    echo "  ssh_build_and_sign_uefi <folder> [remote_path]"
    echo "    Example: ssh_build_and_sign_uefi \"secure_uefi_helloworld\""
    echo ""
    echo "Run in QEMU:"
    echo "  ssh_run_uefi_qemu <folder> [timeout] [remote_path]"
    echo "    Example: ssh_run_uefi_qemu \"secure_uefi_helloworld\" 30"
    echo ""
    echo "Download Artifacts:"
    echo "  ssh_download_uefi <folder> [remote_path] [local_dest]"
    echo "    Example: ssh_download_uefi \"secure_uefi_helloworld\""
    echo ""
    echo "Complete Pipeline:"
    echo "  ssh_uefi_pipeline <folder> [run_qemu] [remote_path]"
    echo "    Example: ssh_uefi_pipeline \"secure_uefi_helloworld\" true"
    echo ""
    echo "Current SSH Configuration:"
    echo "  SSH_HOST: ${SSH_HOST:-not set}"
    echo "  SSH_PASS: ${SSH_PASS:+***set***}${SSH_PASS:-not set}"
    echo "  SSH_KEY: ${SSH_KEY:-not set}"
    echo ""
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
}

echo "✓ UEFI SSH functions loaded (compatible with your existing SSH setup)"
echo "  Run 'uefi_help' to see available commands"




echo ""
: <<'END'

🔐 Step-by-Step: SSH to Jumpbox Using Custom Key
✅ Step 1: Generate a new SSH key pair (with custom name)

mkdir -p ~/ssh_keys
ssh-keygen -t rsa -b 4096 -f ~/ssh_keys/jumpbox_key -N ""

This creates:
~/ssh_keys/jumpbox_key → private key
~/ssh_keys/jumpbox_key.pub → public key

✅ Step 2: Copy the public key to the jumpbox
ssh-copy-id -i ~/ssh_keys/jumpbox_key.pub "$SSH_HOST" 
or 
sshpass -p "$SSH_PASS" ssh-copy-id -i ~/ssh_keys/jumpbox_key.pub "$SSH_HOST"

✅ Step 3: Connext using the key
ssh -i "$SSH_KEY" "$SSH_HOST"

END
echo ""

function ssh_login_with_pass(){
    sshpass -p "$SSH_PASS" ssh "$SSH_HOST"
}

function ssh_login_with_key(){
    ssh -i "$SSH_KEY" "$SSH_HOST"
}