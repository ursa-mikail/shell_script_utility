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
    pid=$(pgrep -f "python app.py")
    
    if [ -z "$pid" ]; then
        echo "No python app.py process found"
    else
        # Kill the process
        kill "$pid"
        echo "Stopped python app.py process with PID: $pid"
    fi
}