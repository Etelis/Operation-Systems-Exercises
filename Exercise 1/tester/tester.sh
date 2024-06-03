#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_FILE="tests_config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Config file $CONFIG_FILE not found!${NC}"
    exit 1
fi

check_missing_files() {
    local OUTPUT_DIR=$1
    local EXPECTED_OUTPUT_DIR=$2
    MISSING_FILES=()
    for EXPECTED_FILE in "$EXPECTED_OUTPUT_DIR"/*; do
        FILE_NAME=$(basename "$EXPECTED_FILE")
        if [[ ! -f "$OUTPUT_DIR/$FILE_NAME" ]]; then
            MISSING_FILES+=("$FILE_NAME")
        fi
    done

    if [[ ${#MISSING_FILES[@]} -ne 0 ]]; then
        echo -e "${RED}Missing files: ${MISSING_FILES[*]}${NC}"
    else
        echo -e "${GREEN}All expected files are created.${NC}"
    fi
}

preprocess_file() {
    local FILE=$1
    sed '/^[[:space:]]*$/d' "$FILE" | tr -d '\n' | sed 's/[[:space:]]*$//'
}

compare_file_contents() {
    local OUTPUT_DIR=$1
    local EXPECTED_OUTPUT_DIR=$2
    CONTENT_MISMATCH=0
    for EXPECTED_FILE in "$EXPECTED_OUTPUT_DIR"/*; do
        FILE_NAME=$(basename "$EXPECTED_FILE")
        if [[ -f "$OUTPUT_DIR/$FILE_NAME" ]]; then
            EXPECTED_CONTENT=$(preprocess_file "$EXPECTED_FILE")
            OUTPUT_CONTENT=$(preprocess_file "$OUTPUT_DIR/$FILE_NAME")
            DIFF=$(diff <(echo "$EXPECTED_CONTENT") <(echo "$OUTPUT_CONTENT"))
            if [[ -n "$DIFF" ]]; then
                echo -e "${RED}Differences found in file $FILE_NAME:${NC}"
                echo "$DIFF"
                CONTENT_MISMATCH=1
            fi
        fi
    done

    if [[ $CONTENT_MISMATCH -eq 0 ]]; then
        echo -e "${GREEN}All file contents match the expected output.${NC}"
    fi
}

run_part_1_tests() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}          Beginning Tests for Part 1          ${NC}"
    echo -e "${CYAN}========================================${NC}"

    cd ..

    if [[ -f "split_pgn.sh" ]]; then
        SPLIT_SCRIPT="split_pgn.sh"
    elif [[ -f "pgn_split.sh" ]]; then
        SPLIT_SCRIPT="pgn_split.sh"
    else
        echo -e "${RED}No split script found (split_pgn.sh or pgn_split.sh)!${NC}"
        return
    fi

    chmod +x "$SPLIT_SCRIPT"
    cp "$SPLIT_SCRIPT" "$CURRENT_DIR"

    cd "$CURRENT_DIR"

    for TEST in $PART_1_TESTS; do
        INPUT=$(echo "$TEST" | jq -r '.input')
        OUTPUT_DIR=$(echo "$TEST" | jq -r '.output_dir')
        EXPECTED_OUTPUT_DIR=$(echo "$TEST" | jq -r '.expected_output_directory')

        echo -e "${YELLOW}----------------------------------------${NC}"
        echo -e "${YELLOW}Running test with input: ${BLUE}$INPUT${NC}"
        echo -e "${YELLOW}Output directory: ${BLUE}$OUTPUT_DIR${NC}"
        echo -e "${YELLOW}----------------------------------------${NC}"

        mkdir -p "$OUTPUT_DIR"

        echo -e "${BLUE}Running the split script...${NC}"
        if ! ./"$SPLIT_SCRIPT" "$INPUT" "$OUTPUT_DIR" > /dev/null 2>&1; then
            echo -e "${RED}Failed to run the split script${NC}"
            continue
        fi

        echo -e "${BLUE}Checking for missing files...${NC}"
        check_missing_files "$OUTPUT_DIR" "$EXPECTED_OUTPUT_DIR"

        echo -e "${BLUE}Comparing file contents...${NC}"
        compare_file_contents "$OUTPUT_DIR" "$EXPECTED_OUTPUT_DIR"

        echo -e "${BLUE}Cleaning up...${NC}"
        rm -r "$OUTPUT_DIR"

        echo -e "${YELLOW}----------------------------------------${NC}"
    done

    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}         Tests for Part 1 completed         ${NC}"
    echo -e "${CYAN}========================================${NC}\n\n"
}

run_part_2_tests() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}          Beginning Tests for Part 2          ${NC}"
    echo -e "${CYAN}========================================${NC}"

    cd ..

    if [[ -f "chess_sim.sh" ]]; then
        CHESS_SIM_SCRIPT="chess_sim.sh"
    else
        echo -e "${RED}No chess simulator script found (chess_sim.sh)!${NC}"
        return
    fi

    chmod +x "$CHESS_SIM_SCRIPT"
    cp "$CHESS_SIM_SCRIPT" "$CURRENT_DIR"

    cd "$CURRENT_DIR"

    for TEST in $PART_2_TESTS; do
        INPUT_PATH_PGN=$(echo "$TEST" | jq -r '.input_path_pgn')
        MOVES=$(echo "$TEST" | jq -r '.moves')
        EXPECTED_OUTPUT_WITHOUT_SPECIAL=$(echo "$TEST" | jq -r '.expected_output_without_special_moves')
        EXPECTED_OUTPUT_WITH_SPECIAL=$(echo "$TEST" | jq -r '.expected_output_with_special_moves')

        echo -e "${YELLOW}----------------------------------------${NC}"
        echo -e "${YELLOW}Running test with input: ${BLUE}$INPUT_PATH_PGN${NC}"
        echo -e "${YELLOW}Moves: ${BLUE}$MOVES${NC}"
        echo -e "${YELLOW}----------------------------------------${NC}"

        TEMP_DIR=$(mktemp -d)

        echo -e "${BLUE}Running the chess simulator script...${NC}"

        MOVES_WITH_ENTER=$(echo "$MOVES" | sed 's/./&\n/g')

        echo -e "$MOVES_WITH_ENTER" | ./"$CHESS_SIM_SCRIPT" "$INPUT_PATH_PGN" > "$TEMP_DIR/output.txt" 2>&1

        echo -e "${BLUE}Comparing output...${NC}"
        DIFF_WITHOUT_SPECIAL=$(diff -u <(preprocess_file "$TEMP_DIR/output.txt") <(preprocess_file "$EXPECTED_OUTPUT_WITHOUT_SPECIAL"))
        DIFF_WITH_SPECIAL=$(diff -u <(preprocess_file "$TEMP_DIR/output.txt") <(preprocess_file "$EXPECTED_OUTPUT_WITH_SPECIAL"))

        if [[ -z "$DIFF_WITHOUT_SPECIAL" ]]; then
            echo -e "${GREEN}Output matches the expected output without special moves.${NC}"
        elif [[ -z "$DIFF_WITH_SPECIAL" ]]; then
            echo -e "${GREEN}Output matches the expected output with special moves.${NC}"
            echo -e "${YELLOW}Bonus applied for special moves!${NC}"
        else
            echo -e "${RED}Output differs from both expected outputs:${NC}"
            if [[ -n "$DIFF_WITHOUT_SPECIAL" ]]; then
                echo -e "${RED}Differences with expected output without special moves:${NC}"
                echo "$DIFF_WITHOUT_SPECIAL"
            fi
            if [[ -n "$DIFF_WITH_SPECIAL" ]]; then
                echo -e "${RED}Differences with expected output with special moves:${NC}"
                echo "$DIFF_WITH_SPECIAL"
            fi
        fi

        echo -e "${BLUE}Cleaning up...${NC}"
        rm -r "$TEMP_DIR"

        echo -e "${YELLOW}----------------------------------------${NC}"
    done

    rm -f "$CHESS_SIM_SCRIPT"

    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}         Tests for Part 2 completed         ${NC}"
    echo -e "${CYAN}========================================${NC}\n\n"
}

CURRENT_DIR=$(pwd)

PART_1_TESTS=$(jq -c '.part_1[]' "$CONFIG_FILE")
PART_2_TESTS=$(jq -c '.part_2[]' "$CONFIG_FILE")

run_part_1_tests

run_part_2_tests
