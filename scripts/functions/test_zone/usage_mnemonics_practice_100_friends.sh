source $HOME"/scripts/include.sh"

mnemonics_suggested_list_location="https://raw.githubusercontent.com/Mikail-Eliyah/At-The-Back-Of-Your-Head-An-Insight-To-Mnemonics/main/mnemonics_suggested_list_00.txt"

function obtain_mnemonics_list(){
	echo "location: " $mnemonics_suggested_list_location
	
	get_filename_n_extension $mnemonics_suggested_list_location
	echo ":"
	file_name=$filename'.'$extension
	echo "file: " $file_name
	
	# get_file
	curl -s -O -L --insecure $mnemonics_suggested_list_location
	
}


function display_candidate(){
		clr;
		echo ""
		cat $file_name | grep -i $person_id". " | cut -d'.' -f 1-2
}

function usage_mnemonics_practice_100_friends_practice_00(){
	number_of_digits_for_inputs=2;
	obtain_mnemonics_list;
	
	person_id='0'
	
	while [ $person_id != '-' ]
	do
		read  -n $number_of_digits_for_inputs -p "Enter a number from 0 to 99 (enter '-' to exit):" person_id
		
		if [ $person_id == '-' ];
		then		
			rm -rf $file_name
			return 0;	
		elif [ ${#person_id} -lt 2 ];
		then
			person_id='0'$person_id;
		fi;

		display_candidate;
		
		# person_id='-'
	done
	
}

function usage_mnemonics_practice_100_friends_practice_01(){
	number_of_digits_for_inputs=2;
	obtain_mnemonics_list;
	
	person_id='0'
	
	while [ $person_id != '-' ]
	do
		read  -n $number_of_digits_for_inputs -p "(enter '-' to exit) or just hit [enter] to random select:" person_id
		
		if [ $person_id == '-' ];
		then		
			rm -rf $file_name
			return 0;	
		else
			person_id=$(shuf -i 0-99 -n 1);
			
			if [ ${#person_id} -lt 2 ];
			then
			person_id='0'$person_id;
			fi;

		fi;
		
		display_candidate;
		
		# person_id='-'
	done
	
}


function usage_mnemonics_practice_100_friends_main() {
	usage_mnemonics_practice_100_friends_menu;
	
	number_of_digits_for_inputs=2
	# read  -n 1 -p "Input Selection:" usage_mnemonics_practice_100_friends_menu_input
	read  -n $number_of_digits_for_inputs -p "Input Selection:" usage_mnemonics_practice_100_friends_menu_input
	echo ""
	
    if [ "$usage_mnemonics_practice_100_friends_menu_input" = "1" ]; then
		#		
		usage_mnemonics_practice_100_friends_practice_00;

    elif [ "$usage_mnemonics_practice_100_friends_menu_input" = "2" ]; then
		#		
		usage_mnemonics_practice_100_friends_practice_01;

    elif [ "$usage_mnemonics_practice_100_friends_menu_input" = "x" -o "$usage_mnemonics_practice_100_friends_menu_input" = "X" ];then # -o := `or` and `||`
		exit_program_for_menu;
    else
		usage_mnemonics_practice_100_friends_main_default_action;
    fi
	
}

function usage_mnemonics_practice_100_friends_menu() {
  echo "1 : start_practice : manually choose the friend"
  echo "2 : start_practice : random select the friend"
  
  echo ""
  echo "'x' or 'X' to exit the script"
  
  date +"%T.%N"
  date +%s
  get_timestamp
}

function usage_mnemonics_practice_100_friends_main_default_action() {
    echo "You have entered an invallid selection!"
    echo "Please try again!"
    echo ""
    echo "Press any key to continue..."
    read -n 1
    clear
	set -u # force it to treat unset variables as an error 
	unset usage_mnemonics_practice_100_friends_menu_input
	#echo $git_menu_input 
    usage_mnemonics_practice_100_friends_main
}

# main 
usage_mnemonics_practice_100_friends_main;
