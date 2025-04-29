#!/bin/bash
# 07_clean_temp.sh - Clean temp files

TEMP_DIR="/tmp"

echo "Cleaning up temporary files in $TEMP_DIR..."
find "$TEMP_DIR" -type f -mtime +7 -exec rm -f {} \;

echo "Old temp files cleaned up (older than 7 days)."

# ✅ Deletes files older than 7 days in /tmp to avoid filling up disk.