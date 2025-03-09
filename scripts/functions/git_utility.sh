function git_commit_and_push_to_main (){
	git add .; git status	
	
	echo "comments [e.g. updated: / added:] : "
	read -r comments
	
	#comments="$1"
	git commit -am "$comments"
	git push -u origin main # git push origin master # git push -u origin master
	# git push -uf origin master # force
	# git push origin HEAD:master
	# git push origin HEAD:main
	# git push origin <branch_name>
}

# % get_commits_in_range "2024-11-01" "2024-11-25"
function get_commits_in_range() {
    local start_date="$1"
    local end_date="$2"

    git log --since="$start_date" --until="$end_date" --pretty=format:"%h" | while read -r hash; do 
        git show "$hash" --pretty=format:"%h | %an | %ad | %s" --date=short --no-patch
    done
}


function fetch_and_check_diff(){
	# Fetch the latest changes
	git fetch origin

	# Check for differences
	DIFF=$(git diff --name-only origin/main)

	if [ -z "$DIFF" ]; then
	  echo "No differences found, safe to pull."
	  # git pull origin main
	else
	  echo "Differences found:"
	  echo "$DIFF"

echo ""
: <<'NOTE_BLOCK'
	  	echo "Do you want to rebase local changes on top of the remote changes? (yes/no): " 
	    read -r rebase_choice
	    if [ "$rebase_choice" == "yes" ]; then
	      echo "Rebasing..."
	      git pull --rebase origin main
	    else
	      echo "Aborting the update."
	      exit 1
	    fi
NOTE_BLOCK
echo ""	
	fi
}

# set_git_user_profile # Uses the default ~/.ssh/ directory
# or
# set_git_user_profile /path/to/your/keys/ # Specify a different directory
function set_git_user_profile {
    key_store="${1:-$HOME/.ssh/}" # Default to ~/.ssh/ if no directory is specified

    echo "Listing files in $key_store:"
 #   files=($(ls -1 "$key_store"))

 #   if [ ${#files[@]} -eq 0 ]; then
 #       echo "No files found in $key_store"
 #       return 1
 #   fi

 #   for i in "${!files[@]}"; do
 #       echo "[$i] ${files[$i]}"
 #   done

 		ls -1 "$key_store";
 		echo ''

 		echo -n "Enter the key file name (without path): "
    read key_file_name

    # Define the full path to the key
    private_authentication_key_with_path="$HOME/.ssh/$key_file_name"

     # Check if the file exists
    if [ ! -f "$private_authentication_key_with_path" ]; then
        echo "File not found: $private_authentication_key_with_path"
        return 1
    else
        echo "File chosen: $private_authentication_key_with_path"
    fi

    #read -p "Select a key file by number: " key_id

    #if ! [[ "$key_id" =~ ^[0-9]+$ ]] || [ "$key_id" -ge ${#files[@]} ] || [ "$key_id" -lt 0 ]; then
    #    echo "Invalid selection"
    #    return 1
    #fi

    #selected_key="${files[$key_id]}"
    #private_authentication_key_with_path="$key_store/$selected_key"

    #echo "Starting ssh-agent..."
    eval "$(ssh-agent -s)"

    echo "Adding private key: $private_authentication_key_with_path"
    ssh-add "$private_authentication_key_with_path"

    echo "set_git_user_profile [DONE]"
    echo "... awaiting git config list ... "
    git config --list
    echo "... git config list [DONE] ... "
}

function git_conflict_resolution_advisory (){
	echo "
	git pull origin <branch_name> | grep -i 'CONFLICT'
	git diff
	
	likely changes of same function by different people, Git is in a state of confusion and it asks the user to resolve the conflict manually before pulling to deter code collisions. 
	
	When multiple developers work on a single remote repo, you cannot modify the order of the commits in the remote repository. In this situation, you can use rebase operation to put your local commits on top of the remote repo commits and you can push these changes.

	// adds GitHub repo URL as a remote origin and pushes changes to remote repo.
	git remote add origin https://github.com/<user_id>/<user_repo>.git
	git push -u origin master

	"
}

