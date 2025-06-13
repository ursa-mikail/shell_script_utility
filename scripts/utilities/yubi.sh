echo ""
: <<'NOTE_USAGE'

ykman info
ykman openpgp info
ykman piv info

NOTE_USAGE
echo "" 

function get_yubikey_info() {
  local serial_number
  serial_number=$(ykman list --serials | head -n 1)

  if [[ -z "$serial_number" ]]; then
    echo "❌ No YubiKey detected."
    return 1
  fi

  echo "=== Get Serial Number & Basic Info ==="
  echo "🔍 Found YubiKey with serial: $serial_number"
  ykman --device "$serial_number" info
}

function view_all_functions_of_yubi_sh() {
  # Lists all functions defined in the yubi.sh file
  grep -E '^\s*(function\s+)?[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{' $HOME"/scripts/utilities/yubi.sh"
}

echo ""
: <<'NOTE_USAGE'

🧪 1. Generate N PEM Keys for Testing
# N is how many keys you want
N=7
for i in {0..$N}; do
  openssl genpkey -algorithm RSA -out "key_$i.pem" -pkeyopt rsa_keygen_bits:2048
done

🖇️ 2. Zsh Function: Import PEM Keys to YubiKey Slot
This function detects how many key_*.pem files exist and imports them to the 5FC103 slot:

🔄 Advanced: Import to Different Slots
To cycle through slots dynamically (e.g., for 5FC10X slots):

local slot=$(printf "5FC10%d" $i)
ykman piv objects import $slot "$key_file" -P "$pin"

[TO=DO]
view stored keys
delete stored keys
retrieve stored keys

NOTE_USAGE
echo "" 

function probe_custom_key_slots(){
  for i in {0..15}; do
    slot=$(printf "5fc10%x" $i)
    echo -n "Checking $slot: "
    ykman piv keys info $slot 2>/dev/null && echo "✅ Key exists" || echo "❌ Empty"
  done
}


