function get_script_utility_version {
    file_path="$HOME/scripts/functions/version.txt"

    if [ ! -f "$file_path" ]; then
        echo "File not found: $file_path"
        return 1
    fi

    # Get the first line of the file
    first_line=$(head -n 1 "$file_path")
    echo "$first_line"

    # Extract the timestamp from the first line using a simpler approach
    timestamp=$(echo "$first_line" | awk -F'Updated: ' '{print $2}' | xargs)

    if [ -n "$timestamp" ]; then
        echo "Version by timestamp: $timestamp"
    else
        echo "No timestamp found in the first line"
        return 1
    fi
}

# Sample usage: % list_functions_in_shell_script 'scripts/functions/shell_setting.sh' 
function list_functions_in_shell_script {
    if [ -z "$1" ]; then
        echo "File path required"
        echo "Usage: list_functions_in_sh <file_path>"
        return 1
    fi

    file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "File not found: $file_path"
        return 1
    fi

    echo "Functions in $file_path:"
    grep -E '^\s*function\s+\w+\s*\(|^\s*\w+\s*\(\s*\)\s*\{' "$file_path"
}

# Sample usage: list_functions_in_shell_scripts_given_folder 'scripts/functions'
# Sample usage: list_functions_in_shell_scripts_given_folder 'scripts/functions'
function list_functions_in_shell_scripts_given_folder () {
    if [ -z "$1" ]; then
        echo "Folder path required"
        echo "Usage: list_functions_in_shell_scripts_given_folder <folder_path>"
        return 1
    fi

    folder_path="$1"

    if [ ! -d "$folder_path" ]; then
        echo "Folder not found: $folder_path"
        return 1
    fi

    # Find all .sh files and store them in a temporary file
    temp_file=$(mktemp)
    find "$folder_path" -type f -name "*.sh" -print0 > "$temp_file"

    # Read from the temporary file
    index=1
    while IFS= read -r -d '' file; do
        echo "=================================================================="
        echo "File #$index: $file"
        list_functions_in_shell_script "$file"
        ((index++))
    done < "$temp_file"

    # Clean up the temporary file
    rm -f "$temp_file"
}

# Dummy example of list_functions_in_shell_script function
function list_functions_in_shell_script () {
    grep -E '^\s*function\s+\w+\s*\(' "$1"
}