function clear_git_logs() {
    # Display warning message
    echo "WARNING: This action will permanently delete all commit history from the current branch."
    echo "         It will create a new branch with no history and force push it to the remote repository."
    echo "         This is a destructive action and cannot be undone."
    echo "Explain what will happen before proceeding a full flush and refresh."
    echo "Are you sure you want to proceed? (yes/no):" 
    read -r confirmation

    #open_new_window;

    mkdir ../backup/
    mv readme.md ../backup/readme.md # backup the readme file

    # Check user confirmation
    if [ "$confirmation" != "yes" ]; then
        echo "Aborting operation."
        exit 1
    fi

    # Step 1: Create a new orphan branch
    git checkout --orphan latest_branch
    if [ $? -ne 0 ]; then
        echo "Failed to create orphan branch. Aborting."
        exit 1
    fi

    # Step 2: Add a file and commit
    echo "Initial content" > README.md  # Create a file to commit if you don't have any files
    git add -A
    git commit -m "Initial commit on latest_branch"
    if [ $? -ne 0 ]; then
        echo "Failed to commit changes. Aborting."
        exit 1
    fi

    # Step 3: Delete the main branch if it exists locally
    git branch -D main  # If 'main' exists, this will delete it; if not, skip this step
    if [ $? -ne 0 ]; then
        echo "Failed to delete old branch. Aborting."
        exit 1
    fi

    # Step 4: Rename latest_branch to main
    git branch -m main
    if [ $? -ne 0 ]; then
        echo "Failed to rename branch. Aborting."
        exit 1
    fi

    # Step 5: Force push the new main branch to the remote repository
    git push -f origin main
    if [ $? -ne 0 ]; then
        echo "Failed to push changes to remote repository. Aborting."
        exit 1
    fi

    mv ../backup/readme.md readme.md # recover the backuped readme file
    rm -rf ../backup/

    echo "Git logs cleared and new history pushed to remote repository successfully."
    echo "Close this window and use the other one from which this is created from."
}


# check which repo in Github
function git_which_repo (){
	git remote -v
}

function git_latest_status (){
	git log -1
}

function git_N_status_from_branch (){
	branch_name="$1"
	N="$2"
	
	git log --pretty=oneline origin/"$branch_name" -"$N"
	# if that branch is useful, get from that branch: 
	# $ git branch
	# $ git merge origin/"$branch_name" # or checkout
}

function git_search_by_ID (){
	# view commit details. git show command takes SHA-1 commit ID as a parameter. 
	#$ git show cbe1249b140dad24b2c35b15cc7e26a6f02d2277

	echo 'Usage: git show $ID from the above. Enter commit_id (hash):'
	read commit_id

	git show $commit_id
}

echo ""
: <<'NOTE_BLOCK'
Searches for commits using the provided keywords.
Formats the log output to highlight commit hash, message, author, and relative date.
NOTE_BLOCK
echo ""	

# git_log_search "keyword1" "keyword2" ....
function git_log_search() {
    local keywords=("$@")
    local grep_args=""

    # Prepare search arguments for each keyword and search in commit messages
    for keyword in "${keywords[@]}"; do
        grep_args+="--grep=${keyword}* "
    done

    # Perform the git log search with the 'grep' filtering
    GIT_PAGER=cat git log --color --pretty=format:'%C(yellow)%h%Creset %s %C(bold blue)<%an>%Creset %C(green)(%ar)%Creset' --regexp-ignore-case | grep -i "${keywords[0]}" | grep -i "${keywords[1]}"
}

echo ""
: <<'NOTE_BLOCK'
Searches for commits either before or after the specified date.
Formats the log output similarly to the git_log_search function.
Date format: YYYY-MM-DD.
NOTE_BLOCK
echo ""	

# Function to search for commits by date
function git_log_search_by_date() {
  local date=$1
  local direction=$2

  if [ "$direction" == "before" ]; then
    git log --before="$date" --color --pretty=format:'%C(yellow)%h%Creset %s %C(bold blue)<%an>%Creset %C(green)(%ar)%Creset' --date=local
  elif [ "$direction" == "after" ]; then
    git log --after="$date" --color --pretty=format:'%C(yellow)%h%Creset %s %C(bold blue)<%an>%Creset %C(green)(%ar)%Creset' --date=local
  else
    echo "Invalid direction. Use 'before' or 'after'."
    exit 1
  fi
}