# Note: read -s hides the PIN as it is typed
function import_keys_to_yubikey() {
  local pem_files=(key_*.pem(N))
  local N=${#pem_files[@]}
  
  # Define slots in order - using standard PIV slots
  local slots=(9a 9c 9d 9e 82 83 84 85)
  
  if [[ $N -eq 0 ]]; then
    echo "No key_*.pem files found in current directory."
    return 1
  fi
  
  if [[ $N -gt ${#slots[@]} ]]; then
    echo "Warning: Found $N key files but only ${#slots[@]} slots available."
    echo "Only the first ${#slots[@]} keys will be imported."
    N=${#slots[@]}
  fi
  
  # Get PIN
  echo -n "Enter PIN for YubiKey: "
  read -s pin
  echo ""
  
  # Get management key with validation
  echo -n "Enter management key (48-digit hex) [blank for default]: "
  read -s mgmt
  echo ""
  
  # Validate management key format if provided
  if [[ -n "$mgmt" ]]; then
    if [[ ! "$mgmt" =~ ^[0-9a-fA-F]{48}$ ]]; then
      echo "Error: Management key must be exactly 48 hexadecimal characters."
      echo "Format: 48 characters using only 0-9 and a-f (case insensitive)"
      return 1
    fi
  fi
  
  echo "Detected $N .pem files."
  echo "Available slots: ${slots[*]:0:$N}"
  echo ""
  
  for ((i=0; i<N; i++)); do
    local slot=${slots[i]}
    local key_file="key_$i.pem"
    
    if [[ ! -f "$key_file" ]]; then
      echo "Warning: $key_file not found, skipping..."
      continue
    fi
    
    echo "Importing $key_file to slot $slot..."
    
    # Build command with proper parameters
    local cmd="ykman piv keys import $slot $key_file --pin $pin"
    if [[ -n "$mgmt" ]]; then
      cmd="$cmd --management-key $mgmt"
    fi
    
    # Execute the import command
    if eval "$cmd"; then
      echo "✅ Successfully imported key $i to slot $slot"
    else
      echo "❌ Failed to import key $i to slot $slot"
      echo "Check that:"
      echo "  - YubiKey is connected and recognized"
      echo "  - PIN is correct"
      echo "  - Management key is correct (if provided)"
      echo "  - Key file $key_file is valid"
      return 1
    fi
    
    echo "---"
    sleep 1
  done
  
  echo "Import process completed!"
  echo ""
  echo "To verify imported keys:"
  echo "ykman piv keys list"
}

# Alternative function with interactive slot selection
function import_keys_to_yubikey_interactive() {
  local pem_files=(key_*.pem(N))
  local N=${#pem_files[@]}
  
  if [[ $N -eq 0 ]]; then
    echo "No key_*.pem files found in current directory."
    return 1
  fi
  
  echo "Found $N key files:"
  for ((i=0; i<N; i++)); do
    echo "  $i: key_$i.pem"
  done
  echo ""
  
  # Get PIN
  echo -n "Enter PIN for YubiKey: "
  read -s pin
  echo ""
  
  # Get management key
  echo -n "Enter management key (48-digit hex) [blank for default]: "
  read -s mgmt
  echo ""
  
  # Validate management key format if provided
  if [[ -n "$mgmt" ]] && [[ ! "$mgmt" =~ ^[0-9a-fA-F]{48}$ ]]; then
    echo "Error: Management key must be exactly 48 hexadecimal characters."
    return 1
  fi
  
  # Import each key with user-specified slot
  for ((i=0; i<N; i++)); do
    local key_file="key_$i.pem"
    
    echo "Available PIV slots: 9a, 9c, 9d, 9e, 82, 83, 84, 85"
    echo -n "Enter slot for $key_file (or 'skip' to skip): "
    read slot
    
    if [[ "$slot" == "skip" ]]; then
      echo "Skipping $key_file"
      continue
    fi
    
    # Validate slot format
    if [[ ! "$slot" =~ ^(9[a-e]|8[2-5])$ ]]; then
      echo "Invalid slot: $slot. Using default slot 9a."
      slot="9a"
    fi
    
    echo "Importing $key_file to slot $slot..."
    
    local cmd="ykman piv keys import $slot $key_file --pin $pin"
    if [[ -n "$mgmt" ]]; then
      cmd="$cmd --management-key $mgmt"
    fi
    
    if eval "$cmd"; then
      echo "✅ Successfully imported $key_file to slot $slot"
    else
      echo "❌ Failed to import $key_file to slot $slot"
    fi
    
    echo "---"
  done
}

#!/bin/bash

# View/List stored keys on YubiKey
function view_yubikey_keys() {
    echo "=== YubiKey PIV Keys Overview ==="
    echo ""
    
    # Basic key listing
    echo "📋 All PIV slots and their status:"
    ykman piv keys list
    echo ""
    
    # More detailed information about each slot
    echo "🔍 Detailed slot information:"
    ykman piv info
    echo ""
    
    # Check certificates (which correspond to keys)
    echo "📜 PIV certificates:"
    ykman piv certificates list
}

# Delete stored keys from YubiKey
function delete_yubikey_keys() {
    echo "=== Delete YubiKey PIV Keys ==="
    echo ""
    
    # Show current keys first
    echo "Current keys on YubiKey:"
    ykman piv keys list
    echo ""
    
    # Get PIN for authentication
    echo -n "Enter PIN for YubiKey: "
    read -s pin
    echo ""
    
    # Get management key if needed
    echo -n "Enter management key (48-digit hex) [blank for default]: "
    read -s mgmt
    echo ""
    
    echo "Choose deletion method:"
    echo "1. Delete specific slot"
    echo "2. Delete all keys (reset PIV application)"
    echo "3. Cancel"
    echo -n "Choice (1-3): "
    read choice
    
    case $choice in
        1)
            delete_specific_key "$pin" "$mgmt"
            ;;
        2)
            reset_piv_application "$pin" "$mgmt"
            ;;
        3)
            echo "Operation cancelled."
            return 0
            ;;
        *)
            echo "Invalid choice."
            return 1
            ;;
    esac
}

# Delete a specific key from a slot
function delete_specific_key() {
    local pin="$1"
    local mgmt="$2"
    
    echo -n "Enter slot to delete (9a, 9c, 9d, 9e, 82, 83, 84, 85): "
    read slot
    
    # Validate slot
    if [[ ! "$slot" =~ ^(9[a-e]|8[2-5])$ ]]; then
        echo "Invalid slot: $slot"
        return 1
    fi
    
    echo "⚠️  WARNING: This will permanently delete the key in slot $slot"
    echo -n "Type 'DELETE' to confirm: "
    read confirmation
    
    if [[ "$confirmation" != "DELETE" ]]; then
        echo "Operation cancelled."
        return 0
    fi
    
    # Build delete command
    local cmd="ykman piv keys delete $slot --pin $pin"
    if [[ -n "$mgmt" ]]; then
        cmd="$cmd --management-key $mgmt"
    fi
    
    if eval "$cmd"; then
        echo "✅ Successfully deleted key from slot $slot"
    else
        echo "❌ Failed to delete key from slot $slot"
        return 1
    fi
}

# Reset entire PIV application (deletes all keys and certificates)
function reset_piv_application() {
    local pin="$1"
    local mgmt="$2"
    
    echo "⚠️  WARNING: This will delete ALL PIV keys, certificates, and reset PIN/PUK!"
    echo "This action is IRREVERSIBLE!"
    echo -n "Type 'RESET-PIV' to confirm: "
    read confirmation
    
    if [[ "$confirmation" != "RESET-PIV" ]]; then
        echo "Operation cancelled."
        return 0
    fi
    
    if ykman piv reset; then
        echo "✅ PIV application has been reset"
        echo "ℹ️  Default PIN: 123456"
        echo "ℹ️  Default PUK: 12345678"
        echo "ℹ️  Default Management Key: 010203040506070801020304050607080102030405060708"
    else
        echo "❌ Failed to reset PIV application"
        return 1
    fi
}

# Retrieve/Export stored keys from YubiKey
function retrieve_yubikey_keys() {
    echo "=== Retrieve YubiKey PIV Keys ==="
    echo ""
    echo "ℹ️  Note: Private keys cannot be extracted from YubiKey (by design)"
    echo "You can only export public keys and certificates."
    echo ""
    
    # Show available certificates
    echo "Available certificates to export:"
    ykman piv certificates list
    echo ""
    
    echo "Choose what to retrieve:"
    echo "1. Export public key from specific slot"
    echo "2. Export certificate from specific slot"
    echo "3. Export all certificates"
    echo "4. Generate Certificate Signing Request (CSR)"
    echo "5. Cancel"
    echo -n "Choice (1-5): "
    read choice
    
    case $choice in
        1)
            export_public_key
            ;;
        2)
            export_certificate
            ;;
        3)
            export_all_certificates
            ;;
        4)
            generate_csr
            ;;
        5)
            echo "Operation cancelled."
            return 0
            ;;
        *)
            echo "Invalid choice."
            return 1
            ;;
    esac
}

