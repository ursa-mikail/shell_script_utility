#source $HOME"/scripts/parameters.sh" 

function retrieve_key_from_key_file(){
	filename=$key_file
	check_if_file_exists;
	
	if [ $status == "true" ]; then 
		cmd="cat $key_file"
		key=$(eval $cmd)
	fi
	
	# echo "key: "$key
}

function generate_N_bytes_random(){
	number_of_bytes=16
	
	read -p '[Enter number_of_bytes of random to generate]: ' number_of_bytes
	
	echo 'Generating '$number_of_bytes ' random bytes'
	openssl rand -hex $number_of_bytes 
}

function generate_key_for_hmac_sha256(){
	filename=$key_hmac_sha256_file
	number_of_bytes=64
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		echo 'Generating :'$key_hmac_sha256_file
		openssl rand -hex $number_of_bytes > $key_hmac_sha256_file
		cat $key_hmac_sha256_file
	fi
}

function generate_key_for_ciphering(){
	filename=$key_aes_cbc_ciphering_file
	number_of_bytes=16
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		echo 'Generating :'$key_aes_cbc_ciphering_file
		openssl rand -hex $number_of_bytes > $key_aes_cbc_ciphering_file
		cat $key_aes_cbc_ciphering_file
	fi
}

function display_key_profile(){
	key_file="$1"
	
	cat $key_file | grep -i "private\|public\|pub" --color
	echo ""
	echo "key: "
	cat $key_file
}

function display_key_for_ciphering(){
	key_file=$key_aes_cbc_ciphering_file
	retrieve_key_from_key_file;
	
	if [ $status == "true" ]; then 
		key_for_ciphering=$key
	fi
	
	echo "key: "$key_for_ciphering
}

function get_key_for_ciphering(){
	key_file=$key_aes_cbc_ciphering_file
	retrieve_key_from_key_file;
	
	if [ $status == "true" ]; then 
		key_for_ciphering=$key
	fi
	
	# echo "key: "$key_for_ciphering
}

function get_key_for_authentication(){
	key_file=$key_hmac_sha256_file
	retrieve_key_from_key_file;
	
	if [ $status == "true" ]; then 
		key_hmac_sha256_authentication=$key
	fi
	
	# echo "key: "$key_for_ciphering
}

function display_key_for_authentication(){
	key_file=$key_hmac_sha256_file
	retrieve_key_from_key_file;
	
	if [ $status == "true" ]; then 
		key_hmac_sha256_authentication=$key
	fi
	
	echo "key: "$key_hmac_sha256_authentication
}

function generate_key_rsa_for_ciphering () {
	# create_folders;
	label="[Creating "$key_rsa_ciphering_private"]";
	print_label;
	
	filename=$key_rsa_ciphering_private
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		# by omitting -aes128 : openssl do not encrypt key
		# openssl genrsa -aes256 -out $key_rsa_ciphering_private $key_length
		openssl genrsa -out $key_rsa_ciphering_private $key_length
		sleep 1
	
		label="[Display "$key_rsa_ciphering_private"]";
		print_label;
	
		openssl rsa -text -in $key_rsa_ciphering_private
		openssl rsa -in $key_rsa_ciphering_private -check
		openssl rsa -noout -modulus -in $key_rsa_ciphering_private | openssl $hash_algo
		sleep 1
		# openssl rsa -in $key_rsa_ciphering_private -noout -text
	
		# Export RSA Public Key to a File : 
		# openssl rsa -in $key_rsa_ciphering_private -outform PEM -pubout -out $key_rsa_ciphering_public
		openssl rsa -in $key_rsa_ciphering_private -pubout -out $key_rsa_ciphering_public
		sleep 1
	
		label="[Display "$key_rsa_ciphering_public"]";
		print_label;
		cat $key_rsa_ciphering_public
	else
		label="[ "$key_rsa_ciphering_public" exists. ]";
		print_label;
	fi
}

function generate_key_rsa_for_signing () {
	# create_folders;
	label="[Creating "$key_rsa_signing_private"]";
	print_label;
	
	filename=$key_rsa_signing_private
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		# by omitting -aes128 : openssl do not encrypt key
		# openssl genrsa -aes256 -out $key_rsa_signing_private $key_length
		openssl genrsa -out $key_rsa_signing_private $key_length
		sleep 1
	
		label="[Display "$key_rsa_signing_private"]";
		print_label;
	
		openssl rsa -text -in $key_rsa_signing_private
		openssl rsa -in $key_rsa_signing_private -check
		openssl rsa -noout -modulus -in $key_rsa_signing_private | openssl $hash_algo
		sleep 1
		# openssl rsa -in $key_rsa_signing_private -noout -text
	
		# Export RSA Public Key to a File : 
		# openssl rsa -in $key_rsa_signing_private -outform PEM -pubout -out $key_rsa_signing_public
		openssl rsa -in $key_rsa_signing_private -pubout -out $key_rsa_signing_public
		sleep 1
	
		label="[Display "$key_rsa_signing_public"]";
		print_label;
		cat $key_rsa_signing_public
	else
		label="[ "$key_rsa_signing_private" exists. ]";
		print_label;
	fi
}


