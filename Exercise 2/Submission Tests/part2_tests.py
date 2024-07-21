import subprocess
import json
import time
import re
from collections import Counter
import os

def check_code(c_file):
    with open(c_file, 'r') as file:
        code = file.read()
        if re.search(r'\bmmap\b|\bflock\b', code, re.IGNORECASE):
            return False
    return True

def compile_c_file(c_file, output_file):
    try:
        subprocess.run(['gcc', c_file, '-o', output_file], check=True, stderr=subprocess.PIPE)
        return True
    except subprocess.CalledProcessError:
        return False

def run_test(executable, test, test_number):
    args = [executable] + [f'"{arg}"' if ' ' in arg else arg for arg in test['args']]
    command = ' '.join(args)
    try:
        result = subprocess.run(command, check=True, capture_output=True, shell=True, timeout=50)
        output = result.stdout.decode().strip().split('\n')
        
        # Check if the output file exists
        if os.path.exists('output2.txt'):
            with open('output2.txt', 'r') as file:
                output = file.read().strip().split('\n')

        output_count = len(output)
        output_counter = Counter(output)

        expected_count = test['expected_count']
        expected_messages = test['expected_messages']

        if output_count == expected_count and all(output_counter[msg] == expected_count // len(expected_messages) for msg in expected_messages):
            return f"TEST_{test_number}, PASSED"
        else:
            return f"TEST_{test_number}, FAILED"

    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return f"TEST_{test_number}, FAILED"

def run_tests(executable, config_file):
    results = []
    start_time = time.time()

    with open(config_file, 'r') as f:
        config = json.load(f)
    
    for i, test in enumerate(config['tests'], start=1):
        elapsed_time = time.time() - start_time
        if elapsed_time > 50:
            results.extend([f"TEST_{j}, FAILED" for j in range(i, len(config['tests']) + 1)])
            break
        result = run_test(executable, test, i)
        results.append(result)
    
    return results

def main():
    c_file = 'part2.c'
    output_file = 'part2'
    config_file = 'config.json'
    output_results_file = 'part2_output.txt'

    if not check_code(c_file):
        results = ["TEST_ILEGAL_USAGE" for _ in range(len(json.load(open(config_file))['tests']))]
    elif compile_c_file(c_file, output_file):
        results = run_tests(f'./{output_file}', config_file)
    else:
        results = ["Compilation failed"]

    with open(output_results_file, 'w') as f:
        for result in results:
            f.write(result + '\n')

    for result in results:
        print(result)

if __name__ == "__main__":
    main()