echo ""
: <<'NOTE_BLOCK'
Resets or reverts to the specified commit based on the action provided.
reset performs a hard reset to the given commit.
revert reverts the changes made by all commits from the specified commit to the current HEAD without committing them immediately.
NOTE_BLOCK
echo ""	

# Function to reset or revert to a specified commit
function git_reset_or_revert() {
  local commit_id=$1
  local action=$2

  if [ "$action" == "reset" ]; then
    echo "Resetting to commit: $commit_id"
    git reset --hard "$commit_id"
  elif [ "$action" == "revert" ]; then
    echo "Reverting to commit: $commit_id"
    git revert --no-commit "$commit_id"..HEAD
    git commit -m "Revert to commit $commit_id"
  else
    echo "Invalid action. Use 'reset' or 'revert'."
    exit 1
  fi
}

# menu_git_reset_or_revert "$@"
# Function to display the menu and handle user input
function menu_git_reset_or_revert() {

    echo "[1] $0 search <keyword1> <keyword2> ..."
    echo "[2] $0 search-by-date <date> <before|after>"
    echo "[3] $0 reset-or-revert <commit_id> <reset|revert>"

    #read -p "Input Selection: " COMMAND # -r
    echo "Input Selection: "
    read COMMAND
    echo ""

#  if [ -z "$1" ]; then # no inputs
#  if [ $# -lt 1 ]; then # < 1 inputs
#  if [ $# -ne 2 ]; then # != 2 inputs
#  fi

  #COMMAND=$1
  #shift

  case "$COMMAND" in
    1) 
      echo "Usage: $0 search <keyword1> <keyword2> ..."; # search) # insteading of typing word `search`
      echo "Enter keywords (separated by spaces): ";
      read -r "$@";

      git_log_search "$@"
      ;;
    
    2) # search-by-date)
      echo "Usage: $0 search-by-date <date> <before|after>"
      read -r "DATE: " DATE
      read -r "DIRECTION: " DIRECTION

      #DATE=$1
      #DIRECTION=$2
      git_log_search_by_date "$DATE" "$DIRECTION"
      ;;
    
    3) # reset-or-revert)
      echo "Usage: $0 reset-or-revert <commit_id> <reset|revert>"
      read -r "COMMIT_ID: " COMMIT_ID
      read -r "ACTION: " ACTION

      #COMMIT_ID=$1
      #ACTION=$2
      git_reset_or_revert "$COMMIT_ID" "$ACTION"
      ;;
    
    *)
      echo "Invalid command. Use 'search', 'search-by-date', or 'reset-or-revert'."
      return 0;
      ;;
  esac

  echo ""
}

function git_show_line_index_by_ID (){
	# view commit details. git show command takes SHA-1 commit ID as a parameter. 
	#$ git show cbe1249b140dad24b2c35b15cc7e26a6f02d2277

	echo 'Usage: git show $ID from the above. Enter commit_id (hash):'
	read commit_id

	git log | cat -n | grep $commit_id
}

function git_remove_file (){
	# Delete Operation
	$ file $file_name

	comments='Remove file: '$file_name
	echo $comments
	git log
	git rm -f $file_name
	git commit -am $comments
	git push origin master
}

function git_create_patch (){
	# Patch is a text file, whose contents are similar to git diff, but along with code, it has metadata about commits; e.g., commit ID, date, commit message, etc.
	# create a patch from commits and other people can apply them to repo.
	# create a path of his code and send it to team. Then, he can apply the received patch to his code.
	git add .
	# `git format-patch` to create a patch for latest commit. to create a patch for a specific commit, then use COMMIT_ID with ` format-patch `.
	patch_file_created=$(git format-patch -1)
	echo "patch_file_created: " $patch_file_created
}

function git_apply_patch (){
	patch_file="$1" # $patch_file_created
	echo "applying patch_file: " $patch_file
	
	# Team can use patch to modify files. Git provides 2 commands to apply patches git am and git apply, respectively. Git apply modifies the local files without creating commit, while git am modifies file and creates commit as well. To apply patch and create commit:
	
	git status –s
	git apply $patch_file
	git status -s
	#M string_operations.c
	#?? 0001-Added-my_strcat-function.patch
	# patch gets applied, view modifications:
	git diff	
}

