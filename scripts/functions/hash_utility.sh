# source $HOME"/scripts/parameters.sh" 
# function pack_n_sha { get_timestamp ; tar -cvzf "$1"_$time_stamp.tar .; sha256_result=$(openssl dgst -$hash_algo "$1"_$time_stamp.tar); echo $sha256_result; }

function hash_message(){
    message_input=$1
    
    if [ -z "$message_input" ]; then
        echo "Please provide a message to hash."
        return 1
    fi
    
    hash_algo=${hash_algo:-sha256} # Default to sha256 if not set

    ANS=$(echo -n "$message_input" | openssl dgst -$hash_algo | awk '{print $2}')
    echo $ANS
}

function hash_file_with_prompt(){
	read -p '[file_to_hash]: ' file_to_hash
	filename=$message_store_path$file_to_hash
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		label="[ "$file_to_hash" does not exist. ]";
		print_label;	
	else
		label="[ "$file_to_hash" exists. ]";
		print_label;
	fi
	
	ANS=$(openssl dgst -$hash_algo $filename | awk '{print $2}')
}


function hash_file() {
    local filename="$1"
    local file_to_hash="$1"
    
    # Check if the file exists
    check_if_file_exists "$file_to_hash"
    
    #if [ "$file_status" == "false" ]; then 
    #    label="[ $file_to_hash does not exist. ]"
    #    echo $label
    #    return 1
    #else
    #    label="[ $file_to_hash exists. ]"
    #    echo $label
    #fi
    
    # Check if the file exists
    if [ -e "$filename" ]; then
        echo "[ $filename exists. ]"
    else
        echo "[ $filename does NOT exist. ]"
        return 1
    fi

    # Ensure hash_algo is set
    if [ -z "$hash_algo" ]; then
        #echo "hash_algo is not set. Please set the hash algorithm (e.g., sha256, md5)."
        #return 1
        hash_algo="sha256"
        echo $hash_algo
    fi
    
    # Hash the file
    local ans=$(openssl dgst -"$hash_algo" "$filename" | awk '{print $2}')
    echo $ans
}


alias pack_and_sha_folder=pack_and_sha

# pack_and_sha script_utility
function pack_and_sha {
    hash_algo=${hash_algo:-sha256} # Default to sha256 if not set

    if [ -z "$1" ]; then
        echo "Usage: pack_and_sha <folder_path>"
        return 1
    fi

    folder_path="$1"

    if [ ! -d "$folder_path" ]; then
        echo "Error: '$folder_path' is not a valid directory."
        return 1
    fi

    # Remove trailing slash if any
    folder_path="${folder_path%/}"
    folder_name=$(basename "$folder_path")

    echo "$folder_name"
    time_stamp=$(date +"%Y-%m-%d_%H%Mhr_%Ssec")

    output_zip_file="${folder_name}_$time_stamp.zip"
    zip -r "$output_zip_file" "$folder_path"

    sha256_result=$(openssl dgst -$hash_algo "$output_zip_file")
    echo "$sha256_result"

    echo "$output_zip_file"
}


function pack_and_sha_self {
    # Change directory to "$HOME/scripts/functions"
    cd "$HOME/scripts/functions" || { echo "Failed to change directory"; return 1; }

    # Call pack_and_sha and capture its output
    output_zip_file=$(pack_and_sha "shell_script_utility")

    # Check if the pack_and_sha command succeeded
    if [ $? -eq 0 ] && [ -n "$output_zip_file" ]; then
        # Prepend "shell_scripts_" to the output zip file name
        #output_zip_file="shell_scripts_$original_output_zip_file"
        #mv "$original_output_zip_file" "$output_zip_file"
        echo "$output_zip_file created @ $HOME/scripts/functions"
        open "$HOME/scripts/functions"
    else
        echo "Failed to create zip file"
        cd - || { echo "Failed to return to directory"; return 1; }
        return 1
    fi 

    # Return to the previous directory
    cd - || { echo "Failed to return to directory"; return 1; }
}


# function pack_and_sha { get_timestamp ; tar -cvzf "$1"_$time_stamp.tar .; sha256_result=$(openssl dgst -sha256 "$1"_$time_stamp.tar); echo $sha256_result; }
echo ""
: <<'COMMENT_UnUsed'

