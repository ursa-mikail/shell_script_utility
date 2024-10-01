source $HOME"/scripts/include.sh"

# $ dos2unix lab_read_array.sh; ./lab_read_array.sh

	# globals (as there is no return of arrays)
	declare -a array_hash=() ## declare an array variable
		
function get_hashes_in_array(){
	IFS=$'\r\n' GLOBIGNORE='*' command eval  'line_contents=($(cat $path_to_file))'
	
	character_demarcartor='=' # remove characters before this

	# echo "${line_contents[5]}"
	# echo "${line_contents[@]}"

	for i in "${line_contents[@]}"  ## loop through the above array
	do
		i=${i#*$character_demarcartor}
		i=$(echo $i | tr -d ' ')
	   echo "$i" # or do whatever with individual element of the array
	   
	   # Add new element at the end of the array
	   array_hash[${#array_hash[@]}]=$(echo "$i")
	   
	done
	
	echo "display : array_hash"
	for value in "${array_hash[@]}"
	do
		echo $value
	done
	
}

function get_tags_in_array(){
    #number_of_elements_in_array=${#array_hash[@]}
	#unset array_hash{1..$number_of_elements_in_array} # clear array
	unset array_hash # clear array
		
	IFS=$'\r\n' GLOBIGNORE='*' command eval  'line_contents=($(cat $path_to_file))'
	
	character_demarcartor='=' # remove characters before this

	# echo "${line_contents[5]}"
	# echo "${line_contents[@]}"

	for i in "${line_contents[@]}"  ## loop through the above array
	do
		#i=${i#*$character_demarcartor}
		i=$(echo $i |  sed 's/'$character_demarcartor'.*//')
		i=$(echo $i | tr -d ' ')
	   # echo "$i" # or do whatever with individual element of the array
	   
	   # Add new element at the end of the array
	   array_hash[${#array_hash[@]}]=$(echo "$i")
	   
	done
	
	echo "display : tags"
	for value in "${array_hash[@]}"
	do
		echo $value
	done
	
}

function get_number_of_lines_in_file(){
	get_file_content_lines_in_array;
	number_of_lines=${#line_contents[@]}
	echo "number_of_lines: " $number_of_lines
}

function look_for_exact_line_in_file(){
	get_file_content_lines_in_array;
	
	number_of_lines=${#line_contents[@]}
	echo "number_of_lines: " $number_of_lines

	# target_line_to_find='Updated:2020-10-16_1745hr_57sec'
	echo "look for: $target_line_to_find"
	echo "string len: " ${#target_line_to_find}

	part_to_remove='Updated:'
	for i in "${line_contents[@]}"  ## loop through the above array
	do
		echo "string len: " ${#i}
		i=$(echo $i | tr -d '\r')
		i=$(echo $i | tr -d '\n')
		i=$(echo $i | tr -d '\t')
		i=$(echo $i | tr -d ' ')
		
		target_string=$i
		remove_word_from_string;
		i=$target_string
		
		echo "string len: " ${#i}
		#i=$(echo $i | tr -d 'sec')
		echo "$i" # or do whatever with individual element of the array  
		#echo $target_line_to_find
		if [ "$i" == "$target_line_to_find" ]; then 
			echo $target_line_to_find " exists."
		fi
	done
	
}

function compute_hashes_of_all_files_in_folder() {
	file_type='*.sh'
	find -name "$file_type" -exec openssl dgst -sha1  "{}" + >  $path_to_file
	# find /home/username/ -name "*.err"
}

# main
path_to_file='../version.txt'
#number_of_lines=${#line_contents[@]}
#echo "number_of_lines: " $number_of_lines

#target_line_to_find='Updated:2020-10-16_1745hr_57sec'
target_line_to_find='2020-10-16_1745hr_57sec'
look_for_exact_line_in_file;

path_to_file='./hashes.txt'
echo ""
compute_hashes_of_all_files_in_folder;
#cat $path_to_file

get_hashes_in_array;

echo "display : array_hash"
for value in "${array_hash[@]}"
do
     echo $value
done

# get_tags_in_array;

# display_array_elements;

	for value in "${array_hash[@]}"
	do
		 array_from[${#array_from[@]}]=$value
	done
fill_data_with_another_array;

echo "::::"
# echo $array_elements
display_array_elements;

index=2
get_Nth_element_from_array;
echo "Nth_element: " $Nth_element
echo ""
#element_to_remove='ae17c83d3c18fd87f288f045151655272b973500'

element_to_remove=$Nth_element
#echo "element_to_remove: " $element_to_remove
#remove_specific_element_from_array $element_to_remove;
#remove_specific_element_from_array;
element_01_to_remove='ae17c83d3c18fd87f288f045151655272b973500'
delete=($element_to_remove $element_01_to_remove) 
remove_multiple_elements_from_array;

#remove_Nth_element_from_array;

path_to_file='./out.txt'
write_array_to_file;
echo "result:"
cat $path_to_file
rm -rf $path_to_file
