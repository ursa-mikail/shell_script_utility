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

# Delete a remote branch and prune stale refs
git_delete_remote_branch() {
  if [ -z "$1" ]; then
    echo "Usage: git_delete_remote_branch <branch-name>"
    return 1
  fi
  git push origin --delete "$1" 2>/dev/null
  git fetch --prune
}

# Delete a local branch (safe, auto-switch if needed)
git_delete_local_branch() {
  if [ -z "$1" ]; then
    echo "Usage: git_delete_local_branch <branch-name>"
    return 1
  fi

  current_branch=$(git branch --show-current)
  if [ "$current_branch" = "$1" ]; then
    echo "You are on branch '$1'. Switching to 'main' before deletion..."
    git checkout main || return 1
  fi

  echo -n "Are you sure you want to delete local branch '$1'? (y/N) "
  read confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    git branch -D "$1"
  else
    echo "Aborted."
  fi
}


# git_delete_branch feature-x --local   # only local
# git_delete_branch feature-x --remote  # only remote
# git_delete_branch feature-x --both    # local + remote (default)
# git_delete_branch feature-x           # also defaults to both
# Delete both local and remote branches
git_delete_branch() {
  if [ -z "$1" ]; then
    echo "Usage: git_delete_branch <branch-name> [--local] [--remote] [--both]"
    return 1
  fi

  local branch="$1"
  local target="${2:---both}"  # default is both if no flag provided

  case "$target" in
    --local)
      git_delete_local_branch "$branch"
      ;;
    --remote)
      git_delete_remote_branch "$branch"
      ;;
    --both)
      git_delete_remote_branch "$branch"
      git_delete_local_branch "$branch"
      ;;
    *)
      echo "Invalid option. Use --local, --remote, or --both."
      return 1
      ;;
  esac
}

