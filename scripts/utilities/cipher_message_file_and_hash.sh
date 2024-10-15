data_home_path=$HOME'/scripts/utilities/data'
file_name_tmp='log.txt'

BLUE_TEXT='\033[0;36m'
NC='\033[0m' # No Color

# cipher_file "path/to/input_file.txt" "path/to/output_file.enc"
# decipher_file "path/to/output_file.enc" "path/to/decrypted_file.txt"
function cipher_file_and_hash () {
	echo "file_to_be_ciphered_in: "
	read -r file_to_be_ciphered_in

    # Check if the file exists
    if [[ ! -f "$file_to_be_ciphered_in" ]]; then
        echo "File not found: $file_to_be_ciphered_in"
        return
    fi

	hash_of_file=$(get_file_sha "$file_to_be_ciphered_in") 
	echo "hash_of_file: " $hash_of_file
	file_ciphered_out=$file_to_be_ciphered_in".enc"
	cipher_file $file_to_be_ciphered_in $file_ciphered_out
	echo "file_ciphered_out: " $file_ciphered_out
}

function decipher_file_and_hash () {
	echo "file_to_be_deciphered_in: "
	read -r file_to_be_deciphered_in
	file_deciphered_out=$file_to_be_deciphered_in".txt"

    # Check if the file exists
    if [[ ! -f "$file_to_be_deciphered_in" ]]; then
        echo "File not found: $file_to_be_deciphered_in"
        return
    fi

	decipher_file $file_to_be_deciphered_in $file_deciphered_out
	echo "file_ciphered_out: " $file_deciphered_out
	hash_of_file=$(get_file_sha "$file_deciphered_out")
	echo "hash_of_file: " $hash_of_file
}

# Function to cipher a file after zipping it and display its hash
function cipher_file_zipped_and_hash() {
    echo "Enter the file to be ciphered: "
    read -r file_to_be_ciphered_in

    # Check if the file exists
    if [[ ! -f "$file_to_be_ciphered_in" ]]; then
        echo "File not found: $file_to_be_ciphered_in"
        return
    fi

    # ZIP the file before ciphering
    file_zipped_to_be_ciphered_in="${file_to_be_ciphered_in}.zip"
    zip "$file_zipped_to_be_ciphered_in" "$file_to_be_ciphered_in"
    echo "Zipped file output: $file_zipped_to_be_ciphered_in"

    # Get the hash of the zipped file
    hash_of_file=$(get_file_sha "$file_zipped_to_be_ciphered_in")
    echo "Hash of zipped file: $hash_of_file"

    # Cipher the zipped file
    file_ciphered_out="${file_zipped_to_be_ciphered_in}.enc"
    cipher_file "$file_zipped_to_be_ciphered_in" "$file_ciphered_out"
    echo "Ciphered file output: $file_ciphered_out"
}

# Function to decipher a file and verify its hash, then unzip it
function decipher_file_zipped_and_hash() {
    echo "Enter the file to be deciphered (including .enc extension): "
    read -r file_to_be_deciphered_in

    # Check if the encrypted file exists
    if [[ ! -f "$file_to_be_deciphered_in" ]]; then
        echo "File not found: $file_to_be_deciphered_in"
        return
    fi

    # Decipher the file
    file_deciphered_out="${file_to_be_deciphered_in%.enc}"  # Remove the .enc extension
    decipher_file "$file_to_be_deciphered_in" "$file_deciphered_out"
    echo "Deciphered file output: $file_deciphered_out"

    # Verify the hash of the deciphered (zipped) file
    hash_of_deciphered_file=$(get_file_sha "$file_deciphered_out")
    echo "Hash of deciphered file: $hash_of_deciphered_file"

    # Unzip the deciphered file
    unzip_dir="${file_deciphered_out%.zip}"  # Remove the .zip extension to get the original filename
    unzip "$file_deciphered_out" -d "$unzip_dir"
    echo "Unzipped file output directory: $unzip_dir"
}