# Export public key from specific slot
function export_public_key() {
    echo -n "Enter slot (9a, 9c, 9d, 9e, 82, 83, 84, 85): "
    read slot
    
    if [[ ! "$slot" =~ ^(9[a-e]|8[2-5])$ ]]; then
        echo "Invalid slot: $slot"
        return 1
    fi
    
    local output_file="yubikey_public_key_${slot}.pem"
    
    if ykman piv keys export $slot "$output_file"; then
        echo "✅ Public key exported to: $output_file"
        echo "📄 Key details:"
        openssl pkey -pubin -in "$output_file" -text -noout
    else
        echo "❌ Failed to export public key from slot $slot"
        return 1
    fi
}

# Export certificate from specific slot
function export_certificate() {
    echo -n "Enter slot (9a, 9c, 9d, 9e, 82, 83, 84, 85): "
    read slot
    
    if [[ ! "$slot" =~ ^(9[a-e]|8[2-5])$ ]]; then
        echo "Invalid slot: $slot"
        return 1
    fi
    
    local output_file="yubikey_certificate_${slot}.pem"
    
    if ykman piv certificates export $slot "$output_file"; then
        echo "✅ Certificate exported to: $output_file"
        echo "📄 Certificate details:"
        openssl x509 -in "$output_file" -text -noout
    else
        echo "❌ Failed to export certificate from slot $slot"
        return 1
    fi
}