# git_create_branch feature-x         # creates and switches to branch locally
# git_create_branch feature-x --push  # creates, switches, and pushes to origin
# Create and switch to a new branch
git_create_branch() {
  if [ -z "$1" ]; then
    echo "Usage: git_create_branch <branch-name> [--push]"
    return 1
  fi

  local branch="$1"
  local push_flag="$2"

  # Create and switch
  git checkout -b "$branch"

  # Optionally push to remote
  if [ "$push_flag" = "--push" ]; then
    git push -u origin "$branch"
  fi
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

    touch '.gitignore'
    echo '.DS_Store' >> '.gitignore'
    echo '.gitignore' >> '.gitignore'
    
    # Create the file
	touch "${folder_name}.py"

	# Write title-cased comment into the first line
	## no space
	# echo "# $(echo "${folder_name}" | awk -F'_' '{for (i=1; i<=NF; i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' OFS='')" > "${folder_name}.py"
	## with space
	# echo "# $(echo "${folder_name}" | awk -F'_' '{for (i=1; i<=NF; i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' OFS=' ')" > "${folder_name}.py"
	echo "# $(str_to_title_case "${folder_name}") " >> "${folder_name}.py"

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

function git_refresh() {
	git fetch --all;
	git pull --all;
}

function forced_refresh_and_align_with_remote() {
	# Ensure you're on the correct branch
	git checkout main  # Replace 'main' with your branch name

	# Reset your branch to match the remote, discarding local changes
	git fetch origin
	git reset --hard origin/main
}

# Function to create a new git branch and show all branches
function make_git_branch() {
  if [ -z "$1" ]; then
    echo "Usage: make_git_branch <branch-name>"
    return 1
  fi
  git checkout -b "$1"
  echo "📌 Created and switched to branch: $1"
  echo "📋 Current branches:"
  git branch
}
 
# Function to stage, commit, and remind to push
function commit_changes_to_branch() {
  read -p "📝 Enter commit message: " commit_msg
  git add .
  git commit -m "$commit_msg"
  echo "✅ Committed changes with message: \"$commit_msg\""
  echo "📋 Current branches:"
  git branch

  echo ""
  echo "🚀 Almost done! To open a Pull Request:"
  echo "----------------------------------------"
  echo '1. Run: git push origin <your-branch-name>'
  echo "2. Go to your repo URL"
  echo '3. Click "Compare & pull request" or "New Merge Request".'
  echo "----------------------------------------"
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

#!/usr/bin/env zsh
# git-feature-menu.zsh
# Interactive zsh helper for a feature-branch workflow
# Usage:
#   chmod +x git-feature-menu.zsh
#   ./git-feature-menu.zsh

# --- Safety / UX notes ---
# - Designed for zsh (uses zsh-style read prompts). Should work in bash for most commands,
#   but it's optimized for zsh interactive use.
# - The script won't force destructive actions without confirmation.
# - If you have the GitHub CLI (`gh`) installed, the "Open PR" step will use it.
# - Uses your $EDITOR for multi-line commit messages when requested.

# Colors
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[0;33m')
BLUE=$(printf '\033[0;34m')
RESET=$(printf '\033[0m')

# Globals
GH_AVAILABLE=0
DEFAULT_BRANCH="main"
CURRENT_REPO=""
CURRENT_BRANCH=""

trap 'printf "\n${YELLOW}Interrupted. Returning to menu...${RESET}\n"' INT

# --- Helpers ---
check_requirements() {
  if ! command -v git >/dev/null 2>&1; then
    printf "%s\n" "${RED}Error: git not found in PATH. Install git and retry.${RESET}";
    exit 1
  fi
  if command -v gh >/dev/null 2>&1; then
    GH_AVAILABLE=1
  fi
}

is_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

ensure_repo_or_clone() {
  if is_git_repo; then
    CURRENT_REPO=$(git rev-parse --show-toplevel 2>/dev/null)
    printf "%s\n" "${GREEN}Detected git repo: ${CURRENT_REPO}${RESET}"
    cd "$CURRENT_REPO" || return 1
  else
    read "url?Repository URL to clone (git@... or https://...): "
    if [[ -z "$url" ]]; then
      printf "%s\n" "${YELLOW}No URL entered — returning to menu.${RESET}"; return 1
    fi
    git clone "$url" || { printf "%s\n" "${RED}Clone failed.${RESET}"; return 1 }
    # cd into cloned dir
    repo_dir=$(basename "$url" .git)
    cd "$repo_dir" || return 1
    CURRENT_REPO=$(pwd)
    printf "%s\n" "${GREEN}Cloned into ${CURRENT_REPO}${RESET}"
  fi
  update_repo_state
}

update_repo_state() {
  if is_git_repo; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    # detect default branch from origin
    if git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}' >/dev/null 2>&1; then
      detected=$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
      if [[ -n "$detected" ]]; then
        DEFAULT_BRANCH=$detected
      fi
    fi
  else
    CURRENT_BRANCH=""
  fi
}

confirm() {
  # usage: confirm "Message"
  read "ans?${1:-Are you sure?} (y/N): "
  case "$ans" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

sanitize_branch_name() {
  # lower, replace spaces and illegal chars with '-'
  print -r -- "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._\/-]/-/g'
}

# --- Actions ---
action_status_log() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo. Use option 1 to clone or cd into one.${RESET}"; return; fi
  printf "\n${BLUE}--- Status ---${RESET}\n"
  git status --short
  printf "\n${BLUE}--- Recent commits ---${RESET}\n"
  git log --oneline --graph --decorate -n 20
  read "REPLY?Press Enter to continue..."
}

action_create_branch() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo. Use option 1 to clone or cd into one.${RESET}"; return; fi
  read "branch?Branch name (leave blank to build from issue + desc): "
  if [[ -z "$branch" ]]; then
    read "issue?Issue/ticket number (optional, e.g. 123): "
    read "desc?Short description (e.g. add-search): "
    desc_s=$(sanitize_branch_name "$desc")
    if [[ -n "$issue" ]]; then
      branch="feat/${issue}-${desc_s}"
    else
      branch="feat/${desc_s}"
    fi
  fi
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    printf "%s\n" "${YELLOW}Local branch $branch already exists. Checking it out.${RESET}"
    git checkout "$branch" || { printf "%s\n" "${RED}Failed to checkout $branch${RESET}"; return; }
  else
    git checkout -b "$branch" || { printf "%s\n" "${RED}Failed to create branch $branch${RESET}"; return; }
  fi
  CURRENT_BRANCH=$branch
  printf "%s\n" "${GREEN}Now on branch: $CURRENT_BRANCH${RESET}"
}

action_add_and_commit() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo.${RESET}"; return; fi
  printf "\n${BLUE}Git status:${RESET}\n"
  git status --short
  read "how?Add mode: (p)atch, (a)ll, (s)elect files, (n)one: "
  case "$how" in
    p|P) git add -p ;;
    a|A) git add -A ;;
    s|S)
      printf "%s\n" "Enter paths one per line; empty line finishes."
      files=()
      while true; do
        read "f?path (blank to finish): "
        [[ -z "$f" ]] && break
        files+=($f)
      done
      if (( ${#files[@]} )); then
        git add "${files[@]}"
      fi
      ;;
    *) printf "%s\n" "No files added."; return ;;
  esac

  # commit message
  read "use_editor?Open $EDITOR for a multi-line commit message? (y/N): "
  if [[ "$use_editor" =~ ^([yY].*)$ ]]; then
    tmpf=$(mktemp /tmp/gitmsg.XXXXXX)
    ${EDITOR:-vi} "$tmpf"
    if [[ -s "$tmpf" ]]; then
      git commit -F "$tmpf" || { printf "%s\n" "${RED}Commit failed.${RESET}"; rm -f "$tmpf"; return; }
    else
      printf "%s\n" "${YELLOW}Empty message — aborting commit.${RESET}"
      rm -f "$tmpf"
      return
    fi
    rm -f "$tmpf"
  else
    read "msg?One-line commit message: "
    [[ -z "$msg" ]] && { printf "%s\n" "${YELLOW}Empty message — aborting commit.${RESET}"; return; }
    git commit -m "$msg" || { printf "%s\n" "${RED}Commit failed.${RESET}"; return; }
  fi
  printf "%s\n" "${GREEN}Committed successfully.${RESET}"
}

action_push_branch() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo.${RESET}"; return; fi
  if [[ -z "$CURRENT_BRANCH" || "$CURRENT_BRANCH" == "HEAD" ]]; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  fi
  if [[ -z "$CURRENT_BRANCH" ]]; then printf "%s\n" "${RED}Could not detect current branch.${RESET}"; return; fi
  git push -u origin "$CURRENT_BRANCH" || { printf "%s\n" "${RED}Push failed.${RESET}"; return; }
  printf "%s\n" "${GREEN}Pushed $CURRENT_BRANCH -> origin/${CURRENT_BRANCH}${RESET}"
}

