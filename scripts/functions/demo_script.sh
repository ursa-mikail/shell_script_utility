#!/bin/bash

# Function to create directory structure with files
create_test_directory() {
    local root_dir="$1"
    
    echo "Creating test directory structure in: $root_dir"
    
    # Create main directory
    mkdir -p "$root_dir"
    
    # Create subdirectories
    mkdir -p "$root_dir/config"
    mkdir -p "$root_dir/data/logs"
    mkdir -p "$root_dir/src/modules"
    mkdir -p "$root_dir/docs"
    
    # Create sample files
    cat > "$root_dir/main.sh" << 'EOF'
#!/bin/bash
echo "Hello from main script"
echo "Project: $(basename "$(pwd)")"
echo "Created: $(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" "$0")"
EOF
    chmod +x "$root_dir/main.sh"
    
    cat > "$root_dir/config/settings.yaml" << EOF
# Application Configuration
app_name: DemoApp
version: 1.0.0
debug: true
log_level: INFO
root_directory: $(basename "$root_dir")
created: $(date +"%Y-%m-%d %H:%M:%S")
EOF
    
    cat > "$root_dir/config/config.json" << EOF
{
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "demo_db"
  },
  "api": {
    "endpoint": "https://api.example.com",
    "timeout": 30
  },
  "metadata": {
    "project_name": "$(basename "$root_dir")",
    "created": "$(date -Iseconds)"
  }
}
EOF
    
    cat > "$root_dir/src/main.py" << 'EOF'
import sys
import os

def main():
    print("Hello from Python module")
    print(f"Project: {os.path.basename(os.path.dirname(os.path.dirname(__file__)))}")
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOF
    
    cat > "$root_dir/src/modules/utils.js" << EOF
// Utility module
// Project: $(basename "$root_dir")

export function greet(name) {
    return \`Hello, \${name} from $(basename "$root_dir")!\`;
}

export const version = '1.0.0';
export const project = '$(basename "$root_dir")';
EOF
    
    cat > "$root_dir/docs/README.md" << EOF
# Project Documentation: $(basename "$root_dir")

## Overview
This is a demo project structure created on $(date).

## Files
- main.sh: Main shell script
- config/: Configuration files
- src/: Source code
- docs/: Documentation
- data/: Data and logs

## Usage
Run ./main.sh to start the application.

## Project Info
- Name: $(basename "$root_dir")
- Created: $(date)
- Location: $root_dir
EOF
    
    cat > "$root_dir/data/logs/app.log" << EOF
$(date +"%Y-%m-%d %H:%M:%S") INFO - Application started
$(date +"%Y-%m-%d %H:%M:%S") INFO - Project: $(basename "$root_dir")
$(date +"%Y-%m-%d %H:%M:%S") INFO - Configuration loaded
$(date +"%Y-%m-%d %H:%M:%S") WARN - Cache miss detected
$(date +"%Y-%m-%d %H:%M:%S") INFO - Processing completed successfully
EOF
    
    echo "node_modules/
*.tmp
*.log
*.cache
*.zip
*.sha256" > "$root_dir/.gitignore"
    
    # Create a simple test data file
    cat > "$root_dir/data/sample.txt" << EOF
This is a test data file for project: $(basename "$root_dir")
Timestamp: $(date)
EOF
    
    echo "Directory structure created successfully!"
    echo "Total files created: $(find "$root_dir" -type f 2>/dev/null | wc -l | tr -d ' ')"
}

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

# Demo mode: create directory first, then process it
run_demo() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local root_dir="demo_project_${timestamp}"
    
    echo "=== Demo Script Started ==="
    echo "Timestamp: $(date)"
    echo "Root directory: $(pwd)/$root_dir"
    echo ""
    
    # Step 1: Create directory structure
    echo "Step 1: Creating directory structure..."
    create_test_directory "$root_dir"
    echo ""
    
    # Display directory structure
    show_directory_tree "$root_dir"
    
    # Process the directory
    if ! process_directory "$root_dir"; then
        echo "✗ Demo failed"
        return 1
    fi
    
    echo ""
    echo "=== Demo Completed Successfully ==="
    echo ""
    echo "Summary:"
    echo "✓ Created directory: $root_dir"
    echo "✓ Created zip archive: ${root_dir}.zip"
    echo "✓ Generated checksum: ${root_dir}.sha256"
    echo ""
    echo "You can now:"
    echo "1. Run the demo script: ./$root_dir/main.sh"
    echo "2. Extract the zip: unzip ${root_dir}.zip"
    echo "3. Verify integrity: sha256sum -c ${root_dir}.sha256"
    echo ""
    echo "To clean up, run:"
    echo "  rm -rf \"$root_dir\" \"${root_dir}.zip\" \"${root_dir}.sha256\""
}

# Process existing directory mode
run_process() {
    local root_dir="$1"
    
    if [[ -z "$root_dir" ]]; then
        echo "✗ Error: Please specify a directory to process"
        show_usage
        return 1
    fi
    
    # Handle relative paths
    if [[ "$root_dir" == "." ]]; then
        root_dir=$(pwd)
    elif [[ ! "$root_dir" = /* ]]; then
        root_dir="$(pwd)/$root_dir"
    fi
    
    if [[ ! -d "$root_dir" ]]; then
        echo "✗ Error: Directory '$root_dir' does not exist"
        return 1
    fi
    
    # Show what we're processing
    show_directory_tree "$root_dir"
    
    if ! process_directory "$root_dir"; then
        echo "✗ Processing failed"
        return 1
    fi
    
    local base_name=$(basename "$root_dir")
    echo ""
    echo "=== Processing Completed Successfully ==="
    echo ""
    echo "Summary:"
    echo "✓ Processed directory: $root_dir"
    echo "✓ Created zip archive: ${base_name}.zip"
    echo "✓ Generated checksum: ${base_name}.sha256"
    echo ""
    echo "To clean up created files, run:"
    echo "  rm -f \"${base_name}.zip\" \"${base_name}.sha256\""
}

# Helper function to show usage
show_usage() {
    echo "Usage: $0 [directory]"
    echo "       $0 --demo"
    echo "       $0 --help"
    echo ""
    echo "Options:"
    echo "  [directory]    Zip and hash an existing directory"
    echo "  --demo, -d     Run demo (create directory, then zip and hash)"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Zip and hash current directory"
    echo "  $0 ./my_project        # Zip and hash my_project directory"
    echo "  $0 /path/to/project    # Zip and hash project directory"
    echo "  $0 --demo              # Create demo directory, then zip and hash"
    echo ""
}

# Main script logic
main() {
    # Handle no arguments (process current directory)
    if [[ $# -eq 0 ]]; then
        echo "=== Processing Current Directory ==="
        echo "Directory: $(pwd)"
        echo "Timestamp: $(date)"
        echo ""
        run_process "."
        return $?
    fi
    
    # Handle single argument
    case "$1" in
        "--demo"|"-d")
            run_demo
            ;;
        "--help"|"-h")
            show_usage
            ;;
        *)
            # Assume it's a directory
            run_process "$1"
            ;;
    esac
}

# Run the script
main "$@"

# ./demo_script.sh ./my_project