# Export all certificates
function export_all_certificates() {
    local slots=(9a 9c 9d 9e 82 83 84 85)
    local exported_count=0
    
    for slot in "${slots[@]}"; do
        local output_file="yubikey_certificate_${slot}.pem"
        
        if ykman piv certificates export $slot "$output_file" 2>/dev/null; then
            echo "✅ Exported certificate from slot $slot to: $output_file"
            ((exported_count++))
        else
            echo "⏭️  No certificate in slot $slot, skipping..."
        fi
    done
    
    echo ""
    echo "📊 Exported $exported_count certificates total"
}

# Generate Certificate Signing Request
function generate_csr() {
    echo -n "Enter slot containing the key (9a, 9c, 9d, 9e, 82, 83, 84, 85): "
    read slot
    
    if [[ ! "$slot" =~ ^(9[a-e]|8[2-5])$ ]]; then
        echo "Invalid slot: $slot"
        return 1
    fi
    
    echo -n "Enter PIN for YubiKey: "
    read -s pin
    echo ""
    
    echo -n "Enter subject (e.g., '/CN=My Name/O=My Org/C=US'): "
    read subject
    
    local output_file="yubikey_csr_${slot}.pem"
    
    if ykman piv keys generate-csr $slot "$subject" "$output_file" --pin "$pin"; then
        echo "✅ CSR generated: $output_file"
        echo "📄 CSR details:"
        openssl req -in "$output_file" -text -noout
    else
        echo "❌ Failed to generate CSR"
        return 1
    fi
}

# Quick status check
function yubikey_piv_status() {
    echo "=== YubiKey PIV Quick Status ==="
    echo ""
    
    # Check if YubiKey is connected
    if ! ykman list 2>/dev/null | grep -q "YubiKey"; then
        echo "❌ No YubiKey detected"
        return 1
    fi
    
    echo "✅ YubiKey detected"
    echo ""
    
    # Show PIV info
    echo "📋 PIV Application Info:"
    ykman piv info
    echo ""
    
    # Count keys
    local key_count=$(ykman piv keys list 2>/dev/null | grep -c "Slot")
    echo "🔑 Total keys stored: $key_count"
    
    # Count certificates
    local cert_count=$(ykman piv certificates list 2>/dev/null | grep -c "Slot")
    echo "📜 Total certificates stored: $cert_count"
}

# Print usage information
function yubikey_help() {
    echo "=== YubiKey PIV Management Functions ==="
    echo ""
    echo "Available functions:"
    echo "  view_yubikey_keys         - List all keys and certificates"
    echo "  delete_yubikey_keys       - Delete specific keys or reset PIV"
    echo "  retrieve_yubikey_keys     - Export public keys/certificates"
    echo "  yubikey_piv_status        - Quick status overview"
    echo "  yubikey_help              - Show this help"
    echo ""
    echo "Quick commands:"
    echo "  ykman piv info            - Show PIV application info"
    echo "  ykman piv keys list       - List keys in slots"
    echo "  ykman piv certificates list - List certificates"
    echo ""
    echo "Slot meanings:"
    echo "  9a - PIV Authentication"
    echo "  9c - Digital Signature"
    echo "  9d - Key Management"
    echo "  9e - Card Authentication"
    echo "  82-85 - Retired Key Management slots"
}



# ================================================================================================

function yk_view_slots() {
  echo "=== YubiKey Slot Status ==="

  echo -n "Slot 1 (HOTP): "
  if ykman otp code 2>/dev/null | grep -q 'Slot 1'; then
    echo "Programmed (HOTP or similar)."
  else
    echo "Not responding or empty."
  fi

  echo -e "\nSlot 2 (Static Password or Custom Config):"
  echo "→ Please tap your YubiKey now to test static password output."
  echo "→ Suggested: Open a text editor and tap to see if a password appears."
  echo "(Note: Slot 2 cannot be queried programmatically.)"
}


# create_static_password 20
# to store it to a file for later: static_password > ~/.my_static_password.txt
function create_static_password() {
  local length=${1:-16}  # Default length 16 if not given
  # Generate a random password with uppercase, lowercase, digits, symbols
  # /dev/urandom filtered to acceptable chars
  LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()-_=+[]{}|;:,.<>?' < /dev/urandom | head -c "$length"
  echo
}