function display_key_rsa_for_signing(){
	filename=$key_rsa_signing_private
	check_if_file_exists;
	
	if [ $status == "true" ]; then 
		label="[Displaying "$key_rsa_signing_private"]";
		print_label;
	
		openssl rsa -text -in $key_rsa_signing_private
		echo $demarcator
		openssl rsa -in $key_rsa_signing_private -check
		echo $demarcator
		openssl rsa -noout -modulus -in $key_rsa_signing_private | openssl $hash_algo
		echo $demarcator
	else
		label="[ "$key_rsa_signing_private" does not exists. ]";
		print_label;
	fi

	filename=$key_rsa_signing_public
	check_if_file_exists;
	
	if [ $status == "true" ]; then 
		label="[Display "$key_rsa_signing_public"]";
		print_label;
		cat $key_rsa_signing_public
	else
		label="[ "$key_rsa_signing_public" does not exists. ]";
		print_label;
	fi
}

function generate_key_dsa_for_signing () {
	label="[Creating DSA signing key: "$key_dsa_signing_private"]";
	print_label;
	
	filename=$key_dsa_signing_private
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		openssl dsaparam -genkey $key_length | openssl dsa -out  $key_dsa_signing_private #-aes128
		openssl dsa -text -in $key_dsa_signing_private
		# openssl dsa -in $key_dsa_signing_private -check
		
		label="[Display "$key_dsa_signing_private"]";
		print_label;
		cat $key_dsa_signing_private
		
		# Export DSA Public Key to a File : 
		openssl dsa -in $key_dsa_signing_private -pubout -out $key_dsa_signing_public
		sleep 1
	
		label="[Display "$key_dsa_signing_public"]";
		print_label;
		cat $key_dsa_signing_public
		
	else
		label="[ "$key_dsa_signing_private" exists. ]";
		print_label;
	fi
}

function display_key_dsa_for_signing () {
	filename=$key_dsa_signing_private
	check_if_file_exists;
	
	if [ $status == "true" ]; then 
		label="[Display "$key_dsa_signing_private"]";
		print_label;
		cat $key_dsa_signing_private
	
		label="[Display "$key_dsa_signing_public"]";
		print_label;
		cat $key_dsa_signing_public
		
	else
		label="[ "$key_dsa_signing_private" exists. ]";
		print_label;
	fi
}

#ECDSA: P-256 curve
#EdDSA : Curve25519
# generating a elliptic curve P-256 key pair (# ECDSA: P-256 curve)
#private_key_EC_P256=”$1”
#public_key_EC_P256=”$2”
#openssl ecparam -name prime256v1 -genkey -out $private_key_EC_P256
#openssl ec -in $private_key_EC_P256 -pubout -out $public_key_EC_P256

function generate_key_ecc_for_signing () {
	label="[Creating ECC signing key: "$key_ec_signing_private"]";
	print_label;
	
	filename=$key_ec_signing_private
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		openssl ecparam -genkey -name secp256r1 | openssl ec -out $key_ec_signing_private #-aes128
		openssl ec -text -in $key_ec_signing_private
		# openssl ec -in $key_ec_signing_private -check
		label="[Display "$key_ec_signing_private"]";
		print_label;
		cat $key_ec_signing_private
		
		# Export ECC Public Key to a File : 
		openssl ec -in $key_ec_signing_private -pubout -out $key_ec_signing_public
		sleep 1
	
		label="[Display "$key_ec_signing_public"]";
		print_label;
		cat $key_ec_signing_public
		
	else
		label="[ "$key_ec_signing_private" exists. ]";
		print_label;
	fi
}

function display_key_ecc_for_signing () {
	filename=$key_ec_signing_private
	check_if_file_exists;
	
	if [ $status == "true" ]; then 
		label="[Display "$key_ec_signing_private"]";
		print_label;
		cat $key_ec_signing_private
	
		label="[Display "$key_ec_signing_public"]";
		print_label;
		cat $key_ec_signing_public
		
	else
		label="[ "$key_ec_signing_private" exists. ]";
		print_label;
	fi
}

function import_partner_key(){
	read -p '[partner_id, or name]: ' partner_id
	read -p '[partner_key]: ' partner_key
	# read -p '[key]: ' key	# caveat keep as plaintext for now
	read -p '[purpose_of_usage]: ' purpose_of_usage	
	partner_key_file=$partner_id'@'$purpose_of_usage'.key'	
	
	partner_key_file_with_path=$key_store_path$partner_key_file
	
	filename=$partner_key_file_with_path
	check_if_file_exists;
	
	if [ $status == "false" ]; then 
		echo $partner_key > $partner_key_file_with_path
	
		echo 'Creating [partner_key_file, <partner_id@speak>.key e.g.  user_x@speak.key]: ' $partner_key_file_with_path

	else
		label="[ "$filename" exists. ]";
		print_label;
		
		read -p '[confirm OK to overwrite, else press <enter>]: ' confirmation
		
		if [ $confirmation == "OK" ] || [ $confirmation == "ok" ]; then 
			echo $partner_key > $partner_key_file_with_path
	
			echo 'Creating [partner_key_file, <partner_id@speak>.key e.g.  user_x@speak.key]: ' $partner_key_file_with_path			
		else
			echo "Nothing done and exited."
			exit
		fi
		
	fi
}

function display_partner_key(){
	tree $key_store_path
	
	read -p '[partner_key_file]: ' partner_key_file	
	partner_key=$(cat $key_store_path$partner_key_file)
	
	echo "partner_key: "$partner_key
}