action_open_pr() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo.${RESET}"; return; fi
  read "title?PR title (leave blank to use last commit): "
  if [[ -z "$title" ]]; then
    title=$(git log -1 --pretty=%s 2>/dev/null)
  fi
  read "body?PR body (leave blank to open editor): "
  if [[ -z "$body" ]]; then
    if [[ -n "$EDITOR" ]]; then
      tmpf=$(mktemp /tmp/prbody.XXXXXX)
      ${EDITOR} "$tmpf"
      body=$(cat "$tmpf")
      rm -f "$tmpf"
    fi
  fi

  if [[ $GH_AVAILABLE -eq 1 ]]; then
    printf "%s\n" "${BLUE}Creating PR using gh...${RESET}"
    gh pr create -t "$title" -b "$body" -B "$DEFAULT_BRANCH" || { printf "%s\n" "${RED}gh failed to create PR.${RESET}"; return; }
    printf "%s\n" "${GREEN}PR created via gh.${RESET}"
    return
  fi

  # fallback: craft GitHub compare URL from origin
  origin_url=$(git remote get-url origin 2>/dev/null)
  if [[ -z "$origin_url" ]]; then
    printf "%s\n" "${RED}No origin remote detected.${RESET}"; return; fi

  if [[ "$origin_url" =~ git@([^:]+):(.+)\.git ]]; then
    host=${match[1]}
    repo=${match[2]}
    https_url="https://${host}/${repo}"
  else
    # handle https://host/user/repo(.git)
    https_url=$(echo "$origin_url" | sed -E 's/\.git$//')
  fi
  pr_url="$https_url/compare/${DEFAULT_BRANCH}...${CURRENT_BRANCH}?expand=1"
  printf "%s\n" "${GREEN}Open this URL to create a PR:${RESET}"
  printf "%s\n" "$pr_url"
  if command -v open >/dev/null 2>&1; then
    open "$pr_url"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$pr_url" >/dev/null 2>&1 || true
  fi
}

