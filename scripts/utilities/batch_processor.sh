# Example usage
#input_file="./data/log.txt"
#output_file="./data/output.txt"

#process_file "$input_file" "$output_file"

# Function to process each word
function process_word() {
    local word=$1
    # Replace this with your actual processing logic
    echo "Processing: $word"
    # Simulate processing output
    hash_message "$word"
}

# Function to process the file
function process_file() {
    local input_file=$1
    local output_file=$2

    # Ensure the input file exists and is readable
    if [[ ! -r "$input_file" ]]; then
        echo "Error: Input file '$input_file' does not exist or is not readable."
        return 1
    fi

    echo "Reading from: $input_file"
    echo "Writing to: $output_file"

    # Handle the output file
    if [[ -e "$output_file" ]]; then
        echo "Output file '$output_file' exists. Clearing it."
        # > "$output_file"
        rm -rf "$output_file"
    else
        echo "Creating output file '$output_file'."
        touch "$output_file"
    fi

    # Read each line from the input file
    while IFS= read -r line || [[ -n "$line" ]]; do
        echo "Processing line: $line"
        # Split the line into words
        for word in $line; do
            echo "Processing word: $word"
            # Process each word and append the result to the output file
            process_word "$word" >> "$output_file"
        done
    done < "$input_file"

    echo "Processing completed. Output written to $output_file"
}

: '
use cases:
'
echo use_cases
: <<'END'
# Step 1: Generate keys
process_files "hsm_domain_key_{1..5}.pem" "" "./cert_folder" 'openssl genpkey -algorithm RSA -out "$outfile" -pkeyopt rsa_keygen_bits:2048'

# Step 2: Extract public keys
process_files "./cert_folder/hsm_domain_key_*.pem" "_pub" "./cert_pub_folder" \
  'openssl pkey -in "$filepath" -pubout -out "$outfile" -outform pem'

END
echo use_cases

function process_files() {
  local pattern="$1"
  local suffix="$2"
  local outdir="$3"
  local cmd_template="$4"

  echo "pattern: $pattern"
  echo "suffix: $suffix"
  echo "outdir: $outdir"
  echo "cmd_template: $cmd_template"

  if [[ -z "$outdir" ]]; then
    echo "Output directory not specified"
    return 1
  fi

  mkdir -p "$outdir" || return 1

  # Evaluate the pattern to expand the braces
  eval "files=($pattern)"
  
  for filepath in "${files[@]}"; do
    local base=$(basename "$filepath" .pem)
    local outfile="${outdir}/${base}${suffix}.pem"
    echo "Generating: $outfile"
    eval "$cmd_template"
  done
}


