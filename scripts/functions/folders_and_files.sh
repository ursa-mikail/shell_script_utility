level_at_here='./'
level_1_above='../'
level_2_above='../../'
level_3_above='../../../'
level_4_above='../../../../'
level_5_above='../../../../../'

#$ target_folder='dev'
#$folder_name=$(pwd)/$level_2_above$target_folder
#$ check_if_folder_exists


# Function to make a folder with a timestamped snake_case name
function make_folder_timestamped_snakecase() {
    base_name="$1"
    if [ -z "$base_name" ]; then
        #echo "Usage: make_folder_timestamped_snakecase <base_folder_name>"
        #return 1
        base_name=''
        echo 'base_name not used.'
    fi

    time_stamp=$(date +"%Y_%m_%d_%H%Mhr_%Ssec")
    echo "$time_stamp"
    folder_name="${base_name}${time_stamp}"

    mkdir -p "$folder_name"
    echo "Created folder: $folder_name"
}

# Sample usage: % find_lines_containing_str_starting_from_path 'scripts/' 'find_lines'
function find_lines_containing_str_starting_from_path() {
    starting_path="$1"
    str_target="$2"

    # Use find to search for files recursively and grep to find the lines containing the target string
    find "$starting_path" -type f -exec grep -Hn "$str_target" {} \; | while IFS=: read -r file line_num line; do
        echo "=================================================================="
        echo "File: $file"
        echo "Line: $line_num"
        echo "$line"
        echo ""
    done

    # Count the total number of lines found
    number_of_lines_found=$(find "$starting_path" -type f -exec grep -Hn "$str_target" {} \; | wc -l)

    echo "number_of_lines_found: $number_of_lines_found"
}

# find_filename_given_keyword 'merkle'
function find_filename_given_keyword() {
    local keyword=$1
    local path=${2:-"."}  # If no path is given, default to current directory

    find "$path" -type f -name "*$keyword*" -exec ls -l {} +
}