action_rebase_onto_default() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo.${RESET}"; return; fi
  read "branch?Branch to rebase (leave blank for current ${CURRENT_BRANCH}): "
  branch=${branch:-$CURRENT_BRANCH}
  if [[ -z "$branch" ]]; then printf "%s\n" "${RED}No branch specified.${RESET}"; return; fi
  git fetch origin || { printf "%s\n" "${RED}Fetch failed.${RESET}"; return; }
  printf "%s\n" "${BLUE}Rebasing $branch onto origin/${DEFAULT_BRANCH}...${RESET}"
  git checkout "$branch" || { printf "%s\n" "${RED}Checkout failed.${RESET}"; return; }
  if ! git rebase "origin/${DEFAULT_BRANCH}"; then
    printf "%s\n" "${YELLOW}Rebase stopped due to conflicts. Resolve them, then run: git add <file>; git rebase --continue${RESET}"
    return
  fi
  printf "%s\n" "${GREEN}Rebase succeeded. Remember to: git push --force-with-lease${RESET}"
  read "do_force?Run git push --force-with-lease now? (y/N): "
  if [[ "$do_force" =~ ^([yY].*)$ ]]; then
    git push --force-with-lease origin "$branch" || { printf "%s\n" "${RED}Force-push failed.${RESET}"; }
  fi
}

action_interactive_rebase() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo.${RESET}"; return; fi
  read "n?Number of commits to edit/squash (e.g. 4): "
  if ! [[ "$n" =~ ^[0-9]+$ ]]; then printf "%s\n" "${YELLOW}Invalid number.${RESET}"; return; fi
  git rebase -i "HEAD~${n}"
}

action_merge_locally() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo.${RESET}"; return; fi
  read "branch?Branch to merge into ${DEFAULT_BRANCH} (leave blank for current ${CURRENT_BRANCH}): "
  branch=${branch:-$CURRENT_BRANCH}
  if [[ -z "$branch" ]]; then printf "%s\n" "${RED}No branch specified.${RESET}"; return; fi
  if confirm "Merge ${branch} into ${DEFAULT_BRANCH}?"; then
    git checkout "$DEFAULT_BRANCH" || { printf "%s\n" "${RED}Checkout failed.${RESET}"; return; }
    git pull origin "$DEFAULT_BRANCH" || { printf "%s\n" "${RED}Pull failed.${RESET}"; return; }
    git merge --no-ff "$branch" || { printf "%s\n" "${RED}Merge failed.${RESET}"; return; }
    git push origin "$DEFAULT_BRANCH" || { printf "%s\n" "${RED}Push failed.${RESET}"; return; }
    printf "%s\n" "${GREEN}Merged and pushed.${RESET}"
  fi
}