# Sample usage: list_shell_scripts_given_folder 'scripts/functions'
function list_shell_scripts_given_folder {
    if [ -z "$1" ]; then
        echo "Folder path required"
        echo "Usage: list_shell_scripts_given_folder <folder_path>"
        return 1
    fi

    folder_path="$1"

    if [ ! -d "$folder_path" ]; then
        echo "Folder not found: $folder_path"
        return 1
    fi

    # Find all .sh files and store them in a temporary file
    temp_file=$(mktemp)
    find "$folder_path" -type f -name "*.sh" -print0 > "$temp_file"

    # Read the list of .sh files from the temporary file into an array
    sh_files=()
    while IFS= read -r -d '' file; do
        sh_files+=("$file")
    done < "$temp_file"

    # Clean up the temporary file
    rm -f "$temp_file"

    if [ ${#sh_files[@]} -eq 0 ]; then
        echo "No .sh files found in $folder_path"
        return 1
    fi

    echo 'Shell script files in folder:'
    echo '----------------------------------------------------------------------'

    # Iterate over the array and list each file
    index=1
    for file in "${sh_files[@]}"; do
        echo "File #$index: $file"
        ((index++))
    done

    ((index--))
    echo ''
    echo "Total shell script files: $index"
    echo ''
}

# Reload the shell configuration
#source ~/.bashrc  # or source ~/.zshrc

echo ""
: <<'COMMENT_'

% list_zsh_functions_enumerated
% where_is_function compute_hash_of_paragraphs
==================================================================
File: /scripts/functions//hash_utility.sh
Line: 209
function compute_hash_of_paragraphs () {

number_of_lines_found:        1

COMMENT_
echo ""

# $ list_zsh_functions | delete_lines_from_to 75 80 | cat -n # --number
# Function to list all functions in Zsh, clean output
function list_zsh_functions() {
    echo "======================"
    echo "List of Zsh functions"
    echo "======================"

    # List all functions with typeset
    typeset -f | awk 'NF {print $3}'  # Print only function names
}

function list_zsh_functions_enumerated() {
	echo ""
	echo "======================"
	echo "List of bash functions"
    echo "======================"
	list_zsh_functions | grep -v gawk | cat -n
}

function search_function () {
	keyword="$1"
	list_zsh_functions | seek_further $keyword
}

# Usage: where_is_function find_bash
function where_is_function(){
	keyword="$1"
	path_start=$HOME'/scripts/functions/'
	find_lines_containing_str_starting_from_path $path_start $keyword 
}


#^ (circumflex or caret) inside square brackets negates expression : eg, [^Ff] means anything except upper or lower case F and [^a-z] means everything except lower case a-z.

#$ list_zsh_functions | grep '[*’$substring’]' --color # contains
#$ list_zsh_functions | grep 'in[‘$list_of_characters’]' --color # contains characters such as ...
#$ list_zsh_functions | grep '^'$substring’’ --color # starts with 
#$ list_zsh_functions | grep $substring'$' --color # ends with
#$ list_zsh_functions | grep $substring --color # matches

# Sample usage: seek 'bash_func' 'scripts'
# Sample usage: seek "index" ./scripts/functions | seek_further '\+'
function seek { 
    if [ -z "$1" ]; then
        echo 'Search keyword required'
        echo "Usage: seek <keyword> [path_start]"
    else
        keyword="$1"
        path_start="${2:-.}" # Default to the current directory if no path is provided
        
        echo "Keyword: $keyword"
        echo "Path: $path_start"
        
        # Use egrep to search for the keyword recursively in the specified path with colored output
        GREP_COLORS='ms=01;32' egrep -inr --color=always "$keyword" "$path_start" 2>/dev/null

        time_stamp=$(date +"%Y-%m-%d_%H%Mhr_%S"sec)
        echo "Timestamp: $time_stamp"
    fi
}


# seek 'bash_func' 'scripts' | seek_further 'tion'
# $ seek $key_word_00 | seek_further $key_word_01 | seek_further $key_word_02 ...
function seek_further() { 
    if [ -z "$1" ]; then
        echo 'Search keyword required'
        echo "Usage: seek_further <keyword>"
    else
        GREP_COLORS='ms=01;36' egrep -i --color=always "$1"
    fi

    time_stamp=$(date +"%Y-%m-%d_%H%Mhr_%S"sec)
    echo "Timestamp: $time_stamp"
}

# Example usage:
# seek_and_seek_further "./scripts/functions" "seek" "function" "bash"
# seek_and_seek_further "./scripts/functions" "seek" "function" "bash" "key" "list"
function seek_and_seek_further() {
    if [ "$#" -lt 2 ]; then
        echo 'Starting path and initial search keyword required'
        echo "Usage: seek_and_seek_further <starting_path> <initial_keyword> <keyword1> <keyword2> ... <keywordN>"
        return 1
    fi

    starting_path="$1"
    initial_keyword="$2"
    shift 2

    further_keywords=("$@")

    # Perform the initial seek
    results=$(seek "$initial_keyword" "$starting_path" | tee /dev/tty)
    
    index=1
    # Perform further seeks based on the remaining keywords
    for keyword in "${further_keywords[@]}"; do
        results=$(echo "$results" | seek_further "$keyword" | tee /dev/tty)
        ((index++))
    done

    echo ""
    echo "Number of keywords searched: "$index

    echo "============================================================"
    echo "Final results:"
    echo "$results"
    echo "============================================================"
}

function kill_process() {
  # List running processes
  ps aux

  # Prompt for the PID to kill
  echo -n "Enter the PID to kill: "
  read pid

  # Check if PID is valid
  if ! [[ $pid =~ ^[0-9]+$ ]]; then
    echo "Invalid PID: $pid"
    return 1
  fi

  # Get the command of the process
  cmd=$(ps -p $pid -o comm=)

  # Check if the process exists
  if [ -z "$cmd" ]; then
    echo "No process found with PID $pid"
    return 1
  fi

  # Kill the process
  kill $pid

  # Check if the kill command was successful
  if [ $? -eq 0 ]; then
    echo "Process $pid ($cmd) killed successfully."
  else
    echo "Failed to kill process $pid."
  fi
}

# Function to find or list shell functions based on a keyword
function find_shell_function_in_list(){
    echo "Input keyword (e.g., update*):"
    read -r keyword

    echo "Found (if not empty or NIL):"

    # Check if the keyword is not empty
    if [ -n "$keyword" ]; then
        echo '=========== [start] ==========='
        search_function "$keyword"
        echo '============ [end] ============'
    else
        echo '=========== [start] ==========='
        list_zsh_functions
        echo '============ [end] ============'
    fi
}


function locate_zsh_function_in_list(){
	keyword="$1"
	if [ ! -z $keyword ] # not empthy 
		then : # 
			echo '=========== [start] ==========='
			list_zsh_functions | seek_further "$keyword"
			echo ""
			read   -p "select function from candidate list above:" keyword			
			echo ""
			echo "The function is located at: "
			GREP_COLORS='ms=01;36' grep -ir --color=always $keyword $HOME'/scripts/' | seek_further 'function'
			echo '============ [end] ============'	
		else : # $1 was not given 
			echo '=========== [start] ==========='
			list_zsh_functions 
			echo '============ [end] ============'		
	fi
 
}

#
#		read -r -p "keyword for list_zsh_functions [e.g. read] (enter nothing to list ALL) : "  word_to_search
#		# echo $word_to_search
#		
#		if [ "$word_to_search" = '' ]
#		then
#			compgen -A function # list_zsh_functions
#		else
#			compgen -A function | grep $word_to_search
#		fi

function clr(){
	# echo -en '\033c';
	#clear && printf '\e[3J'
	clear
}

function set_terminal_title() {
      export PS1="\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n$ "
      echo -ne "\e]0;$1\a"
}

echo ""
: <<'COMMENT_SET_TERMINAL_TITLE_FOR_MAC'



function set_terminal_title() {
     #export PS1="\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n$ "
     # echo -ne "\e]0;$1\a"
	 echo "\033]0;$1\007"
}
COMMENT_SET_TERMINAL_TITLE_FOR_MAC
echo ""

function open_new_window() {
	#open -a Terminal "$(which zsh)";
    open -a Terminal "$(pwd)";
}

function get_env_vars () {
	echo "OSTYPE: " + $OSTYPE ;
	echo "USER: " + $USER ; # login name
	echo "HOME: " + $HOME ; # path name of home dir
	echo "HOST: " + $HOST ; # name of computer 
	echo "Architecture: " + $ARCH ; # architecture of computers processor
	echo "Display: " + $DISPLAY ; # name of computer screen to display X windows
	echo "PRINTER: " + $PRINTER ; # default printer to send print jobs
	echo "PATH: " + $PATH ; # directories shell should search to find a command
	echo "Current dir : " + $CWD ;
	echo "prompt : " + $prompt ; # text string used to prompt for interactive commands shell login shell)
	echo "SHELL: " + $SHELL ;
	echo "Terminal: " + $TERM ;
	echo "displayed more details : use printenv, env or set" # putting commands in `` will execute the commands
}

function replay_command() {
	history
	echo ""
	echo ""
	read   -p "cmd_choice (e.g. index number*):" cmd_choice
	eval "!$cmd_choice"
}

function open_dir () {
	eval "open ."
}

function open_dir_given_path () {
	destination_path="$1" # "C:\Ursa\...\Gaia"
	# eval ". $(HOME)/.bashrc"
	# eval ". ~/.bashrc"
	cd ${destination_path}
	eval "open ."
}

#$ gnome-open .
#or
#$ nautilus .

# cygwin 
#alias nwin=”cygstart /bin/bash -li” # “mintty.exe -i /Cygwin-Terminal.ico - &”

# ubuntu
#alias nwin=”gnome-terminal”

function get_bash_version () {
	#N=10
		
	#for VARIABLE in 1 2 3 4 5 .. N
	#do
	#	printf "\n"
	#done
	echo "Bash version ${BASH_VERSION}..."
	echo "Home path: $HOME"
}

function count_parameters(){
	printf "Hello, $USER.\n\n"
	printf "There are "$#" arguments.\n"
	#input_length=20
	#read  -n $input_length -p "Input arguments:" arguments 
	echo ""
	demarcator="===================================================="
	# handle > 10 parameters in shell
	# can have up to ${255}
	# Use curly braces to set them off:
	# echo "${10}"
	printf "\n $demarcator \n"	
	# iterate over the positional parameters
	# for arg
	printf "\n $demarcator \n"			
	# for arg in "$@"
	printf "\n $demarcator \n"			
	#or
	while (( $# > 0 )) # or [ $# -gt 0 ] 
	do 
		echo "$1" 
		shift 
	done
	printf "\n $demarcator \n"	
}

function show_latest_command_and_argument_history () {
	echo "[show_latest_command_and_argument_history]"
	echo "latest command: " 
	echo "type '!!'"
	echo "latest argument: " 
	echo "type '!$'"
}

function clean_all_openssl_processes () {
	kill -9 $(ps aux | grep -e openssl | awk '{ print $2 }')
	rm -rf ./messages/msg.txt.*
}

function clr_history () {
	# Clear all previous history using option -c
	history -c
	> $HOME/.bash_history  # delete all contents of file
	# echo "" > .bash_history	
	echo "history cleared."
}

function refresh_shell(){
	time_stamp=$(date +"%Y-%m-%d_%H%Mhr_%S"sec) ; 
	
	echo ""
	echo "Refreshing bashrc"
	echo $time_stamp; 
	eval ". "$HOME"/.zshrc"
}

function exit_program_for_menu() {
	printf "\n quit.\n"
	echo 'X' : return # quitprogram: return to command line
}