function pack_and_sha { 
	if [ "$1" = "" ]; # not specified 
	then	# use current_folder as name
		current_folder_name=${PWD##*/};
	else
		current_folder_name=$1;	
	fi;
	 
	echo"....."

	echo $current_folder_name;
	time_stamp=$(date +"%Y-%m-%d_%H%Mhr_%S"sec) ; 
	output_zip_file="$current_folder_name"_$time_stamp.zip
	zip -r "$output_zip_file" .

    # Check if the zip command succeeded
    if [ $? -ne 0 ]; then
        echo "Failed to create zip file"
        return 1
    fi
    	
	# tar -cvzf $(current_folder_name)_$time_stamp.tar .; 
	sha256_result=$(openssl dgst -sha256 "$current_folder_name"_$time_stamp.zip); 
	echo $sha256_result; 

	return "$output_zip_file"
}


COMMENT_UnUsed
echo 

# Example usage:
#hash_algo="sha256"  # Set the hash algorithm
#hash_file "$file_to_hash"
function pack_and_hash_file(){
	read -p '[foldier_to_pack_and_hash, e.g. current folder: '.' or "./messages/"]: ' foldier_to_pack_and_hash
	
	if [ "$foldier_to_pack_and_hash" == "" ] || [ "$foldier_to_pack_and_hash" == "." ] # not specified 
	then	# use current_folder as name
		foldier_to_pack_and_hash='.';
		zip_file_name=${PWD##*/};
	else
		# zip_file_name='';
		read -p '[zip_file_name]: ' zip_file_name
	fi;
	
	time_stamp=$(date +"%Y-%m-%d_%H%Mhr_%S"sec) ;
	output_file="$message_store_path$zip_file_name"_$time_stamp.zip
	zip -r $output_file $foldier_to_pack_and_hash; 
	
	filename=$output_file
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		label="[ "$output_file" does not exist. ]";
		print_label;	
	else
		label="[ "$output_file" exists. ]";
		print_label;
	fi
	
	ANS=$(openssl dgst -$hash_algo $output_file | awk '{print $2}');
}

function get_file_sha { sha256_result=$(openssl dgst -$hash_algo "$1"); echo $sha256_result; }

function display_hashes_of_all_files_under_folder(){
	number_of_inputs=0
	if [ $# -eq $number_of_inputs ]
	then
		read -r -p "path_to_folder_to_sha [e.g. c:/path_to_folder_to_sha/] : "  path_to_folder_to_sha
		find $path_to_folder_to_sha -type f -exec openssl dgst -$hash_algo {} \;
	else
		# hash all files in folder and sub-directories
		find . -type f -exec openssl dgst -$hash_algo {} \; # cd /path/to/working/directory sha256sum <(find . type f -exec sha256sum \; | sort).		
	fi
}

function compute_hash_of_paragraphs () {
	echo "Enter contents into notepad (this will be removed after compute):" 

	tmp_file_for_hash=./scripts/data/tmp.txt
	touch $tmp_file_for_hash
	notepad $tmp_file_for_hash
	
	echo "Displaying profiles: "
	echo "---------------------"
	
	cat $tmp_file_for_hash
	echo ""
	echo "---------------------"
	openssl dgst -sha256 $tmp_file_for_hash

	rm -rf $tmp_file_for_hash
}

function compare_hashes_of_2_files() {
    # Ask for the locations of the two files
    echo "Enter the path for the first file (use ~ for home directory):"
    read file_00
    echo "Enter the path for the second file (use ~ for home directory):"
    read file_01

    # Expand ~ to the full home directory path
    file_00="${file_00/#\~/$HOME}"
    file_01="${file_01/#\~/$HOME}"

    # Check if both files exist
    if [[ ! -f $file_00 ]]; then
        echo "File not found: $file_00"
        return 1
    fi

    if [[ ! -f $file_01 ]]; then
        echo "File not found: $file_01"
        return 1
    fi

    # Create temporary files for the hashes
    tmp_file_for_hash_00=$(mktemp)
    tmp_file_for_hash_01=$(mktemp)

    # Calculate the hashes of the two files and store them in the temporary files
    hash_file "$file_00" > "$tmp_file_for_hash_00"
    hash_file "$file_01" > "$tmp_file_for_hash_01"

    # Show the hashes
    echo "Hash of $file_00: $(cat "$tmp_file_for_hash_00")"
    echo "Hash of $file_01: $(cat "$tmp_file_for_hash_01")"

    # Compare the hashes and show the diff
    if diff_output=$(diff $tmp_file_for_hash_00 $tmp_file_for_hash_01 --color=always); then
        echo "No differences (hashes are identical)."
    else
        echo "Differences in hashes:"
        echo "$diff_output"
    fi

    # Clean up temporary files
    rm -f "$tmp_file_for_hash_00" "$tmp_file_for_hash_01"
}


function compare_contents () {
	tmp_file_for_contents_00=./scripts/data/tmp_file_for_contents_00.txt
	tmp_file_for_contents_01=./scripts/data/tmp_file_for_contents_01.txt
	touch $tmp_file_for_contents_00
	touch $tmp_file_for_contents_01
	
	echo "[Enter contents into notepad (this will be removed after compute)]" 
	echo "Enter contents for content 00:" 
	notepad $tmp_file_for_contents_00
	echo "Enter contents for content 01:" 
	notepad $tmp_file_for_contents_01
	
	diff $tmp_file_for_contents_00 $tmp_file_for_contents_01 --color=always
	
	echo ""
	rm -rf $tmp_file_for_contents_00 $tmp_file_for_contents_01
}

function get_file_sha { 
	sha256_result=$(openssl dgst -sha256 "$1"); echo $sha256_result; 
}

# caveat: not standard hashing
function rehash_n_rounds { 
	# e.g. 
	# message="hello"
	# number_of_rounds=10
	# usage: rehash_n_rounds $message $number_of_rounds
	message="$1"
	number_of_rounds="$2"
	START=1
	END=$number_of_rounds
	hash_result=''
	
	for (( i=$START; i<=$END; i++ ))
		do
			# echo $i
			hash_result=$(echo -n "$message" | openssl dgst -sha256); 
			message="$hash_result";
		done 
		
	echo $hash_result
}
