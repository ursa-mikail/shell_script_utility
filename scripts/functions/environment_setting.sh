
function memory_available(){
	vm_stat | awk 'NR==2{print "Free Memory: " $3 * 4096 / 1024 / 1024 " MB"}'
}

function introspect_function(){
	if [ ! -z "$1" ]; then
		if [ "$1" == '--introspect' ]; then
			echo 'Usage: ' $introspect_statement
			echo $demarcator
			return
		fi			
	fi		
}

function query_system_profile () {
	uname -a
	whoami
	echo ""
	# check path
	echo "$PATH" # printf "%s\n" "$PATH"
	
	# add line to .bashrc : set path = ($path ~/.../bin)

	# ENVIRONMENT variables are set using setenv, and unset using unsetenv. 
	printenv | less
	# current values of these variables. # SHELL variables are both set and displayed using set . They can be unset by using the unset command.
	set | less
	
}

function live_test_Kharon_support_kit (){
	echo "Kharon_support_kit is live at: "
	get_timestamp;
}

function open_notepad (){
	file_name="$1"

	if [ -z "$1" ]; then
		# eval notepad
		open -a 'Sublime Text' $HOME/scripts/data/data.txt # for Mac
	else
		# eval notepad "$file_name"
		open -a 'Sublime Text' "$file_name"
	fi		
}

function open_notepad_plus (){
	file_name="$1"
	
	if [ -z "$1" ]; then
		eval "/cygdrive/c/Program Files (x86)/Notepad++/notepad++.exe"
	else
		eval "/cygdrive/c/Program Files (x86)/Notepad++/notepad++.exe" "$file_name"
	fi
}


# set path ## please note 'PATH' is CASE sensitivity and must be in UPPERCASE ##
#export PATH=$PATH:/path/to/dir1
#export PATH=$PATH:/path/to/dir1:/path/to/dir2
#export PATH=$PATH:/usr/local/bin
#OR
#PATH=$PATH:/usr/local/bin; export PATH

## please note 'PATH' is CASE sensitivity and must be in UPPERCASE ##
#PATH=$PATH:/path/to/dir1; export PATH

#To make changes permanent, add commands described above to the end of ~/.profile file for sh and ksh shell, or ~/.bash_profile file for bash shell:
## BASH SHELL ##
#echo 'export PATH=$PATH:/usr/local/bin'  >> ~/.bash_profile