# zsh function to use YubiKey static password from slot 2
function yk_static_password() {
  echo "Please touch your YubiKey to input the static password..."
  # Wait for user to touch YubiKey, which will "type" the password into the terminal
  # The static password is sent as keyboard input, so capture it as input here
  read -rs password
  echo "Captured password: [hidden]"
  echo "Usage: '$password'"
  # You can now use $password for commands, e.g. login or passphrase input
  # Example: ssh user@host with password (requires sshpass)
  # sshpass -p "$password" ssh user@host
}

function yk_hmac_password() {
  echo "Please touch your YubiKey to input the static password..."
  local challenge=$(yk_static_password)
  # Convert challenge string to hex (because ykman expects hex input)
  local challenge_hex=$(echo -n "$challenge" | xxd -p)
  # Run ykman command with slot 2 and hex challenge
  local response=$(ykman otp chalresp 2 "$challenge_hex" | xxd -p -c 32)
  echo "Generated password: $response"
}


function check_gpg_status() {
  gpg --card-status | tee yubikey_gpg_status.txt
}

function for_each_yubikey() {
  ykman list --serials | while read -r serial; do
    echo "🔄 Working on YubiKey serial $serial"
    ykman --device "$serial" info
    echo "✅ Done with $serial"
  done
}

echo ""
: <<'NOTE_USAGE'
This will use the gpg key to sign.

yubikey_sign_file document.txt
yubikey_verify_signature document.txt document.txt.sig

"""
mark the key trusted?
gpg --edit-key C86E6C69492E9D3CA3AAC87C6EB0B4F3F74942E4

Then inside the prompt:
trust

Choose trust level:
5 = I trust ultimately
4 = I trust fully
3 = I trust marginally
2 = I do not trust
1 = I don’t know

Usually, choose 4 or 5 only if you fully trust the key.

Then:
`save``
"""

NOTE_USAGE
echo "" 

# Sign a file with GPG using the YubiKey OpenPGP key
function yubikey_sign_file() {
  if [[ -z "$1" ]]; then
    echo "Usage: yubikey_sign_file <file>"
    return 1
  fi
  local file="$1"
  gpg --output "${file}.sig" --detach-sign "$file" && echo "Signed $file -> ${file}.sig"
}

# Verify a signed file with its signature
function yubikey_verify_signature() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: yubikey_verify_signature <file> <signature>"
    return 1
  fi
  local file="$1"
  local sig="$2"
  gpg --verify "$sig" "$file"
}


echo ""
: <<'NOTE_USAGE'
ykman otp chalresp 2 <file> — programs slot 2 with the binary secret.
The slot must be either 1 or 2.
It expects the key as a binary file, not hex.
No --generate-key or --slot options — those are deprecated or incorrect.

# Provide a challenge and get the HMAC-SHA1 response
echo -n "mychallenge" | ykman otp calculate 2 -

Note: Challenge-response is only supported in slot 1 or slot 2 — so 3 is invalid.

✅ Uses raw binary for HMAC key
✅ Echoes the correct hex for your records
✅ Avoids base32 errors completely

NOTE_USAGE
echo "" 

function program_challenge_response() {
  local serial_number
  serial_number=$(ykman list --serials | head -n 1)

  if [[ -z "$serial_number" ]]; then
    echo "❌ No YubiKey detected."
    return 1
  fi

  echo "⚙️ Setting up HMAC-SHA1 challenge-response in slot 2 for YubiKey $serial_number"

  # Generate 20 random bytes (160 bits)
  local random_bytes_file
  random_bytes_file=$(mktemp)
  openssl rand 20 > "$random_bytes_file"

  # Convert binary to base32 (without padding)
  local base32_file
  base32_file=$(mktemp)
  base32 < "$random_bytes_file" | tr -d '=' | tr -d '\n' > "$base32_file"

  echo "🔐 Secret (base32):"
  cat "$base32_file"
  echo

  # Program secret into slot 2 (must be base32 encoded)
  ykman otp chalresp 2 "$base32_file"

  rm -f "$random_bytes_file" "$base32_file"

  echo "✅ Slot 2 programmed successfully."
}

echo ""
: <<'NOTE_USAGE'
ykman otp calculate 1 "test" && echo "Slot 1: PROGRAMMED" || echo "Slot 1: EMPTY"
ykman otp calculate 2 "test" && echo "Slot 2: PROGRAMMED" || echo "Slot 2: EMPTY"
NOTE_USAGE
echo "" 