function git_name () {
	basename `git rev-parse --show-toplevel`
	# git remote show origin
	# basename -s .git `git config --get remote.origin.url`
	# 
	# basename $(git remote get-url origin)
}

function git_get_github_url (){
	github_url=$(git remote show origin | grep "https" | grep "Push  URL:")

	github_url=$(remove_prefix "$github_url" "  Push  URL: ")
	github_url=$(remove_suffix "$github_url" '.git')
	echo "$github_url"
}

chrome_exe_location="'/cygdrive/c/Program Files (x86)/Google/Chrome/Application/chrome.exe' "

function git_display_commit () {
	hash_id="$1"
	github_url=$(git_get_github_url)
	
	github_commit_url=$github_url"/commit/"$hash_id
	
	echo $github_commit_url
	eval ${chrome_exe_location} $github_commit_url
}

function git_resynch() {
	#git fetch # tells local git to retrieve the latest meta-data info from the original (yet doesn’t do any file transferring. just checking to see if there are any changes available).
	#git rebase origin/master
	
	if [ "$1" == '-h' ]; then
		echo "
	merge tries to put commits from other branches on top of the HEAD of the current local branch.

	For example, 
	local branch: A−>B−>C−>D 
	remote merge branch : A−>B−>X−>Y, 
	then git merge convert current local branch to: A−>B−>C−>D−>X−>Y
	
	rebase : tries to find out the common ancestor between the current local branch and the merge branch. It pushes the commits to the local branch by modifying the order of commits in the current local branch. branch merge command, but the difference is that it modifies the order of commits.

	For example, 
	local branch : A−>B−>C−>D 
	remote merge branch : A−>B−>X−>Y, 
	then Git rebase convert current local branch to: A−>B−>X−>Y−>C−>D.

		"
		return 0
	fi
	
	echo 'Fetch Latest Changes: synchronize local repository with remote'
	git pull
	git log
}

function git_review_changes() {
	echo "Review Changes:"
	echo "# diff files between local and remote #"
	git diff		# diff shows '+' sign before lines, which are newly added and '−' for deleted lines.
}

function git_review_latest_N_commits() {
	echo "Usage: git_review_latest_N_commits N"
	git log -"$1"
	echo ""
	echo "At local:"
	cat .git/refs/heads/master
}

function git_config_review(){
	echo "# check settings"
	git config --list
}

function git_test_connection(){
	ssh -T git@github.com;
	git ls-remote;
}

function git_main() {
	git_menu;
	
	number_of_digits_for_inputs=2
	# read  -n 1 -p "Input Selection:" git_menu_input
	read  -n $number_of_digits_for_inputs -p "Input Selection:" git_menu_input
	echo ""
	
    if [ "$git_menu_input" = "1" ]; then
		#		
		git_commit_and_push_to_main # $comments;
    elif [ "$git_menu_input" = "2" ]; then
		git_show_line_index_by_ID; #$id; 	
	elif [ "$git_menu_input" = "3" ]; then
		git_latest_status;
    elif [ "$git_menu_input" = "4" ]; then
		git_which_repo;
    elif [ "$git_menu_input" = "5" ]; then
		git_search_by_ID;
    elif [ "$git_menu_input" = "6" ];then
		git_name;
    elif [ "$git_menu_input" = "7" ];then
		git_review_changes;
    elif [ "$git_menu_input" = "8" ];then
		git_resynch;
    elif [ "$git_menu_input" = "9" ];then
		git_test_connection;
	elif [ "$git_menu_input" = "10" ];then		
		read -r -p "file_name [e.g. ./read.me:] : "  file_name
			
		read -r -p "comments [e.g. reason for file removal:] : "  comments
	
		git_remove_file;

    elif [ "$git_menu_input" = "11" ];then	
		git_get_github_url;

    elif [ "$git_menu_input" = "12" ];then
		read -r -p "hash_id [e.g. from git log] : "  hash_id
		
		git_display_commit $hash_id;
    elif [ "$git_menu_input" = "13" ];then	
		git_create_patch;
    elif [ "$git_menu_input" = "14" ];then	
		ls;
		read -r -p "Apply path_file [] : "  path_file
		
		git_apply_patch;		
    elif [ "$git_menu_input" = "c" ];then
		./connect.sh
    elif [ "$git_menu_input" = "v" ];then		
		git_config_review;
    elif [ "$git_menu_input" = "x" -o "$git_menu_input" = "X" ];then # -o := `or` and `||`
		exit_program_for_menu;
    else
		git_main_default_action;
    fi
	
}