function find_file_from_leaf() {
	number_of_inputs=1
	if [ $# -lt $number_of_inputs ]
	then
		clr;
        		echo "Usage : $0 find_file_from_root $1: (file) "
		return;
	fi

	filename=$1
	
	check_if_file_exists; # at level_at_here
	
	# echo $status
	if [ $status == "true" ]; then
		echo 'at ' $PWD
		return;
	fi;	
	
	cd $level_1_above
	echo 'searching ' $PWD
	echo ' '
	
	check_if_file_exists; # at level_1_above	
	
	if [ $status == "true" ]; then
		echo 'at ' $PWD
		return;
	fi;		
	
	cd $level_1_above
	echo 'searching ' $PWD
	echo ' '
	
	check_if_file_exists; # at level_2_above	
	
	if [ $status == "true" ]; then
		echo 'at ' $PWD
		return;
	fi;		
	
	cd $level_1_above
	echo 'searching ' $PWD
	echo ' '
	
	check_if_file_exists; # at level_3_above	
	
	if [ $status == "true" ]; then
		echo 'at ' $PWD
		return;
	fi;			
	
	cd ~
		
	echo 'Not found.'
}
 
function check_if_folder_exists() {
	if [ -d $folder_name ]; then 
		echo " "$folder_name" exists"; 
		status="true"
	else 
		echo " "$folder_name" does NOT exists";
		status="false"
		#exit;
	fi;
	return
}
 
#$ folder_name=$(pwd)/$level_1_above$target_foler
# 
#$ cd $folder_name
#-bash: cd: /home/user_x/../dev: No such file or directory
#$ check_if_folder_exists
# /home/user_x/../dev does NOT exists

function check_if_file_exists_halt_and_exit_otherwise() {
	if [ -f $filename ]; then 
		echo " "$filename" exists"; 
		status="true"
	else 
		echo " "$filename" does NOT exists";
		status="false"
		#exit;
	fi;
}

function check_if_file_exists() {
	if [ ! -z "$1" ]; then
		filename="$1"
	fi	
	
	if [ -f "$filename" ]; then 
		echo " "$filename" exists"; 
		file_status="true"
	else 
		echo " "$filename" does NOT exist";
		file_status="false"
		#exit;
	fi;
	return
}

function create_folder_if_not_exist() {
    folder_name="$1"
    folder_description="$2"
    
    if [ -d "$folder_name" ]; then 
        echo "Folder '$folder_name' exists"; 
    else 
        echo "Creating $folder_description: '$folder_name'"
        mkdir -p "$folder_name"
        if [ $? -ne 0 ]; then
            echo "Failed to create '$folder_name'"
            return 1
        fi
    fi
}

function create_file_if_not_exist() {
	file=$file_name
	
	if [ -f $file ]; then 
		echo " "$file" exists"; 
	else 
		echo "Create : "$file_name
		touch $file
	fi;
}

function create_folders() {
	folder=$key_store_path
	create_folder_if_not_exist;
	
	folder=$key_store_path
	create_folder_if_not_exist;
	folder=$csr_path
	create_folder_if_not_exist;
	folder=$cnf_path
	create_folder_if_not_exist;
	folder=$certs_path
	create_folder_if_not_exist;
	folder=$message_store_path
	create_folder_if_not_exist;
	
}

function go_to_another_server(){
	echo "Press 1 : RCA"
  	echo "Press 2 : ICA"
  	echo "Press 3 : service_server"

  	number_of_digits_for_inputs=2
	# read  -n 1 -p "Input Selection:" main_menu_input
	read  -n $number_of_digits_for_inputs -p "Input Selection:" _input
	echo ""
	
	if [ "$_input" = "1" ]; then
    	echo 'switching to RCA'
		cd '../0. RCA/'
		pwd
		exec bash
    elif [ "$_input" = "2" ]; then
    	echo 'switching to ICA'
		cd '../1. ICA/'
		pwd
		exec bash
    elif [ "$_input" = "3" ]; then
    	echo 'switching to service_server ...'
		cd ../'2. service_server'/
		pwd
		exec bash
    elif [ "$_input" = "x" -o "$_input" = "X" ];then # -o := `or` and `||`
		exit_program;
    else
		default_action;
    fi

}

function create_and_goto_folder() {
    folder_name="$1"
    folder_description="$2"
    create_folder_if_not_exist "$folder_name" "$folder_description"
    
    if [ $? -eq 0 ]; then
        cd "$folder_name" || { echo "Failed to navigate to '$folder_name'"; return 1; }
    else
        echo "Failed to create or navigate to '$folder_name'"
        return 1
    fi
}

function create_and_open_file(){
	file_name=$1
	create_file_if_not_exist;
	
	subl $file_name
} 

function zip_folder(){
	if [ "$1" == "" ] # not specified 
	then	# use current_folder as name
		current_folder_name=${PWD##*/};
	else
		current_folder_name=$1;	
	fi;
	
	echo $current_folder_name;
	time_stamp=$(date +"%Y-%m-%d_%H%Mhr_%S"sec) ; 
	zip -r "$current_folder_name"_$time_stamp.zip .; 
}

# Example usage: zip_file ./sample_data/california_housing_test.csv
function zip_file() {
    if [ -z "$1" ]; then  # Check if the argument is empty
        echo "Usage: zip_file \$file_name"
        return
    else
        file_name="$1"  # Assign the first argument to file_name
    fi

    # Getting the current folder name
    current_folder_name=$(basename "$(pwd)")
    
    # Creating a timestamp
    time_stamp=$(date +"%Y-%m-%d_%H%Mhr_%Ssec")
    
    # Zipping the file with a timestamp
    zip "${file_name}_$time_stamp.zip" "$file_name"
}

time_stamp=''

function estimate_file_compression(){
	zip_file $file_name
	size_in_bytes_compressed=$(du -sb "$file_name"_$time_stamp.zip |  cut -f1)
	size_in_bytes_uncompressed=$(du -sb $file_name |  cut -f1)
	
	echo "size_in_bytes_uncompressed: " $size_in_bytes_uncompressed " bytes"
	echo "size_in_bytes_compressed: " $size_in_bytes_compressed " bytes"
	
}

function check_folder_size() {
    folder_path=$1

    if [ -z "$folder_path" ]; then
        echo "Please provide a folder path."
        return 1
    fi

    if [ ! -d "$folder_path" ]; then
        echo "The specified path '$folder_path' is not a directory."
        return 1
    fi

    echo "Overall size of '$folder_path':"
    du -sh "$folder_path"
    echo "========================================================="
    echo "Including sizes of subdirectories:"
    du -h "$folder_path"/*
}