function check_challenge_response_slots() {
  local serial_number
  serial_number=$(ykman list --serials | head -n 1)

  if [[ -z "$serial_number" ]]; then
    echo "❌ No YubiKey detected."
    return 1
  fi

  echo "🔍 Checking HMAC-SHA1 challenge-response slots on YubiKey $serial_number"

  for slot in 1 2; do
    if echo -n "test" | ykman --device "$serial_number" otp calculate "$slot" - &>/dev/null; then
      echo "✅ Slot $slot is PROGRAMMED"
    else
      echo "❌ Slot $slot is EMPTY"
    fi
  done
}


function reset_piv() {
  local serial_number
  serial_number=$(ykman list --serials | head -n 1)

  if [[ -z "$serial_number" ]]; then
    echo "❌ No YubiKey detected."
    return 1
  fi

  echo "🔄 reset_piv — With Warning & Confirm Step"
  echo "⚠️ WARNING: This will irreversibly erase all PIV keys and certificates on YubiKey $serial_number!"
  # read -p "❗ Type 'RESET' (uppercase) to confirm, or anything else to abort: " confirm
  read "confirm?❗ Type 'RESET' (uppercase) to confirm, or anything else to abort: "


  if [[ "$confirm" != "RESET" ]]; then
    echo "✅ Abort confirmed. Nothing was done."
    return 0
  fi

  echo "🔄 Resetting PIV on device $serial_number..."
  if ! ykman --device "$serial_number" piv reset; then
    echo "❌ Failed to reset PIV application on device $serial_number."
    return 1
  fi

  echo "✅ PIV application has been reset."
}



echo ""
: <<'NOTE_USAGE'

🧱 🔒 PIV Key + Cert Setup (Self-signed for SSH)
setup_piv_cert() {
  local serial_number=$(ykman list --serials | head -n 1)
  ykman --device "$serial_number" piv reset
  ykman --device "$serial_number" piv generate-key --algorithm RSA2048 9a pubkey.pem
  ykman --device "$serial_number" piv generate-certificate --subject "CN=YubiKey SSH" 9a pubkey.pem
  rm pubkey.pem
}

You can then use it via:
ssh-add -s /usr/local/lib/libykcs11.dylib

[TO-DO] Use Cases & How To
Install the tools:
- ykman (YubiKey Manager CLI) to manage configuration
- gpg for OpenPGP use
- openssl or ssh tools for PIV and authentication

A. Two-Factor Authentication (2FA) with FIDO2/U2F
Register your YubiKey with Google, GitHub, AWS, Microsoft, or other services supporting FIDO2.

Authenticate simply by touching the YubiKey after username/password.

B. Passwordless Login (FIDO2 / WebAuthn)
Enable passwordless sign-in on supported services.

Use NFC tap for mobile or USB-C for desktop.

C. OpenPGP Smartcard for GPG Signing/Encryption
Use the YubiKey’s onboard smartcard to generate or import OpenPGP keys.

Store private keys securely on the device.

Sign, encrypt, decrypt, or authenticate with gpg using the YubiKey.

Basic OpenPGP init:
gpg --card-status
gpg --edit-card

Quick Commands
View stored keys:
bash# Simple list
ykman piv keys list

# Detailed information
ykman piv info

# Use the comprehensive function
view_yubikey_keys
Delete stored keys:
bash# Delete specific slot
ykman piv keys delete 9a --pin [PIN]

# Reset entire PIV application (deletes everything)
ykman piv reset

# Use the interactive function
delete_yubikey_keys
Retrieve stored keys:
bash# Export public key
ykman piv keys export 9a public_key.pem

# Export certificate
ykman piv certificates export 9a certificate.pem

# Use the comprehensive function
retrieve_yubikey_keys
Important Notes

Private keys cannot be extracted from YubiKey - this is by design for security. You can only export:

Public keys
Certificates
Generate Certificate Signing Requests (CSRs)


PIV Slot meanings:

9a - PIV Authentication
9c - Digital Signature
9d - Key Management
9e - Card Authentication
82-85 - Retired Key Management slots


Backup considerations: Since private keys can't be extracted, make sure to:

Keep backups of your original private key files
Export certificates after importing keys
Document which keys are in which slots

NOTE_USAGE
echo "" 
