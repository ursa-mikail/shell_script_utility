#!/bin/bash
# 04_start_server.sh - Start a local web server

PORT=8000

echo "Starting Python HTTP server on port $PORT..."
python3 -m http.server $PORT

# ✅ This will serve the current directory at http://localhost:8000/