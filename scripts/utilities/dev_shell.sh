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
  
  # Step 3: Run command on remote and capture output
  echo "[$timestamp] Running command: $remote_command"
  local remote_log="/tmp/run_output_$$.log"
  local run_command="cd ${remote_path}${folder} && { $remote_command; } 2>&1 | tee $remote_log"
  
  if ! sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "$run_command"; then
    echo "WARNING: Remote command may have failed (non-zero exit code)"
  fi
  
  # Step 4: Retrieve logs and append to local file
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
  local gpu_count="${2:-1}"
  local num_numbers="${3:-1}"
  local local_log_file="${4:-cuda_logs.log}"
  
  local make_and_run="make clean && make && ./gen_large_rand $gpu_count $num_numbers"
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

# Usage examples:
#
# Basic usage - run make and execute program:
# ssh_run_and_collect "my_cuda_project" "make && ./gen_large_rand" "my_logs.log"
#
# CUDA-specific convenience function:
# ssh_run_cuda "my_cuda_project" 2 5 "cuda_results.log"  # 2 GPUs, 5 numbers
#
# Just retrieve existing logs:
# ssh_get_logs "/home/m/some_output.log" "retrieved_logs.log"


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