action_delete_branch() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo.${RESET}"; return; fi
  read "branch?Branch to delete (leave blank for current ${CURRENT_BRANCH}): "
  branch=${branch:-$CURRENT_BRANCH}
  if [[ -z "$branch" ]]; then printf "%s\n" "${RED}No branch specified.${RESET}"; return; fi
  if confirm "Delete local branch ${branch}?"; then
    git branch -d "$branch" || git branch -D "$branch" || printf "%s\n" "${YELLOW}Local delete may have failed or branch not fully merged.${RESET}";
  fi
  if confirm "Also delete remote origin/${branch}?"; then
    git push origin --delete "$branch" || printf "%s\n" "${YELLOW}Remote delete may have failed.${RESET}";
  fi
}

action_undo_last_commit() {
  update_repo_state
  if ! is_git_repo; then printf "%s\n" "${YELLOW}Not inside a git repo.${RESET}"; return; fi
  printf "%s\n" "Choose undo option:"
  printf "1) Soft reset (uncommit, keep changes staged)\n"
  printf "2) Mixed reset (uncommit, keep changes unstaged)\n"
  printf "3) Hard reset (DANGEROUS: discard changes)\n"
  printf "4) Revert (create a new commit that undoes last commit)\n"
  read "opt?Select [1-4]: "
  case "$opt" in
    1) git reset --soft HEAD~1 ;;
    2) git reset --mixed HEAD~1 ;;
    3) if confirm "Really discard working tree changes and remove last commit?"; then git reset --hard HEAD~1 ; fi ;;
    4) git revert HEAD ;;
    *) printf "%s\n" "${YELLOW}Cancelled.${RESET}"; return ;;
  esac
  printf "%s\n" "${GREEN}Done.${RESET}"
}

print_steps() {
  cat <<-EOF
  Step-by-step recommended flow (menu numbers):
  1) Clone or detect repo (Menu 1)
  2) Create a feature branch (Menu 2)
  3) Add & commit your changes (Menu 3)
  4) Push the branch to origin (Menu 4)
  5) Open a PR (Menu 5)
  6) Rebase your branch onto the latest ${DEFAULT_BRANCH} (Menu 6)
  7) Interactive rebase / squash commits if desired (Menu 7)
  8) Merge locally (or merge via PR) (Menu 8)
  9) Delete branch local & remote (Menu 9)
  10) Status & log to verify (Menu 10)
  11) Undo last commit safely if you need to (Menu 11)
  12) Exit
EOF
}

# --- Menu ---
main_menu_git() {
  check_requirements
  while true; do
    update_repo_state
    printf "\n${BLUE}=== Git Feature Menu ===${RESET}\n"
    printf "Current repo: %s\n" "${CURRENT_REPO:-(none)}"
    printf "Current branch: %s\n" "${CURRENT_BRANCH:-(none)}"
    printf "Default branch: %s\n\n" "${DEFAULT_BRANCH}"
    printf "1) Clone / Detect repo\n"
    printf "2) Create or checkout feature branch\n"
    printf "3) Add & commit changes\n"
    printf "4) Push current branch to origin\n"
    printf "5) Open PR (gh or web fallback)\n"
    printf "6) Rebase branch onto %s\n" "${DEFAULT_BRANCH}"
    printf "7) Interactive rebase (squash / fixup)\n"
    printf "8) Merge branch into ${DEFAULT_BRANCH} locally\n"
    printf "9) Delete branch (local & remote)\n"
    printf "10) Status & recent commits\n"
    printf "11) Undo last commit\n"
    printf "12) Show quick steps\n"
    printf "q) Quit\n"
    read "choice?Choose an option: "
    case "$choice" in
      1) ensure_repo_or_clone ;;
      2) action_create_branch ;;
      3) action_add_and_commit ;;
      4) action_push_branch ;;
      5) action_open_pr ;;
      6) action_rebase_onto_default ;;
      7) action_interactive_rebase ;;
      8) action_merge_locally ;;
      9) action_delete_branch ;;
      10) action_status_log ;;
      11) action_undo_last_commit ;;
      12) print_steps ;;
      q|Q) printf "%s\n" "${GREEN}Goodbye!${RESET}"; break ;;
      *) printf "%s\n" "${YELLOW}Unknown option — try again.${RESET}" ;;
    esac
  done
}

