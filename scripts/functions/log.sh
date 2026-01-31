log() {
    local log_file="${2:-date_time.log}"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    echo "$1"
    echo "$timestamp - $1" >> "$log_file"
}

# Usage
#log "Script started"                    # Uses default date_time.log
#log "Processing complete" "custom.log"  # Uses custom.log
#log "Another message" "/var/log/myapp/app.log"  # Uses full path