#!/bin/bash

# Function to create zip archive
create_zip_archive() {
    local source_dir="$1"
    local output_zip="${2:-$(basename "$source_dir").zip}"
    
    echo "Creating zip archive from: $source_dir"
    echo "Output file: $output_zip"
    
    # Get the parent directory and base name
    local parent_dir=$(dirname "$source_dir")
    local dir_name=$(basename "$source_dir")
    
    # Create zip file
    if command -v zip &> /dev/null; then
        if cd "$parent_dir" && zip -rq "$output_zip" "$dir_name"; then
            echo "✓ Zip archive created successfully: $output_zip"
            echo "  File size: $(du -h "$output_zip" | cut -f1)"
            echo "  Location: $(pwd)/$output_zip"
            return 0
        else
            echo "✗ Error: Failed to create zip archive"
            return 1
        fi
    else
        echo "✗ Error: 'zip' command not found. Please install zip utility."
        return 1
    fi
}

# Function to generate SHA256 checksum
generate_sha256() {
    local file_path="$1"
    local output_file="${2:-$(basename "$file_path").sha256}"
    
    echo "Generating SHA256 checksum for: $(basename "$file_path")"
    
    # Generate SHA256
    if command -v sha256sum &> /dev/null; then
        local checksum=$(sha256sum "$file_path" | awk '{print $1}')
        echo "✓ SHA256: $checksum"
        
        # Save to file
        echo "$checksum $(basename "$file_path")" > "$output_file"
        echo "  Checksum saved to: $output_file"
        
        return 0
    elif command -v shasum &> /dev/null; then
        # macOS alternative
        local checksum=$(shasum -a 256 "$file_path" | awk '{print $1}')
        echo "✓ SHA256: $checksum"
        
        echo "$checksum $(basename "$file_path")" > "$output_file"
        echo "  Checksum saved to: $output_file"
        
        return 0
    else
        echo "✗ Error: SHA256 generation utility not found"
        return 1
    fi
}

# Function to verify zip integrity
verify_zip() {
    local zip_file="$1"
    
    echo "Verifying zip integrity: $(basename "$zip_file")"
    
    if command -v unzip &> /dev/null; then
        if unzip -tq "$zip_file"; then
            echo "✓ Zip file is valid and complete"
            return 0
        else
            echo "✗ Error: Zip file is corrupted or incomplete"
            return 1
        fi
    else
        echo "⚠ Warning: 'unzip' not found, skipping zip verification"
        return 0
    fi
}

# Function to verify checksum
verify_checksum() {
    local checksum_file="$1"
    
    echo "Checksum verification:"
    
    if command -v sha256sum &> /dev/null; then
        if sha256sum -c "$checksum_file"; then
            echo "✓ Checksum verified"
            return 0
        else
            echo "✗ Checksum verification failed"
            return 1
        fi
    elif command -v shasum &> /dev/null; then
        if shasum -a 256 -c "$checksum_file"; then
            echo "✓ Checksum verified"
            return 0
        else
            echo "✗ Checksum verification failed"
            return 1
        fi
    else
        echo "⚠ Warning: checksum verification utility not found"
        return 0
    fi
}

# Function to display directory tree
show_directory_tree() {
    local root_dir="$1"
    
    echo "Directory contents:"
    
    if command -v tree &> /dev/null; then
        # Use tree command if available
        tree "$root_dir"
    else
        # Fallback: show directory listing
        echo "$root_dir"
        find "$root_dir" -type f | sort | while read -r file; do
            local relative_path="${file#$root_dir/}"
            local depth=$(echo "$relative_path" | tr -cd '/' | wc -c)
            local indent=$(printf "%$((depth * 2))s")
            local filename=$(basename "$file")
            
            if [[ $depth -eq 0 ]]; then
                echo "├── $filename"
            else
                local path_parts=$(echo "$relative_path" | sed 's|/| |g')
                local current_path=""
                
                for part in $path_parts; do
                    if [[ "$part" == "$filename" ]]; then
                        echo "${indent}└── $part"
                    else
                        echo "${indent}├── $part/"
                        indent+="  "
                        current_path="$current_path/$part"
                    fi
                done
            fi
        done
        echo ""
        echo "$(find "$root_dir" -type f | wc -l | tr -d ' ') files, $(find "$root_dir" -type d | wc -l | tr -d ' ') directories"
    fi
    echo ""
}

# Main function to process a directory
process_directory() {
    local root_dir="$1"
    local base_name=$(basename "$root_dir")
    
    # Get absolute path
    if [[ ! "$root_dir" = /* ]]; then
        root_dir="$(cd "$(dirname "$root_dir")" && pwd)/$(basename "$root_dir")"
    fi
    
    # Check if directory exists
    if [[ ! -d "$root_dir" ]]; then
        echo "✗ Error: Directory '$root_dir' does not exist"
        return 1
    fi
    
    echo "=== Processing Directory ==="
    echo "Directory: $root_dir"
    echo "Timestamp: $(date)"
    echo ""
    
    # Show what we're processing
    show_directory_tree "$root_dir"
    
    # Step 1: Create zip archive
    echo "Step 1: Creating zip archive..."
    local zip_file="${base_name}.zip"
    create_zip_archive "$root_dir" "$zip_file"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    echo ""
    
    # Step 2: Verify zip integrity
    echo "Step 2: Verifying zip integrity..."
    verify_zip "$zip_file"
    echo ""
    
    # Step 3: Generate SHA256 checksum
    echo "Step 3: Generating SHA256 checksum..."
    local checksum_file="${base_name}.sha256"
    generate_sha256 "$zip_file" "$checksum_file"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    echo ""
    
    # Step 4: Verification
    echo "Step 4: Verification..."
    echo "Created files:"
    ls -lh "$zip_file" "$checksum_file" 2>/dev/null | sed 's/^/  /' || true
    echo ""
    
    # Verify checksum
    verify_checksum "$checksum_file"
    
    # Return success
    return 0
}

# Helper function to show usage
show_usage() {
    echo "Usage: $0 [directory]"
    echo "       $0 --help"
    echo ""
    echo "Options:"
    echo "  [directory]    Zip and hash an existing directory"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Zip and hash current directory"
    echo "  $0 ./my_project        # Zip and hash my_project directory"
    echo "  $0 /path/to/project    # Zip and hash project directory"
    echo ""
}

# Main script logic
#main() {
get_directory_hash(){    
    # Handle help flag
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_usage
        return 0
    fi
    
    # Handle no arguments (process current directory)
    if [[ $# -eq 0 ]]; then
        echo "=== Processing Current Directory ==="
        echo "Directory: $(pwd)"
        echo "Timestamp: $(date)"
        echo ""
        process_directory "."
        return $?
    fi
    
    # Handle single argument (assume it's a directory)
    echo "=== Processing Directory ==="
    echo "Directory: $1"
    echo "Timestamp: $(date)"
    echo ""
    process_directory "$1"
}

# Run the script
#main "$@"