function git_view_all_branches() {
	git branch
	echo ""
	echo "to switch branches (create or switch if exist): git branch <branch_name>"
	echo "to switch branches (switch if exist): git checkout <branch_name>"	
}

function git_menu() {
  echo "1 : git_commit_and_push_to_main"
  echo "2 : git_show_line_index_by_ID"   
  echo "3 : git_latest_status"
  echo "4 : git_which_repo"  
  echo "5 : git_search_by_ID"
  echo "6 : git_name"
  echo "7 : git_review_changes" 
  echo "8 : git_resynch"
  echo "9 : git_test_connection"  
  echo "10 : git_remove_file"  
  echo "11: git_get_github_url"    
  echo "12: git_display_commit <commit_ID>"
  echo "13: git_create_patch"
  echo "14: git_apply_patch"
  echo "c: git_connect"
  echo "v: git_config_review"  
  echo ""
  echo "'x' or 'X' to exit the script"
  
  date +"%T.%N"
  date +%s
  get_timestamp
}

function git_main_default_action() {
    echo "You have entered an invallid selection!"
    echo "Please try again!"
    echo ""
    echo "Press any key to continue..."
    read -n 1
    clear
	set -u # force it to treat unset variables as an error 
	unset git_menu_input
	#echo $git_menu_input 
    git_main
}

# Make Git store the username and password and it will never ask for them.
# git config --global credential.helper store
# git config --global credential.helper 'cache --timeout=600'

# Different Platforms: Linux and Mac OS uses line-feed (LF), or new line as line ending character
# Windows uses line-feed and carriage-return (LFCR) combination to represent the line-ending character.
# To avoid unnecessary commits because of these line-ending differences, configure Git client to write the same line ending to the Git repository.
# Windows system: configure Git client to convert line endings to CRLF format while checking out, and convert them back to LF format during the commit operation. 
#git config --global core.autocrlf true


# GNU/Linux or Mac OS, configure Git client to convert line endings from CRLF to LF while performing the checkout operation.
#git config --global core.autocrlf input

function generate_key_for_git {
    # Prompt for the key RSA length and email address
    echo "Enter the RSA key length (e.g., 4096):"
    read -r key_rsa_length

    echo "Enter the email address to associate with the key:"
    read -r email_address

    # Ensure the .ssh directory exists
    mkdir -p "$HOME/.ssh"

    while true; do
        # Prompt for the key name
        echo "Enter a name for the key to be stored in ~/.ssh/ (e.g., id_ursa_rsa):"
        read -r key_name

        # Check if the key file already exists
        if [ -f "$HOME/.ssh/$key_name" ] || [ -f "$HOME/.ssh/$key_name.pub" ]; then
            echo "Key file already exists. Please choose another name."
        else
            break
        fi
    done

    # Generate the SSH key
    ssh-keygen -t rsa -b "$key_rsa_length" -C "$email_address" -f "$HOME/.ssh/$key_name"

    # Store the private key path
    private_key_path="$HOME/.ssh/$key_name"

    # Derive the public key from the private key
    ssh-keygen -f "$private_key_path" -y > "$private_key_path.pub"

    # Print the demarcator message
    echo "======================"
    echo "Add this public key to your Github account"
    echo "======================"
    # Output the public key
    cat "$private_key_path.pub"
}

function login_with_git_key {
    # List the available keys in the ~/.ssh directory
    echo "Available keys in ~/.ssh/:"
    ls -1 ~/.ssh/

    # Prompt for the private key name to use for authentication
    echo "Enter the private key name to use for Git (e.g., id_ursa_rsa):"
    read -r key_name

    key_path="$HOME/.ssh/$key_name"

    # Check if the key file exists
    if [ ! -f "$key_path" ]; then
        echo "Key file does not exist. Please make sure the key name is correct."
        return 1
    fi

    # Start the ssh-agent in the background
    eval $(ssh-agent -s)

    # Add the specified private key
    ssh-add "$key_path"

    # Confirm the key was added
    if [ $? -eq 0 ]; then
        echo "Key added successfully."
    else
        echo "Failed to add the key."
        return 1
    fi

    # Display the current Git configuration
    echo "Git user profile set."
    git config --list
}

