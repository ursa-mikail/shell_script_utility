# Load configurations
source config.txt

# Create directories
braces="{$domains}/{$domain_subs}"
file_out="$folder_out/$braces"
eval mkdir -p $file_out

# Create files within the defined range inside each subdirectory
for dir in $(eval echo $file_out); do
    #files="$dir/$file_name{$index_start..$index_end}.txt"
    #eval touch $files
    for i in $(seq -f "%03g" $index_start $index_end); do
        touch "$dir/$file_name$i.txt"
    done
done

#braces="{01..100}"
#files="$file_name"$braces".txt" 
#eval touch $files

