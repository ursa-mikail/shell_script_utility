#!/bin/bash
# 03_another_task.sh - Backup a folder

SOURCE_DIR="./batch_files"
BACKUP_DIR="./backup_$(date +%Y%m%d_%H%M%S)"

echo "Creating backup of '${SOURCE_DIR}' to '${BACKUP_DIR}'..."
cp -r "$SOURCE_DIR" "$BACKUP_DIR"
echo "Backup completed."