# --- Entrypoint ---
# main_menu_git

echo ""
: <<'NOTE_BLOCK'

Practices & checklist before merging
✅ Small, focused PR (ideally <500 lines changed).
✅ Passes CI (tests + linters).
✅ Good commit messages (or use squash).
✅ Linked to an issue / ticket.
✅ At least one approving review.
✅ Rebased onto latest main (or merge conflicts resolved).
✅ Changelog or release notes updated (if required).

1) Clone / Detect repo

Menu: 1
Prompt: Repository URL to clone (git@... or https://...): → you type:

git@github.com:your-org/awesome-app.git


Script runs:

git clone git@github.com:your-org/awesome-app.git
cd awesome-app


Output (example):

Cloned into /home/me/awesome-app
Detected git repo: /home/me/awesome-app

2) Create or checkout a feature branch

Menu: 2
Prompt: Branch name (leave blank to build from issue + desc): → leave blank
Prompt: Issue/ticket number (optional, e.g. 123): → 123
Prompt: Short description (e.g. add-search): → add-search

Script builds feat/123-add-search and runs:

git checkout -b feat/123-add-search


Output:

Switched to a new branch 'feat/123-add-search'
Now on branch: feat/123-add-search

3) Add & commit changes

Menu: 3
Script shows git status --short. You type a to add all changed files.
Prompt: Open $EDITOR for multi-line? (y/N): → n
Prompt: One-line commit message: →

feat(search): add basic server-side search endpoint


Script runs:

git add -A
git commit -m "feat(search): add basic server-side search endpoint"


Output:

[feat/123-add-search 1a2b3c4] feat(search): add basic server-side search endpoint
 5 files changed, 120 insertions(+), 2 deletions(-)
Committed successfully.

4) Push current branch to origin

Menu: 4
Script runs:

git push -u origin feat/123-add-search


Output:

Counting objects: ... done
Pushed feat/123-add-search -> origin/feat/123-add-search (upstream set)

5) Open PR

Menu: 5
Script checks for gh. If gh exists it will run:

gh pr create -t "feat(search): add basic server-side search endpoint" -b "<body>" -B main


If gh not available it prints a URL:

Open this URL to create a PR:
https://github.com/your-org/awesome-app/compare/main...feat/123-add-search?expand=1


(Your browser may open automatically if open or xdg-open exists.)

6) Rebase branch onto default (main)

Menu: 6
Prompt: Branch to rebase (leave blank for current): → press Enter
Script runs:

git fetch origin
git checkout feat/123-add-search
git rebase origin/main


If rebase succeeds: script suggests git push --force-with-lease.

If there’s a conflict it prints:

Rebase stopped due to conflicts. Resolve them, then run:
  git add <file>
  git rebase --continue
or abort: git rebase --abort


Conflict resolution example:

# edit files to remove conflict markers
git add src/search.js
git rebase --continue
# after success
git push --force-with-lease origin feat/123-add-search

7) Interactive rebase (squash/fixup)

Menu: 7
Prompt: Number of commits to edit/squash (e.g. 4): → 3
Script runs:

git rebase -i HEAD~3


You’ll get the editor to mark pick/s/f. After the rebase, if history changed:

git push --force-with-lease

8) Merge branch into main locally

Menu: 8
Prompt: Branch to merge into main (leave blank for current): → press Enter
Confirm Merge feat/123-add-search into main? (y/N): → y
Script runs:

git checkout main
git pull origin main
git merge --no-ff feat/123-add-search
git push origin main


Output:

Merge made by the 'recursive' strategy.
 Pushed main
Merged and pushed.


(Or use the PR UI to merge instead.)

9) Delete branch (local & remote)

Menu: 9
Prompt: Branch to delete (leave blank for current): → feat/123-add-search
Confirm local deletion: y
Script runs:

git branch -d feat/123-add-search   # falls back to -D if needed