function derive_git_key_sha() {
    # Prompt for the path to the SSH key
    echo "Enter the path to your SSH private key (e.g., ~/.ssh/id_rsa): "
    read -r key_path

    # Expand the tilde to the full home directory path
    key_path=${key_path/#\~/$HOME}

    # Check if the file exists
    if [ ! -f "$key_path" ]; then
        echo "The specified file does not exist. Please check the path and try again."
        return 1
    fi

    # Calculate the SHA-256 hash
    sha_result=$(openssl dgst -sha256 "$key_path" | awk '{print $2}')

    # Display the result
    echo "SHA-256: $sha_result"

    # Calculate the SHA-256 hash and derive the Git-compatible format
    sha_result=$(ssh-keygen -E sha256 -lf "$key_path" | awk '{print $2}')

    if [ -z "$sha_result" ]; then
        echo "Failed to derive SHA256 from the key."
        return 1
    fi

    echo "$sha_result"    
}

# sample usage: initialize_1st_git_repo "https://github.com/ursa-mikail/shell_script_utility.git"
function initialize_1st_git_repo() {
    local remote_url="$1"
    
    if [ -z "$remote_url" ]; then
        echo "Usage: initialize_git_repo <remote_repository_url>"
        return 1
    fi

    # Create the folder if it doesn't exist
    # create_folder_if_not_exist "$repo_path" "repository directory"

    # $repo_path: e.g. ~/ursa/git/shell_script_utility
    # Navigate to the project directory
    #cd "$repo_path" || { echo "Failed to navigate to '$repo_path'"; return 1; }

    echo "Initializing Git repository in '$PWD'..."
    git init

    # git remote add origin https://github.com/ursa-mikail/shell_script_utility.git
    echo "Adding remote origin '$remote_url'..."
    git remote add origin "$remote_url"

    echo "Creating and switching to the main branch..."
    git branch -M main

    echo "Adding all files to the staging area..."
    git add .

    echo "Committing the files with message 'Initial commit'..."
    git commit -m "Initial commit"

    echo "Pushing to the remote repository..."
    git push -u origin main

    echo "Git repository initialized and pushed successfully."
}


function fetch_from_remote() {
    # Check if the user is logged in by attempting to SSH into GitHub
    ssh -T git@github.com &>/dev/null
    if [ $? -ne 1 ]; then
        echo "You are logged in to GitHub."
    else
        echo "You are not logged in to GitHub. Please log in first."
        return 1
    fi

    # Prompt the user for the remote source
    echo "Enter the remote source (default: origin): "
    read -r remote_name

    remote_name=${remote_name:-origin}  # Default to 'origin' if no input

    # Fetch changes from the specified remote
    echo "Fetching changes from remote '$remote_name'..."
    git fetch "$remote_name"

    # Check the status of local branches
    echo "Checking status of local branches..."
    git status

    echo "Fetching completed. You can merge changes from the remote branch if needed."
}

function force_all_updates(){
	git fetch origin
	git reset --hard origin/main
}

# Example usage: # manage_merge master feature-branch # master <--- feature-branch
function manage_merge() {
    local target_branch=$1
    local feature_branch=$2

    # Check if both branches are provided
    if [[ -z "$target_branch" || -z "$feature_branch" ]]; then
        echo "Usage: manage_merge <target_branch> <feature_branch>"
        return 1
    fi

    # Display current branch and all branches
    current_branch=$(git symbolic-ref --short -q HEAD)
    echo "You are currently on branch: $current_branch"
    echo "All branches:"
    git branch

    # Check if the user is on the target branch
    if [[ "$current_branch" != "$target_branch" ]]; then
        echo "Switching to target branch: $target_branch"
        git checkout $target_branch
        if [[ $? -ne 0 ]]; then
            echo "Error: Could not check out branch $target_branch"
            return 1
        fi
        echo "Now on branch: $target_branch"
    else
        echo "Already on target branch: $target_branch"
    fi

    # Merge the feature branch into the target branch
    git merge $feature_branch
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not merge branch $feature_branch into $target_branch"
        return 1
    fi

    # Delete the feature branch locally
    git branch -d $feature_branch
    if [[ $? -ne 0 ]]; then
        echo "Error: Could not delete local branch $feature_branch"
        return 1
    fi

    # Delete the feature branch remotely if it exists
    git push origin --delete $feature_branch
    if [[ $? -ne 0 ]]; then
        echo "Warning: Could not delete remote branch $feature_branch"
        # Not returning an error here, since local deletion is often sufficient
    fi

    # Announce the branch deletion
    echo "Branch '$feature_branch' has been successfully merged into '$target_branch' and deleted."

    echo "All branches:"
    git branch    
}


function manage_branch() {
    echo "Current branches:"
    git branch

    echo "Choose an action:"
    echo "1. Create a new branch"
    echo "2. Switch to an existing branch"
    echo "3. Delete a branch"
    printf "Enter the number of your choice: "
    read action

    case $action in
        1)
            printf "Enter the name of the new branch: "
            read new_branch
            git checkout -b "$new_branch"
            ;;
        2)
            printf "Enter the name of the branch to switch to: "
            read switch_branch
            git checkout "$switch_branch"
            ;;
        3)
            printf "Enter the name of the branch to delete: "
            read delete_branch
            git branch -d "$delete_branch"
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or 3."
            ;;
    esac

    echo "Current branches:"
    git branch    
}

