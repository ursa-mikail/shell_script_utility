function remove_whitespaces { 
	var="$1"
	#var="$(echo -e "${var}" | tr -d '[:space:]')" # remove whitespace
	var=$(echo ${var//[[:blank:]]/})
	
	#echo "string length: " ${#var}
	echo $var
}

function remove_spaces { 
	var="$1"
	var="$(echo -e "${var}" | xargs)" # remove remove_spaces
	
	#echo "string length: " ${#var}
	echo $var
}

function remove_before { 
	target_str="$1"
	remove_before="$2"
	
	resultant=$(echo $target_str | sed 's/^.*'$remove_before'/'$remove_before'/')
	echo $resultant
}

function remove_after { 
	target_str="$1"
	remove_after="$2"
	
	resultant=$(echo $target_str | sed 's/'$remove_after'.*/'$remove_after'/')
	echo $resultant	
}

function remove_prefix { 
	target_str="$1"
	prefix_to_remove="$2"
	
	if [ "$target_str" == "" ] # not specified 
	then
		echo "Usage : remove_prefix $target_str $prefix_to_remove"
		echo "Usage : remove_prefix 'notAfter=Oct  7, 2020  3:32:11 PM GMT' 'notAfter=' ---> 'Oct  7, 2020  3:32:11 PM GMT'"		
	else
		target_str=${target_str#"$prefix_to_remove"} # remove prefix
	fi;
	
	#prefix_to_remove="notAfter="
	#suffix_to_remove="GMT"
	# e.g. target_str='notAfter=Oct  7, 2020  3:32:11 PM GMT'
	
	echo "$target_str" # return string
}

function remove_suffix { 
	target_str="$1"
	suffix_to_remove="$2"
	
	if [ "$target_str" == "" ] # not specified 
	then
		echo "Usage : remove_suffix $target_str $prefix_to_remove"
		echo "Usage : remove_suffix 'notAfter=Oct  7, 2020  3:32:11 PM GMT' 'GMT' ---> notAfter=Oct  7, 2020  3:32:11 PM"		
	else
		target_str=${target_str%"$suffix_to_remove"}	# remove suffix
	fi;	
	
	#prefix_to_remove="notAfter="
	#suffix_to_remove="GMT"
	# e.g. target_str='notAfter=Oct  7, 2020  3:32:11 PM GMT'
	
	echo "$target_str" # return string
}

: '
prefix_to_remove="notAfter="
suffix_to_remove="GMT"
target_str="notAfter=Oct  7, 2020  3:32:11 PM GMT"
result=$(remove_prefix)
echo $result
'

function get_line_N_from_file(){
	number_of_inputs=2
	line_number_to_view="$1"
	
	if [ $# -lt $number_of_inputs ]
	then
		echo "Usage: get_line_N_from_file line_number_to_view target_file"
		
		#return 0
	fi
	
	if [ $# -lt $number_of_inputs ]
	then
		read -r -p "target_file [e.g. c:/path_to_folder_to_file/file_name] : "  target_file
		read -r -p "line_number_to_view : "  line_number_to_view		
	else
		target_file="$1"
		line_number_to_view="$2"
	fi
	
	number_of_lines=$(wc -l $target_file | awk '{ print $1 }')
	#echo $number_of_lines
	
	if [ $number_of_lines -lt $line_number_to_view ]
	then
		echo "line_number_to_view > number_of_lines of the file"
	else
		cat $target_file | head -$line_number_to_view | tail -1
	fi
}

function remove_word_from_string (){
	#part_to_remove='FISH'
	# printf '%s\n' "${$target_string//$part_to_remove/}" # 
	target_string=${target_string//$part_to_remove/}
}

# $ echo "asdefwefwgfvw" | change_case_to_upper
function change_case_to_upper (){
	tr '[:lower:]' '[:upper:]'
}

function change_case_to_lower (){
	tr '[:upper:]' '[:lower:]'
}

function string_to_array_with_single_pre_fixed_delimiters (){
	string="$1"
	delimiters=', '
	IFS=$delimiters read -r -a array <<< "$string"
	
	for index in "${!array[@]}"
	do
		echo "$index ${array[index]}"
	done	
	
	# delete and define array elements
	#unset "array[1]"
	#array[42]=Earth	
}

declare -a array_elements=()
declare number_of_words=0

function string_to_array_with_single_char_delimiters (){
	string="$1"
	#delimiters=', '
	delimiters="$2"
	IFS=$delimiters read -r -a array <<< "$string"
	
	unset array_elements # clear array
	
	for index in "${!array[@]}"
	do
		echo "$index ${array[index]}"
		array_elements[${#array_elements[@]}]=$(echo "${array[index]}")
	done	
	
	# delete and define array elements
	#unset "array[1]"
	#array[42]=Earth	
	
	number_of_words=${#array_elements[@]}
	
	echo "number_of_words: " $number_of_words
}

# $ string_to_array_with_single_substring_delimiters "1[test]123[test]23" '\[test\]'

# e.g. string_in="1--123--23"
# e.g. substring="--"

function string_to_array_with_single_substring_delimiters (){
	string_in="$1"
	substring="$2"
	
	unset array_elements # clear array

	while test "${string_in#*$substring}" != "$string_in" ; do
	  echo "${string_in%%$substring*}"
	  #string_in="${string_in#*$substring}"
	  #echo ":" $string_in
	  array_elements[${#array_elements[@]}]=$(echo "${string_in%%$substring*}")
	done
	#echo "$string_in"
	
	number_of_words=${#array_elements[@]}
}

# str="the quick brown fox jumps over the lazy bear"
function extract_word_given_index (){
	str="$1"
	index_of_word_to_be_extracted="$2"
	#echo ${#str}
	word_extracted=''
	
	#echo "str: "  $str
	# echo $str | cut -d ' ' -f1,2,3
	string_to_array_with_single_char_delimiters "$1" " "
	
	#number_of_words="${array_elements[@]}"
	#number_of_words=9
	#echo $number_of_words

	if [ $index_of_word_to_be_extracted -lt $number_of_words ]
	then
		word_extracted=$(echo $str | cut -d ' ' -f"$index_of_word_to_be_extracted")
		
		echo "word_extracted: " $word_extracted
	else
		echo "index_of_word_to_be_extracted > number_of_words"
	fi
	
}

# word_count_in_str "the quick brown fox jumps over the lazy bear"
function word_count_in_str(){
	str_without_punctuation=$(replace_all_symbols "$1") # remove_punctuation_from_str
	
	#echo $str_without_punctuation
	
	string_to_array_with_single_char_delimiters "$str_without_punctuation" " "
	
	echo "number_of_words:" $number_of_words
}

# str_to_snake_case 'QR Code JSON Encoder/Decoder For Contact Share'
# Convert to snake_case (lowercase and underscores)
function str_to_snake_case() {
    input_string="$1"
    formatted_string=$(echo "$input_string" | tr -cs '[:alnum:]' '_' | tr '[:upper:]' '[:lower:]' | tr -s '_')
    # Remove trailing underscore if present
    formatted_string=$(echo "$formatted_string" | sed 's/_$//')
    echo "$formatted_string"
}

# str_to_kebab_case 'QR Code JSON Encoder/Decoder For Contact Share'
# Convert to kebab-case (lowercase and hyphens)
function str_to_kebab_case() {
    input_string="$1"
    formatted_string=$(echo "$input_string" | tr -cs '[:alnum:]' '-' | tr '[:upper:]' '[:lower:]' | tr -s '-')
    # Remove trailing hyphen if present
    formatted_string=$(echo "$formatted_string" | sed 's/-$//')
    echo "$formatted_string"
}

# str_to_camel_case 'QR Code JSON Encoder/Decoder For Contact Share'
# Convert to camelCase (first letter lowercase, no separator)
# Convert to camelCase (first letter lowercase, subsequent words capitalized)
function str_to_camel_case() {
    local input_string="$1"
    
    # Convert to lowercase and replace non-alphanumeric characters with spaces
    local cleaned=$(echo "$input_string" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/ /g')
    
    # Capitalize first letter after each space and remove spaces
    local camel_case=""
    local capitalize_next=false

    for ((i=0; i<${#cleaned}; i++)); do
        local char="${cleaned:$i:1}"
        
        if [[ "$char" == " " ]]; then
            capitalize_next=true
        else
            if [ "$capitalize_next" = true ]; then
                camel_case="${camel_case}$(echo "$char" | tr '[:lower:]' '[:upper:]')"
                capitalize_next=false
            else
                camel_case="${camel_case}${char}"
            fi
        fi
    done

    # Ensure the first character is lowercase
    camel_case="$(echo "${camel_case:0:1}" | tr '[:upper:]' '[:lower:]')${camel_case:1}"

    echo "$camel_case"
}

# str_to_pascal_case 'QR Code JSON Encoder/Decoder For Contact Share'
# Convert to PascalCase (capitalize the first letter)
function str_to_pascal_case() {
    input_string="$1"
    camel_case_string=$(str_to_camel_case "$input_string")
    # Capitalize the first letter manually
    pascal_case_string="$(echo ${camel_case_string:0:1} | tr '[:lower:]' '[:upper:]')${camel_case_string:1}"
    echo "$pascal_case_string"
}

# str_to_capital_snake_case 'QR Code JSON Encoder/Decoder For Contact Share'
# Convert to CAPITAL_SNAKE_CASE (uppercase and underscores)
function str_to_capital_snake_case() {
    input_string="$1"
    formatted_string=$(echo "$input_string" | tr -cs '[:alnum:]' '_' | tr '[:lower:]' '[:upper:]' | tr -s '_')
    # Remove trailing underscore if present
    formatted_string=$(echo "$formatted_string" | sed 's/_$//')
    echo "$formatted_string"
}

# Convert to Title Case
function str_to_title_case() {
    input_string="$1"
    formatted_string=$(echo "$input_string" | sed -E 's/[^[:alnum:]]+/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    echo "$formatted_string"
}

