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

OUTPUT_NAME=$1
OUTPUT_FILE="${OUTPUT_NAME}.txt"

# Ensure the script has permission to create and write to the output file
if ! touch "$OUTPUT_FILE" 2>/dev/null; then
    echo -e "${RED}Cannot create or write to file $OUTPUT_FILE. Permission denied!${NC}"
    exit 1
fi

> "$OUTPUT_FILE"

log_result() {
    echo "$1" >> "$OUTPUT_FILE"
}

check_missing_files() {
    local OUTPUT_DIR=$1
    local EXPECTED_OUTPUT_DIR=$2
    for EXPECTED_FILE in "$EXPECTED_OUTPUT_DIR"/*; do
        FILE_NAME=$(basename "$EXPECTED_FILE")
        if [[ ! -f "$OUTPUT_DIR/$FILE_NAME" ]]; then
            return 1
        fi
    done
    return 0
}

preprocess_file() {
    local FILE=$1
    iconv -f "$(file -bi "$FILE" | sed -e 's/.*[ ]charset=//')" -t UTF-8 "$FILE" | sed -e 's/\r$//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]\+/ /g' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' | sed -e '$a\'
}

compare_file_contents() {
    local OUTPUT_DIR=$1
    local EXPECTED_OUTPUT_DIR=$2
    for EXPECTED_FILE in "$EXPECTED_OUTPUT_DIR"/*; do
        FILE_NAME=$(basename "$EXPECTED_FILE")
        if [[ -f "$OUTPUT_DIR/$FILE_NAME" ]]; then
            EXPECTED_CONTENT=$(preprocess_file "$EXPECTED_FILE")
            OUTPUT_CONTENT=$(preprocess_file "$OUTPUT_DIR/$FILE_NAME")
            DIFF=$(diff <(echo "$EXPECTED_CONTENT") <(echo "$OUTPUT_CONTENT"))
            if [[ -n "$DIFF" ]]; then
                return 1
            fi
        else
            return 1
        fi
    done
    return 0
}

run_part_1_tests() {
    log_result "Part 1 Tests"
    cd ..

    if [[ -f "split_pgn.sh" ]]; then
        SPLIT_SCRIPT="split_pgn.sh"
    elif [[ -f "pgn_split.sh" ]]; then
        SPLIT_SCRIPT="pgn_split.sh"
    else
        return
    fi

    chmod +x "$SPLIT_SCRIPT"
    cp "$SPLIT_SCRIPT" "$CURRENT_DIR"

    cd "$CURRENT_DIR"

    if [[ $SHELL == *"cbash"* ]]; then
        sed -i 's|#!/bin/bash|#!/bin/cbash|' "$SPLIT_SCRIPT"
    fi

    for TEST in $PART_1_TESTS; do
        INPUT=$(echo "$TEST" | jq -r '.input')
        OUTPUT_DIR=$(echo "$TEST" | jq -r '.output_dir')
        EXPECTED_OUTPUT_DIR=$(echo "$TEST" | jq -r '.expected_output_directory')

        mkdir -p "$OUTPUT_DIR"

        if ! ./"$SPLIT_SCRIPT" "$INPUT" "$OUTPUT_DIR" > /dev/null 2>&1; then
            log_result "FAILED"
            continue
        fi

        if ! check_missing_files "$OUTPUT_DIR" "$EXPECTED_OUTPUT_DIR"; then
            log_result "FAILED"
            rm -r "$OUTPUT_DIR"
            continue
        fi

        if ! compare_file_contents "$OUTPUT_DIR" "$EXPECTED_OUTPUT_DIR"; then
            log_result "FAILED"
        else
            log_result "PASSED"
        fi

        rm -r "$OUTPUT_DIR"
    done

    rm -f "$SPLIT_SCRIPT"
    log_result "Part 1 Tests Completed"
}

run_part_2_tests() {
    log_result "Part 2 Tests"
    cd ..

    if [[ -f "chess_sim.sh" ]]; then
        CHESS_SIM_SCRIPT="chess_sim.sh"
    else
        log_result "No chess simulator script found!"
        return
    fi

    if [[ -f "chess_sim.py" ]]; then
        CHESS_SIM_PY="chess_sim.py"
    else
        log_result "No chess simulator script found!"
        return
    fi

    chmod +x "$CHESS_SIM_SCRIPT"
    cp "$CHESS_SIM_SCRIPT" "$CURRENT_DIR"
    cp "$CHESS_SIM_PY" "$CURRENT_DIR"

    cd "$CURRENT_DIR"

    if [[ $SHELL == *"cbash"* ]]; then
        sed -i 's|#!/bin/bash|#!/bin/cbash|' "$CHESS_SIM_SCRIPT"
    fi

    TEST_NUM=0

    for TEST in $PART_2_TESTS; do
        ((TEST_NUM++))
        INPUT_PATH_PGN=$(echo "$TEST" | jq -r '.input_path_pgn')
        MOVES=$(echo "$TEST" | jq -r '.moves')

        TEMP_DIR=$(mktemp -d)

        MOVES_WITH_ENTER=$(echo "$MOVES" | sed 's/./&\n/g')

        echo -e "$MOVES_WITH_ENTER" | ./"$CHESS_SIM_SCRIPT" "$INPUT_PATH_PGN" > "$TEMP_DIR/student_output.txt" 2>&1
        echo -e "$MOVES_WITH_ENTER" | python3 "$CHESS_SIM_PY" "$INPUT_PATH_PGN" > "$TEMP_DIR/expected_output.txt" 2>&1

        DIFF=$(diff -u "$TEMP_DIR/student_output.txt" "$TEMP_DIR/expected_output.txt")

        if [[ -z "$DIFF" ]]; then
            log_result "PASS"
        else
            log_result "FAIL: $INPUT_PATH_PGN"
            FAIL_DIR="fails/test_$TEST_NUM"
            mkdir -p "$FAIL_DIR"
            cp "$TEMP_DIR/student_output.txt" "$FAIL_DIR/student_output.txt"
            cp "$TEMP_DIR/expected_output.txt" "$FAIL_DIR/expected_output.txt"
        fi

        rm -r "$TEMP_DIR"
    done

    rm -f "$CHESS_SIM_SCRIPT"
    rm -f "$CHESS_SIM_PY"
    log_result "Part 2 Tests Completed"
}

run_part_2_special_tests() {
    log_result "Part 2 Special Tests"
    cd ..

    if [[ -f "chess_sim.sh" ]]; then
        CHESS_SIM_SCRIPT="chess_sim.sh"
    else
        log_result "No chess simulator script found!"
        return
    fi

    if [[ -f "chess_sim.py" ]]; then
        CHESS_SIM_PY="chess_sim.py"
    else
        log_result "No chess simulator script found!"
        return
    fi

    chmod +x "$CHESS_SIM_SCRIPT"
    cp "$CHESS_SIM_SCRIPT" "$CURRENT_DIR"
    cp "$CHESS_SIM_PY" "$CURRENT_DIR"

    cd "$CURRENT_DIR"

    if [[ $SHELL == *"cbash"* ]]; then
        sed -i 's|#!/bin/bash|#!/bin/cbash|' "$CHESS_SIM_SCRIPT"
    fi

    TEST_NUM=0
    ALL_PASSED=1

    for TEST in $PART_2_SPECIAL_TESTS; do
        ((TEST_NUM++))
        INPUT_PATH_PGN=$(echo "$TEST" | jq -r '.input_path_pgn')
        MOVES=$(echo "$TEST" | jq -r '.moves')

        TEMP_DIR=$(mktemp -d)

        MOVES_WITH_ENTER=$(echo "$MOVES" | sed 's/./&\n/g')

        echo -e "$MOVES_WITH_ENTER" | ./"$CHESS_SIM_SCRIPT" "$INPUT_PATH_PGN" > "$TEMP_DIR/student_output.txt" 2>&1
        echo -e "$MOVES_WITH_ENTER" | python3 "$CHESS_SIM_PY" "$INPUT_PATH_PGN" > "$TEMP_DIR/expected_output.txt" 2>&1

        DIFF=$(diff -u "$TEMP_DIR/student_output.txt" "$TEMP_DIR/expected_output.txt")

        if [[ -z "$DIFF" ]]; then
            log_result "PASS"
        else
            log_result "FAIL: $INPUT_PATH_PGN"
            ALL_PASSED=0
            FAIL_DIR="fails/test_special_$TEST_NUM"
            mkdir -p "$FAIL_DIR"
            cp "$TEMP_DIR/student_output.txt" "$FAIL_DIR/student_output.txt"
            cp "$TEMP_DIR/expected_output.txt" "$FAIL_DIR/expected_output.txt"
        fi

        rm -r "$TEMP_DIR"
    done

    rm -f "$CHESS_SIM_SCRIPT"
    rm -f "$CHESS_SIM_PY"

    if [[ $ALL_PASSED -eq 1 ]]; then
        log_result "BONUS: 10 points"
    fi

    log_result "Part 2 Special Tests Completed"
}

CURRENT_DIR=$(pwd)

PART_1_TESTS=$(jq -c '.part_1[]' "$CONFIG_FILE")
PART_2_TESTS=$(jq -c '.part_2[]' "$CONFIG_FILE")
PART_2_SPECIAL_TESTS=$(jq -c '.part_2_special[]' "$CONFIG_FILE")

run_part_1_tests

run_part_2_tests

run_part_2_special_tests
