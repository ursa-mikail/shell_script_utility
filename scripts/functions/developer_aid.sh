# alias scaffold_go=scaffold_go

# Define the alias for scaffold_go
function scaffold_go() {
    if [ -z "$1" ]; then
        echo "Usage: scaffold_go <project_name>"
        return 1
    fi
    
    PROJECT_NAME=$1
    TEMPLATE_FOLDER="$HOME/ursa/git/bolting_and_molting_with_golang_an_anarchist_coding_cook_book/chapter_01/examples/test-app"
    
    if [ ! -d "$TEMPLATE_FOLDER" ]; then
        echo "Error: Template folder '$TEMPLATE_FOLDER' does not exist."
        return 1
    fi
    
    # Copy the template folder and rename it
    cp -r "$TEMPLATE_FOLDER" "$PROJECT_NAME"
    cd "$PROJECT_NAME" || return 1
    
    # Initialize Go module
    go mod init "$PROJECT_NAME"
    
    echo "Project '$PROJECT_NAME' has been scaffolded."
    echo "try: % go run main.go"
}


