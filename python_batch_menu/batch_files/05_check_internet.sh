#!/bin/bash
# 05_check_internet.sh - Check internet connectivity

TARGET="8.8.8.8" # Google DNS

echo "Pinging $TARGET..."
ping -c 4 $TARGET

if [ $? -eq 0 ]; then
    echo "Internet connection: OK"
else
    echo "Internet connection: Failed"
fi

# Ping a well-known server to check internet
# ✅ ping -c 4 sends 4 pings.