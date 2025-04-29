#!/bin/bash
# 11_backup_mysql.sh - Backup MySQL database

DB_USER="root"
DB_PASS="yourpassword"
DB_NAME="mydatabase"
BACKUP_FILE="$HOME/${DB_NAME}_backup_$(date +%Y%m%d).sql"

echo "Backing up database $DB_NAME..."
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE"

echo "Backup completed: $BACKUP_FILE"
