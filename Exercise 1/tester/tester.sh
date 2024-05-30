#!/bin/bash

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if ! command -v jq &> /dev/null
then
    echo -e "${RED}jq could not be found. Please install jq manually and rerun the script.${NC}"
    echo "To install jq on Linux Mint, you can follow these steps:"
    echo "1. Update your package list: sudo apt update"
    echo "2. Install jq: sudo apt install jq -y"
    exit 1
fi

CONFIG_FILE="tests_config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file '$CONFIG_FILE' not found.${NC}"
    exit 1
fi

check_part_1() {
    local part="part_1"
    echo -e "${BLUE}Checking $part...${NC}"

    local test_count=$(jq ".${part} | length" "$CONFIG_FILE")
    for (( i=0; i<$test_count; i++ )); do
        local input=$(jq -r ".${part}[$i].input" "$CONFIG_FILE")
        local params=$(jq -r ".${part}[$i].params" "$CONFIG_FILE")
        local expected_dir=$(jq -r ".${part}[$i].expected_dir" "$CONFIG_FILE")
        local expected_tree=$(jq -r ".${part}[$i].expected_tree" "$CONFIG_FILE")
        local expected_output=$(jq -r ".${part}[$i].expected_output" "$CONFIG_FILE")

        echo -e "${YELLOW}Running test $((i+1))...${NC}"

        cd ..

        file1="split_pgn.sh"
        file2="pgn_split"

        if [ -f "$file1" ]; then
            cp "$file1" "$OLDPWD"
            script_to_run="$file1"
        elif [ -f "$file2" ]; then
            cp "$file2" "$OLDPWD"
            script_to_run="$file2"
        else
            echo -e "${RED}Error: Neither $file1 nor $file2 exists.${NC}"
            cd "$OLDPWD"
            return
        fi

        cd "$OLDPWD"

        if [ ! -f "$input" ]; then
            echo -e "${RED}Error: File '$input' does not exist.${NC}"
            return
        fi

        script_output=$(./"$script_to_run" "$input" "$params" 2>&1)

        if [ -d "$expected_dir" ]; then
            echo -e "${GREEN}Directory '$expected_dir' created successfully.${NC}"
            cd "$expected_dir"

            tree_output=$(tree)
            expected_tree_output=$(cat "../$expected_tree")

            if [ "$tree_output" == "$expected_tree_output" ]; then
                echo -e "${GREEN}Test $((i+1)) passed: Directory structure matches.${NC}"
            else
                echo -e "${RED}Test $((i+1)) failed: Directory structure does not match.${NC}"
                echo "Expected:"
                echo "$expected_tree_output"
                echo "Got:"
                echo "$tree_output"
            fi

            cd ..

            for file in "$expected_dir"/*; do
                if [ -f "$file" ]; then
                    expected_file="splited_pgns/$(basename "$file")"
                    if [ -f "$expected_file" ]; then
                        if diff -q -Z "$file" "$expected_file" > /dev/null; then
                            echo -e "${GREEN}File '$(basename "$file")' matches expected output.${NC}"
                        else
                            echo -e "${RED}File '$(basename "$file")' does not match expected output.${NC}"
                            echo "Differences:"
                            diff -Z "$file" "$expected_file"
                        fi
                    else
                        echo -e "${RED}Expected file '$(basename "$file")' does not exist.${NC}"
                    fi
                fi
            done

            expected_script_output=$(cat "$expected_output")
            if [ "$script_output" == "$expected_script_output" ]; then
                echo -e "${GREEN}Test $((i+1)) passed: Script output matches.${NC}"
            else
                echo -e "${RED}Test $((i+1)) failed: Script output does not match.${NC}"
                echo "Expected:"
                echo "$expected_script_output"
                echo "Got:"
                echo "$script_output"
            fi

            rm -rf "$expected_dir"
        else
            echo -e "${RED}Error: Directory '$expected_dir' was not created.${NC}"
        fi
    done

    rm -f "$script_to_run"
}


check_part_2() {
    local part="part_2"
    echo -e "${BLUE}Checking $part...${NC}"

    local test_count=$(jq ".${part} | length" "$CONFIG_FILE")
    for (( i=0; i<$test_count; i++ )); do
        local input=$(jq -r ".${part}[$i].input" "$CONFIG_FILE")
        local moves=$(jq -r ".${part}[$i].moves" "$CONFIG_FILE")
        local expected_output_ver1=$(jq -r ".${part}[$i].expected_output_ver1" "$CONFIG_FILE")
        local expected_output_ver2=$(jq -r ".${part}[$i].expected_output_ver2" "$CONFIG_FILE")
        
        echo -e "${YELLOW}Running test $((i+1))...${NC}"

        cd ..

        file="chess_sim.sh"

        if [ -f "$file" ]; then
            cp "$file" "$OLDPWD"
        else
            echo -e "${RED}Error: $file does not exist.${NC}"
            cd "$OLDPWD"
            continue
        fi

        cd "$OLDPWD"

        if [ ! -f "$input" ]; then
            echo -e "${RED}Error: File '$input' does not exist.${NC}"
            continue
        fi

        output_dir="tests/part_2_test_outputs"
        mkdir -p "$output_dir"
        temp_output_file="${output_dir}/part_2_test_capmemel24_$((i+1))_output.txt"

        # Adding delay to ensure the program has enough time to process inputs
        echo "$moves" | ./chess_sim.sh "$input" > "$temp_output_file" 2>&1
        sleep 0.5  # Adjust the delay as needed

        if ( [ -n "$expected_output_ver1" ] && [ -f "$expected_output_ver1" ] && diff -q -Z "$temp_output_file" "$expected_output_ver1" > /dev/null ) || 
           ( [ -n "$expected_output_ver2" ] && [ -f "$expected_output_ver2" ] && diff -q -Z "$temp_output_file" "$expected_output_ver2" > /dev/null ); then
            if [ -n "$expected_output_ver1" ] && [ -f "$expected_output_ver1" ] && diff -q -Z "$temp_output_file" "$expected_output_ver1" > /dev/null; then
                echo -e "${GREEN}Test $((i+1)) passed: I see you implemented the special moves! Good job.${NC}"
            else
                echo -e "${GREEN}Test $((i+1)) passed.${NC}"
            fi
        else
            echo -e "${RED}Test $((i+1)) failed.${NC}"
            if [ -n "$expected_output_ver1" ] && [ -f "$expected_output_ver1" ]; then
                echo -e "${YELLOW}Differences with expected_output_ver1:${NC}"
                diff -u -Z --color "$temp_output_file" "$expected_output_ver1"
            fi
            if [ -n "$expected_output_ver2" ] && [ -f "$expected_output_ver2" ]; then
                echo -e "${YELLOW}Differences with expected_output_ver2:${NC}"
                diff -u -Z --color "$temp_output_file" "$expected_output_ver2"
            fi
            read -p "Press Enter to continue to the next test..."
        fi

        rm -f "$temp_output_file"
    done

    rm -f "chess_sim.sh"
}



while true; do
    echo -e "${BLUE}Select an option:${NC}"
    echo "1. Check part 1"
    echo "2. Check part 2"
    echo "3. Exit"

    read -p "Enter your choice: " choice

    case $choice in
        1) check_part_1 ;;
        2) check_part_2 ;;
        3) echo -e "${BLUE}Exiting.${NC}"; break ;;
        *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
    esac
done
