source $HOME"/scripts/include.sh"

demarcator='====================================='

function check_status {
  expect=250
  if [ $# -eq 3 ] ; then
	expect="${3}"
  fi
  if [ $1 -ne $expect ] ; then
	echo "Error: ${2}"
	exit
  fi
}


# account: ---; ID: ---; pass: ---
function get_parameter_from_ciphered_file() {
	if [ "$1" == "-h" ] # help
	then
        echo "get_parameter_from_ciphered_file <ciphered_file> <tag>"
	else     	
		# get file name
		filename_ciphered_file="$1"
		
		filename_ciphered_filename=$filename_ciphered_file
        

		# while a '.' exists
		filename_ciphered_filename=$(get_filename_without_version_tag $filename_ciphered_filename)
		
		
		filename_deciphered_file=$filename_ciphered_filename'.dec'
        decipher_file $filename_ciphered_file $filename_deciphered_file;
        #cat $filename_ciphered_file.txt;
        hit_lines=$(grep -oi -P "$2"'.*.*' $filename_deciphered_file);
		
		echo $demarcator
		echo $hit_lines
		echo $demarcator
		
        rm -rf $filename_deciphered_file;
	fi;                         	  
}



# main

# cipher_file secrets.txt $filename_ciphered_file
filename_ciphered_file='./test_data/secrets.enc'
#filename_ciphered_file='secrets.1.1...1.2....txt....enc'
tag='gmail'

#get_filename_without_version_tag $filename_ciphered_file

get_parameter_from_ciphered_file $filename_ciphered_file $tag



: '


MyHost=`hostname`
#read -u 3 sts line
echo "enter [status 1] [status 2]"
read sts line
check_status "${sts}" "${line}" 220
 
echo "HELO ${MyHost}" >&3

echo "enter [status 1] [status 2]"
read sts line
check_status "$sts" "$line"


read -p "Enter your mail host: " MailHost
MailPort=25
read -p "From: " FromAddr
read -p "To: " ToAddr
read -p "Subject: " Subject
read -p "Message: " Message
exec 3<>/dev/tcp/${MailHost}/${MailPort}
 
echo "MAIL FROM: ${FromAddr}" >&3
 
read -u 3 sts line
checkStatus "$sts" "$line"
 
echo "RCPT TO: ${ToAddr}" >&3
 
read -u 3 sts line
checkStatus "$sts" "$line"
 
echo "DATA" >&3
 
read -u 3 sts line
checkStatus "$sts" "$line" 354
echo "Subject: ${Subject}" >&3
echo "${Message}" >&3
echo "." >&3
read -u 3 sts line
checkStatus "$sts" "$line"

echo "0123456789"| wc -c 
echo -n "It is currently: ";date
echo -n "I am logged on as ";whoami
echo -n "This computer is called ";hostname
echo -n "I am currently in the directory ";pwd
echo -n "The number of people currently logged on is:"
who | wc -l
#+----------------------------------------------------------

'

#
#		while [[ "$filename_ciphered_filename" == *"."* ]]
#		do
#		   filename_ciphered_filename=$(echo "$filename_ciphered_filename" | grep -oP '.*?(?=\.)')
#		done	
		
