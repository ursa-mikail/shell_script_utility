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
    echo "Explain what will happen before proceeding a full flush and refresh:"
    echo "         This is a destructive action and cannot be undone."    
    echo "Are you sure you want to proceed? (yes/no): " 
    read -r confirmation

    # Check user confirmation
    if [ "$confirmation" != "yes" ]; then
        echo "Aborting operation."
        exit 1
    fi

    # Step 1: Create a new orphan branch
    git checkout --orphan new-branch
    if [ $? -ne 0 ]; then
        echo "Failed to create orphan branch. Aborting."
        exit 1
    fi

    # Step 2: Remove all files from the staging area and working directory
    git rm -rf .
    if [ $? -ne 0 ]; then
        echo "Failed to remove files. Aborting."
        exit 1
    fi

    # Step 3: Add your files back and commit
    git add .
    git commit -m "Initial commit"
    if [ $? -ne 0 ]; then
        echo "Failed to commit changes. Aborting."
        exit 1
    fi

    # Step 4: Delete the old branch and rename the new branch
    git branch -D main  # Replace 'main' with the name of your old branch
    git branch -m main  # Rename the new branch to 'main'
    if [ $? -ne 0 ]; then
        echo "Failed to rename branch. Aborting."
        exit 1
    fi

    # Step 5: Force push to the remote repository
    git push -f origin main  # Replace 'main' with the name of your branch
    if [ $? -ne 0 ]; then
        echo "Failed to push changes to remote repository. Aborting."
        exit 1
    fi

    echo "Git logs cleared and new history pushed to remote repository successfully."
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