# make_git_folder 'Image Blur Effect'
function make_git_folder() {
    # Convert the provided folder name to snake_case
    folder_name=$(str_to_snake_case "$1")
    
    # Create the folder and navigate into it
    create_and_goto_folder "$folder_name"
    
    # Create and open the .py file and readme.md file in Sublime Text
    subl "${folder_name}.py"
    subl "readme.md"
}

function which_key_is_for_git() {
    ssh -vT git@github.com 2>&1 | grep "Offering public key" | awk '{print $NF}'
    ssh -vT git@github.com 2>&1 | grep "Offering public key" | sed -E 's/.*Offering public key: ([^ ]+) .*/\1/'
}

function test_private_key() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: test_private_key <private_key_filename>"
        return 1
    fi

    key_file="$1"

    echo 'list all keys'
    ls $HOME/.ssh
    echo '-----------------'

    # If the provided key name doesn't include a full path, assume ~/.ssh/
    if [[ "$key_file" != /* ]]; then
        key_file="$HOME/.ssh/$key_file"
    fi

    pub_key="${key_file}.pub"

    if [ ! -f "$key_file" ]; then
        echo "Error: Private key '$key_file' does not exist."
        return 1
    fi

    if [ ! -f "$pub_key" ]; then
        echo "Error: Public key '$pub_key' does not exist."
        return 1
    fi

    fingerprint_priv=$(ssh-keygen -lf "$key_file" | awk '{print $2}')
    fingerprint_pub=$(ssh-keygen -lf "$pub_key" | awk '{print $2}')

    echo 'fingerprint_priv: ' $fingerprint_priv
	echo 'fingerprint_pub: ' $fingerprint_pub

    if [ "$fingerprint_priv" = "$fingerprint_pub" ]; then
        echo "Match: $key_file corresponds to $pub_key"
    else
        echo "Mismatch: $key_file does NOT match $pub_key"
    fi
}




echo ""
: <<'NOTE_BLOCK'
    # Prompt the user for the remote source
    read -p "Enter the remote source (default: origin): " remote_name
    remote_name=${remote_name:-origin}  # Use 'origin' if the user just presses Enter

    # Prompt for the branch name to fetch
    read -p "Enter the branch name to fetch (default: main): " branch_name
    branch_name=${branch_name:-main}  # Use 'main' if the user just presses Enter

    # Fetch from the specified remote and branch
    git fetch "$remote_name" "$branch_name"

    # Check if the fetch was successful
    if [ $? -eq 0 ]; then
        echo "Successfully fetched from $remote_name/$branch_name."
    else
        echo "Failed to fetch from $remote_name/$branch_name."
    fi

NOTE_BLOCK
echo ""	


