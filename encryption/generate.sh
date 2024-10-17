#!/bin/bash

# Define filenames
KEYFILE="keyfile"
KEYFILE_KEY="keyfile.key"
KEYFILE_ENC="keyfile.enc"

# Check if keyfile already exists
if [[ -f $KEYFILE ]]; then
    echo "$KEYFILE already exists. Skipping generation."
else
    (echo -n '1;' ; openssl rand -hex 32 ) | sudo tee "$KEYFILE" > /dev/null
fi

# Check if keyfile.key already exists
if [[ -f $KEYFILE_KEY ]]; then
    echo "$KEYFILE_KEY already exists. Skipping generation."
else
    sudo openssl rand -hex 128 | sudo tee "$KEYFILE_KEY" > /dev/null
fi

# Check if keyfile.enc already exists
if [[ -f $KEYFILE_ENC ]]; then
    echo "$KEYFILE_ENC already exists. Skipping encryption."
else
    sudo openssl enc -aes-256-cbc -md sha1 -pass file:"$KEYFILE_KEY" -in "$KEYFILE" -out "$KEYFILE_ENC"
fi

# Remove unencrypted keyfile after encryption
sudo rm "$KEYFILE"

# Set permissions for the generated files
sudo chmod 640 "$KEYFILE"*  # Apply to all matching keyfile* files
