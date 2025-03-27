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
}

function stop_python_venv() {
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