function cipher_message_file_and_hash () {
	echo "Enter comment / notes (and save, this file will NOT be removed after result output to console) : "
	
	file_renamed_with_path=$(add_timestamp_to_file_name $data_home_path'/'$file_name_tmp)
	echo "Created: " $file_renamed_with_path
	touch $file_renamed_with_path 
	echo $file_renamed_with_path 
	open_notepad 'log.txt'
	
	cp $file_name_tmp $file_renamed_with_path 
	rm -rf $file_name_tmp
	
	hash_result=$(hash_file_give_file_path $file_renamed_with_path) # >> $file_renamed_with_path 
	
	random_select_font;
	# echo ${index_color[$index_color_choice]}
	
	font_display "hash_result: << $hash_result ${NC} >>"
		
	cipher_file  $file_renamed_with_path $file_renamed_with_path'.enc' 
}

function decipher_message_file_and_check_hash () {
	ls $data_home_path
	read -p 'Choose file for deciphering : ' file_ciphered_with_path
	
	file_ciphered_with_path=$data_home_path'/'$file_ciphered_with_path
	
	filename=$file_ciphered_with_path
	check_if_file_exists; # at level_at_here
	
	# echo $status
	if [ $status == "true" ]; then
		file_path=$(get_file_path $file_ciphered_with_path)
		file_name=$(get_file_name $file_ciphered_with_path)
		#file_type=$(get_file_type $file_ciphered_with_path)
		
		file_deciphered_with_path=$file_path'/'"$file_name"_deciphered.txt
		
		decipher_file $file_ciphered_with_path $file_deciphered_with_path 
		
		echo ""
		echo "Deciphered file [" $file_deciphered_with_path "]: "
		cat $file_deciphered_with_path 
		
		echo ""
		hash_result=$(hash_file_give_file_path $file_deciphered_with_path) 

		# echo -e "file hash: ${NC} << ${BLUE_TEXT} $hash_result${NC} >>"
		random_select_font;
		
		font_display "file hash: << $hash_result >>"
		
		return;
	else
		echo $file_ciphered_with_path " does not exist."
	fi;	
	
}

# Function to cipher a folder after zipping it and display its hash
function cipher_folder_zipped_and_hash() {
    echo "Suggested key for ciphering: "
    generate_random_hex 50
    echo "============================================"

    echo "Enter the folder (path) to be ciphered: "
    read -r folder_to_be_ciphered_in

    # Check if the folder exists
    if [[ ! -d "$folder_to_be_ciphered_in" ]]; then
        echo "Folder not found: $folder_to_be_ciphered_in"
        return
    fi
    
    # Check if the input path is '.'
    if [[ "$folder_to_be_ciphered_in" == "." ]]; then
        current_folder_name=$(basename "$PWD")
        echo "Renaming '.' to current folder name: $current_folder_name"
        folder_zipped_to_be_ciphered_in="${current_folder_name}.zip"
    else
        folder_zipped_to_be_ciphered_in="${folder_to_be_ciphered_in}.zip"
    fi    

    # ZIP the folder before ciphering
    zip -r "$folder_zipped_to_be_ciphered_in" "$folder_to_be_ciphered_in"
    echo "Zipped file output: $folder_zipped_to_be_ciphered_in"

    # Get the hash of the zipped file
    hash_of_file=$(get_file_sha "$folder_zipped_to_be_ciphered_in")
    echo "Hash of zipped folder: $hash_of_file"

    # Cipher the zipped file
    file_ciphered_out="${folder_zipped_to_be_ciphered_in}.enc"
    cipher_file "$folder_zipped_to_be_ciphered_in" "$file_ciphered_out"
    echo "Ciphered file output: $file_ciphered_out"
}


# Function to decipher a folder and verify its hash, then unzip it
function decipher_folder_zipped_and_hash() {
    decipher_file_zipped_and_hash;
}
