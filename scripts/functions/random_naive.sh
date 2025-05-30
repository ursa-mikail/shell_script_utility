function generate_random_base64(){
	#number_of_bytes=16
	number_of_bytes=$1
	
	openssl rand -base64 $number_of_bytes
}

function generate_random_bytes (){
	number_of_bytes="$1"
	printf "\n"
    # openssl rand -base64 5
	openssl rand -hex $number_of_bytes
}

function generate_random_hex(){
	#number_of_bytes=16
	number_of_bytes="$1"
	
	# head -c $number_of_bytes /dev/urandom | LC_CTYPE=C tr '\n' = | xxd -p | tr -d '\n'
	
	#  head -c $number_of_bytes /dev/urandom | LC_CTYPE=C tr '\n' = | hexdump -e '"%x"'
	# head -c $number_of_bytes /dev/urandom | LC_CTYPE=C tr '\n' = | xxd -p 

	openssl rand -hex $number_of_bytes
	# openssl rand -out <outout_file> -hex 
	# openssl rand -engine /dev/crypt0 -hex 20
	# cat /dev/urandom
	# #Generating a random number through openssl
	# openssl rand -hex $number_of_bytes > <outout_file>
}

function get_random_integer() {
	bound_lower=${1:-0}  # default value: 0
	bound_upper=${2:-10}  # default value: 10
	# shuf -i $bound_lower-$bound_upper -n 1
	# echo "random_element = random [$bound_lower, $bound_upper]"
	bound_upper=$((bound_upper+1))
	# random [bound_lower, bound_upper]
	random_element=$(echo $(($bound_lower + RANDOM % $bound_upper)))
	echo $random_element
}

function get_random_float() {
	echo "$random_element = random [0, 1]"
	random_element=( $(awk 'BEGIN{srand(); r=rand(); print r, 1-r}') );
	echo $random_element
}

function seed_random_with_pid() {
	RANDOM=$$    # Reseed using script's PID i.e. “$$” # $arr
	r1=$((${RANDOM}%98+1))
	r2=$((100-$r1))
	printf -v r1 "0.%.2d" $r1
	printf -v r2 "0.%.2d" $r2
	echo "$r1 $r2"
}

function generate_random_text() {
    number_of_characters="$1"
    
    # Define the set of characters to choose from
    charset='a-zA-Z0-9~`@#$%^&*()_+=-{}[]|\:;<>,./?'
    
    # Generate random text
    # text_random=$(cat /dev/urandom | tr -dc "$charset" | fold -w "$number_of_characters" | head -n 1)

    # If you still face issues, you can try a fallback method using base64
    # Uncomment the lines below to use base64 if the previous line fails
    text_random=$(head -c "$number_of_characters" /dev/urandom | base64 | tr -dc "$charset" | cut -c1-"$number_of_characters")

    echo "$text_random"
}


