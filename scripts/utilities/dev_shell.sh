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
    ssh -i "$SSH_KEY" "$SSH_HOST"
}

function ssh_login_with_key(){
    sshpass -p "$SSH_PASS" ssh "$SSH_HOST"
}