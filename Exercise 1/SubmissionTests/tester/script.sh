#!/bin/bash

# Function to process .pgn files and convert EOL characters to \n
process_pgn_file() {
    local FILE="$1"
    # Convert EOL characters to \n and overwrite the file
    sed -i 's/\r$//' "$FILE"
}

# Export the function so it can be used by find -exec
export -f process_pgn_file

# Find all .pgn files in the current directory and subdirectories, then process them
find . -type f -name "*.pgn" -exec bash -c 'process_pgn_file "$0"' {} \;

echo "EOL characters in all .pgn files have been revised to \n."
