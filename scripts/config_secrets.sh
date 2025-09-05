# Set once: password and host
export SSH_HOST="<user_id>@<ip>"	# 
export SSH_PASS="<passcode>"		# 
export SSH_KEY="$HOME/ssh_keys/jumpbox_key" # jumpbox_key := <key.name>

# put (copy/install) the SSH key onto the VM so you can connect with key-based auth instead of a password.
# sshpass -p "$SSH_PASS" ssh-copy-id -i "$SSH_KEY.pub" "$SSH_HOST"
# or (if ssh-copy-id not installed)
# sshpass -p "$SSH_PASS" ssh "$SSH_HOST" "mkdir -p ~/.ssh && echo '$(cat $SSH_KEY.pub)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

## Create the directory if it doesn’t exist
#mkdir -p $HOME/ssh_keys

## Generate an RSA (or Ed25519) SSH keypair
## -f $HOME/ssh_keys/jumpbox_key → file name for the private key.
#ssh-keygen -t ed25519 -f $HOME/ssh_keys/jumpbox_key -C "jumpbox access"

## produces 2 files:
## jumpbox_key → private key (keep safe, permissions 600).
## jumpbox_key.pub → public key (add to ~/.ssh/authorized_keys on the VM).