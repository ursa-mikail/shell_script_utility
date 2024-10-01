# source $HOME"/scripts/parameters.sh" 
source $HOME"/scripts/include.sh"

demarcator='==================================================='

function cipher_message_00 { 
	number_of_inputs=2
	if [ $# -lt $number_of_inputs ]
	then
		# clr;
        		echo "Usage : $0 cipher_message $1: (message) $2: (passcode) "
		return;
	fi
	
	echo -n $1 | xxd -p -r | openssl enc -aes-128-cbc -nopad -nosalt -K $2 -iv '00000000000000000000000000000000' | xxd -p

}


# ref: http://nwsmith.blogspot.com/2012/07/aes-encryption-decryption-from-command.html

function decipher_message_00 { 
	number_of_inputs=2
	if [ $# -lt $number_of_inputs ]
	then
		# clr;
        		echo "Usage : $0 decipher_message $1: (message) $2: (passcode) "
		return;
	fi
		
	#echo "$1" | openssl enc -aes-256-cbc -pbkdf2 -iter $number_of_cipher_nonce_rounds -k "$2" | xxd -p;
	# echo "0: $1" | xxd -r | openssl enc -d -aes-128-ecb -nopad -nosalt -K  "$2" | xxd -p
	# echo -n "$1" | xxd -p -r | openssl enc -d -aes-128-ecb -nopad -nosalt -K  "$2" | xxd -p

	echo -n $1 | xxd -p -r | openssl enc -aes-128-cbc -d -nosalt -K $2 -iv '00000000000000000000000000000000' -nopad | xxd -p

	# openssl enc -aes-256-cfb8 -in <file_plaintext_in> -k file:<file_ciphered_out> -out encrypted -pbkdf2 -iv 021afbb5928ac15fa4503d90959ed139
	
	# openssl enc -d -aes-256-cfb8 -in encrypted -k file:<file_ciphered_in> -out <file_deciphered_out> -pbkdf2 -iv 021afbb5928ac15fa4503d90959ed139
}

function generate_key_primordial_for_ciphering(){
	#filename=$key_aes_cbc_ciphering_file
	number_of_bytes=16
	#check_if_file_exists;
	
	key_aes_cbc_ciphering=''
	
	#if [ $status == "false" ]; then 
		echo 'Generating :'$key_aes_cbc_ciphering
		key_aes_cbc_ciphering=$(openssl rand -hex $number_of_bytes )
		echo $key_aes_cbc_ciphering
		# cat $key_aes_cbc_ciphering_file
	#fi
}

function ratchet_key(){
	#filename=$key_aes_cbc_ciphering_file
	number_of_bytes=16
	#check_if_file_exists;
	
	#shift # clear input
	
	if [ "$key_aes_cbc_ciphering" == "" ]; then 
		echo "[primordial key absent]: generating primordial key ..."
		generate_key_primordial_for_ciphering;
	else
		key_aes_cbc_ciphering=$(cipher_message_in_hex_strings $1 $2)
		echo $key_aes_cbc_ciphering
	fi
}

function ratchet_key_reverse(){
	#filename=$key_aes_cbc_ciphering_file
	number_of_bytes=16
	#check_if_file_exists;
	
	# shift # clear input
	
	if [ "$key_aes_cbc_ciphering" == "" ]; then 
		echo "[primordial key absent]: generating primordial key ..."
		generate_key_primordial_for_ciphering;
	else
		key_aes_cbc_ciphering=$(decipher_message_in_hex_strings $1 $2)
		echo $key_aes_cbc_ciphering
	fi
}

function ratchet_key_N_rounds(){
	ans=$1
	echo "";
	for i in $(seq $index_start $step_size $number_of_rounds)
	do
	   ans=$(ratchet_key $ans $2);
	done
	echo $ans
}

function ratchet_key_reverse_N_rounds(){
	ans=$1
	echo "";
	for i in $(seq $index_start $step_size $number_of_rounds)
	do
	   ans=$(ratchet_key_reverse $ans $2);
	done
	echo $ans	
}

function print_label(){
	echo $demarcator
	echo $label
	echo $demarcator
}

# === main ===
# dos2unix lab_generate_key_ratcheting.sh
key_aes_cbc_ciphering='bd53050ec0c85d5bf53b009c446bc338'
label="START rachet"
key_aes_cbc_ciphering='a000000000000000000000000000000a'
key_aes_cbc_ciphering_static='00000000000000000000000000000000'
key_aes_cbc_ciphering_static='80000000000000000000000000000000'

label="Resultant start key: $key_aes_cbc_ciphering"
print_label;
key_aes_cbc_ciphering=$(ratchet_key $key_aes_cbc_ciphering $key_aes_cbc_ciphering_static);
label="Resultant key: $key_aes_cbc_ciphering"
print_label;

label="START rachet reverse()"
print_label;
key_aes_cbc_ciphering=$(ratchet_key_reverse $key_aes_cbc_ciphering $key_aes_cbc_ciphering_static);
label="Resultant key: $key_aes_cbc_ciphering"
print_label;

number_of_rounds=3
label="START rachet N: "$number_of_rounds" rounds"
print_label;
key_aes_cbc_ciphering=$(ratchet_key_N_rounds $key_aes_cbc_ciphering $key_aes_cbc_ciphering_static);
label="Resultant key: $key_aes_cbc_ciphering"
print_label;

label="START rachet reverse N: "$number_of_rounds" rounds"
print_label;
key_aes_cbc_ciphering=$(ratchet_key_reverse_N_rounds $key_aes_cbc_ciphering $key_aes_cbc_ciphering_static);
label="Resultant key: $key_aes_cbc_ciphering"
print_label

__='
generate_key_primordial_for_ciphering;

echo $key_aes_cbc_ciphering

echo "0: $key_aes_cbc_ciphering" 
#bd53050ec0c85d5bf53b009c446bc338
#next round: decopher_message <output> 'bd53050ec0c85d5bf53b009c446bc338' 
# returns the same
echo $key_aes_cbc_ciphering

echo "1 round rachet"
ratchet_key $key_aes_cbc_ciphering $key_aes_cbc_ciphering;
echo $key_aes_cbc_ciphering

echo ""
echo "reverse checking: " $(decipher_message_00 $key_aes_cbc_ciphering $key_aes_cbc_ciphering)

echo "reverse checking: " $(decipher_message_in_hex_strings $key_aes_cbc_ciphering $key_aes_cbc_ciphering)

number_of_rounds=2

step_size=1
index_start=0
index_end=number_of_rounds

echo $number_of_rounds" round(s) rachet"
ratchet_key_N_rounds;
echo $key_aes_cbc_ciphering

echo $demarcator
#shift # clear input
ans=$(cipher_message_in_hex_strings "00000000000000000000000000000000" "80000000000000000000000000000000")

echo $ans 

ans=$(decipher_message_in_hex_strings $ans "80000000000000000000000000000000")
echo $ans 
echo $demarcator

ans=$(cipher_message_in_hex_strings $ans "80000000000000000000000000000000")

echo $ans 

ans=$(decipher_message_in_hex_strings $ans "80000000000000000000000000000000")
echo $ans 
echo $demarcator

label="START rachet"
key_aes_cbc_ciphering='00000000000000000000000000000000'
key_aes_cbc_ciphering_static='00000000000000000000000000000000'
label="Resultant start key: $key_aes_cbc_ciphering"
print_label;
key_aes_cbc_ciphering=$(ratchet_key $key_aes_cbc_ciphering $key_aes_cbc_ciphering_static);
label="Resultant key: $key_aes_cbc_ciphering"
print_label;

label="START rachet reverse()"
print_label;
key_aes_cbc_ciphering=$(ratchet_key_reverse $key_aes_cbc_ciphering $key_aes_cbc_ciphering_static);
label="Resultant key: $key_aes_cbc_ciphering"
print_label;



label="START rachet reverse()"
print_label;
ratchet_key_reverse;
label="Resultant key: $key_aes_cbc_ciphering"
print_label;

'