Confirm remote deletion: y
Script runs:

git push origin --delete feat/123-add-search


Output:

Deleted branch feat/123-add-search (was abc1234).
To github.com:your-org/awesome-app.git
 - [deleted]         feat/123-add-search

10) Status & recent commits

Menu: 10
Script runs:

git status --short
git log --oneline --graph --decorate -n 20


Use this to verify everything looks good.

11) Undo last commit (if needed)

Menu: 11
Options prompt (choose e.g. 1 for soft reset). Example: 1 runs:

git reset --soft HEAD~1


That leaves changes staged so you can edit the commit and recommit.

12) Show quick steps

Menu: 12
Script prints the one-line checklist (clone → branch → commit → push → PR → rebase → merge → cleanup).

Quit

Menu: q → exits.


Note: If you get stuck during a rebase: git rebase --abort returns you to the pre-rebase state.


NOTE_BLOCK
echo ""	

# compact graph of recent commits
git_log_graph() {
  git log --graph --decorate --oneline --all --abbrev-commit "$@"
}

# pretty graph with author and relative time
git_log_pretty() {
  git log --graph --decorate --pretty=format:'%C(yellow)%h%C(reset) %C(green)%cr%C(reset) %C(bold)%an%C(reset) %C(red)%d%C(reset)%n  %s%n' "$@"
}

# history for a single file (follows renames)
git_log_file() {
  if [ -z "$1" ]; then
    echo "Usage: git_log_file <path>"
    return 1
  fi
  git log --follow --pretty=format:'%h %cr %an %s' -- "$1"
}

# commits by author in last N days (default 30)
git_log_author_since() {
  local author="$1"; shift
  local days="${1:-30}"; shift
  git log --author="$author" --since="${days}.days" --pretty=format:'%h %cr %an %s' "$@"
}

# show diffs for commits that touch a particular string (-S)
git_log_search_content() {
  local pattern="$1"
  if [ -z "$pattern" ]; then
    echo "Usage: git_log_search_content <string>"
    return 1
  fi
  git log -p -S"$pattern" --pretty=format:'commit %H%n%an <%ae> %cd%n%n%s%n' "$@"
}

# summary: commits with file change counts (--stat)
git_log_stats() {
  git log --pretty=format:'%C(yellow)%h%C(reset) %C(green)%cr%C(reset) %C(bold)%an%C(reset) %C(red)%d%C(reset)%n  %s%n' --stat "$@"
}


# Function: git_activity
# Description: Generate a compact git activity report for the last 30 days
# Usage: git_activity [output_file] [extra_git_args...]
# Example: git_activity my_report.txt --author="mikail-eliyah-00"
# git log --pretty=format:"%h %an <%ae>"
git_activity() {
  local OUT="${1:-git-activity.txt}"   # Output file (default)
  shift || true                        # Remove output file argument if provided

  echo "Generating git activity to $OUT ..."
  git log --graph --decorate \
    --pretty=format:'%h %cr %an %s' \
    --since="30 days ago" \
    --stat "$@" > "$OUT"

  if [ $? -eq 0 ]; then
    echo "✅ Done. File saved to: $OUT"
  else
    echo "❌ Failed to generate report." >&2
  fi
}

git_activity_display() {
  local AUTHOR_NAME=$(git config user.name)
  local OUT="${1:-git-activity.txt}"
  shift || true

  echo "Generating git activity for author: $AUTHOR_NAME"
  git log --author="$AUTHOR_NAME" \
    --graph --decorate \
    --pretty=format:'%h %cr %an %s' \
    --since="30 days ago" \
    --stat "$@" > "$OUT"
  echo "✅ Saved to $OUT"
}


# Function: git_authors
# Description: Show all unique authors in current repository
# Usage: git_authors [branch|range]
# Example: git_authors main..feature
git_authors() {
  local RANGE="${1:-HEAD}"
  echo "Listing authors for ${RANGE}:"
  git shortlog -sne "$RANGE"
}


