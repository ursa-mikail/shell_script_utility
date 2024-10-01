# source $HOME"/parameters.sh" 
source $HOME"/scripts/include.sh"

demarcator='==================================================='

number_of_colors_in_rainbow=7
key_static='00000000000000000000000000000000'

function ratchet_key(){
	#filename=$key_aes_cbc_ciphering_file
	number_of_bytes=16
	#check_if_file_exists;
	
	#shift # clear input
	start_index=3 
	number_of_keys_to_extract=3
	
	Ra_seeding_key=$(cipher_message_in_hex_strings $seed_Ra $key_static)
	echo $Ra_seeding_key
	ans=$Ra_seeding_key
	Ra_round_key=$Ra_seeding_key # this may go through racket rounds to dump extra rounds to keep a distance away from the Ra_roo_key which will not be used directly
	
	hash_table_Ra_rainbow_keys=''
	
	declare -a table_Ra_rainbow_keys=('');
	
	echo "Rainbow keys ....";
	for i in $(seq $index_start $step_size $number_of_colors_in_rainbow)
	do
	   Ra_round_key=$(cipher_message_in_hex_strings $ans $Ra_round_key)
	   table_Ra_rainbow_keys[$i]=$Ra_round_key
	   echo $i " : " ${table_Ra_rainbow_keys[$i]}
	   
	done
	echo "table_Ra_rainbow_keys : " ${table_Ra_rainbow_keys[@]}	
	
	echo "table_Ra_rainbow_keys : " ${table_Ra_rainbow_keys[@]:$start_index:$number_of_keys_to_extract}

	echo "<parts of the key>"
	start_index=1	
	key_element_index_from=0
	key_element_index_to=5
	echo ${table_Ra_rainbow_keys[$start_index]:$key_element_index_from:$key_element_index_to}
	
	hash_table_Ra_rainbow_keys=$(echo ${table_Ra_rainbow_keys[@]} | openssl dgst -$hash_algo )	
	echo "hash_table_Ra_rainbow_keys ($hash_algo): " $hash_table_Ra_rainbow_keys
	echo ""
	
	
	# unset table_Ra_rainbow_keys[$index_selected] # remove key
	
}

# as this is a deterministic process, we used static zero nonces
function create_Ra_seed_key { 
	number_of_inputs=1
	
	if [ "$#" -lt $number_of_inputs ];
	then
		# clr;
        echo "Usage : $0 create_Ra_seed_key $1: (passcode) $2: (passcode) "
		return;
	else
		seed_Ra=$(ascii_to_hex "$1")
	fi
	
	echo $(hex_to_ascii $seed_Ra) " is "
	echo $seed_Ra
	
	ratchet_key;
}

# main
passcode='to see the world'
create_Ra_seed_key "$passcode";
#ascii_to_hex "$passcode"