import os
from os.path import isfile
import shutil
import pandas as pd
import subprocess

def run_tester(name, tester_script_path, testing_dir):
    # Ensure tester.sh has execute permissions
    print(f"Setting execute permissions for {tester_script_path}")
    subprocess.run(['chmod', '+x', tester_script_path], check=True)
    
    # Get the directory of the tester.sh script
    tester_dir = os.path.dirname(tester_script_path)
    print(f"Running tester.sh script in directory {tester_dir} for {name}")
    
    try:
        # Run the tester.sh script with the given name, with a timeout of 60 seconds
        subprocess.run([tester_script_path, name], check=True, cwd=tester_dir, timeout=300)
    except subprocess.TimeoutExpired:
        print(f"Tester script timed out for {name}")
        cleanup_testing_directory(testing_dir)
        return pd.DataFrame([[name, '0', '0', '0', '0', 'NO', 'Timeout']], 
                            columns=['ID', 'Part1 Score', 'Part2 Score', 'Part3 Score', 'Total Score', 'Bonus Received', 'Output'])
    
    # Open the output file and read its contents
    output_file = os.path.join(tester_dir, f"{name}.txt")
    print(f"Reading output from {output_file}")
    with open(output_file, 'r') as file:
        lines = file.readlines()
    
    # Parse the output
    part1_tests = []
    part2_tests = []
    special_tests = []
    is_special_bonus = False

    part1_started = part2_started = special_started = False

    for line in lines:
        line = line.strip()
        if line == "Part 1 Tests":
            part1_started = True
        elif line == "Part 1 Tests Completed":
            part1_started = False
        elif line == "Part 2 Tests":
            part2_started = True
        elif line == "Part 2 Tests Completed":
            part2_started = False
        elif line == "Part 2 Special Tests":
            special_started = True
        elif line == "Part 2 Special Tests Completed":
            special_started = False
        
        if part1_started and ("PASSED" in line or "FAILED" in line):
            if "PASSED" in line:
                part1_tests.append("PASSED")
            elif "FAILED" in line:
                part1_tests.append("FAILED")
        elif part2_started and line.startswith("FAILED"):
            part2_tests.append("FAILED")
        elif part2_started and line.startswith("PASSED"):
            part2_tests.append("PASSED")
        elif special_started and line.startswith("FAILED"):
            special_tests.append("FAILED")
        elif special_started and line.startswith("PASSED"):
            special_tests.append("PASSED")
        elif "BONUS: 10 points" in line:
            is_special_bonus = True

    part1_score = (33 / len(part1_tests)) * part1_tests.count("PASSED") if part1_tests else 0
    part2_score = (33 / len(part2_tests)) * part2_tests.count("PASSED") if part2_tests else 0
    
    total_score = part1_score + part2_score + (10 if is_special_bonus else 0)
    
    # Prepare the DataFrame row
    columns = ['ID', 'Part1 Score', 'Part2 Score', 'Total Score', 'Bonus Received', 'Output']
    data = [name, part1_score, part2_score, total_score, 'YES' if is_special_bonus else 'NO', ''.join(lines)]
    
    df_row = pd.DataFrame([data], columns=columns)
    return df_row

def save_results_to_csv(df, filename):
    print(f"Saving results to {filename}")
    df.to_csv(filename, index=False)

def cleanup_testing_directory(testing_dir):
    # Clean up the testing directory, but keep necessary files
    print(f"Cleaning up testing directory {testing_dir}")
    for filename in os.listdir(testing_dir):
        if filename not in ["chess_sim.py"]:
            file_path = os.path.join(testing_dir, filename)
            if os.path.isfile(file_path):
                os.remove(file_path)

def check_chess_sim_for_c_code(chess_sim_path):
    # Check for 'print' and other C patterns in chess_sim.sh
    print(f"Checking {chess_sim_path} for C code patterns")
    c_patterns = ['scanf', 'main', '#include', 'void']
    with open(chess_sim_path, 'r') as file:
        content = file.read()
        for pattern in c_patterns:
            if pattern in content:
                print(f"Pattern '{pattern}' found in {chess_sim_path}. Illegal usage detected.")
                return True
    return False


def process_students_and_run_tests(students_dir, testing_dir, tester_script_path, output_csv):
    # Prepare a list to collect DataFrame rows
    results = []

    # Iterate over each directory in the students_dir
    for student_dir in os.listdir(students_dir):
        student_path = os.path.join(students_dir, student_dir)
        if os.path.isdir(student_path):
            print(f"Processing student directory {student_path}")
            
            # Copy all files from the student directory to the testing directory
            for filename in os.listdir(student_path):
                file_path = os.path.join(student_path, filename)
                dest_path = os.path.join(testing_dir, filename)
                if os.path.isfile(file_path):
                    try:
                        print(f"Copying {file_path} to {dest_path}")
                        shutil.copy(file_path, dest_path)
                    except PermissionError as e:
                        print(f"Permission error: {e}. Skipping this file.")
                        continue
            
            # Get the student name without the "-0"
            student_name = student_dir.split('-')[0]
            
            # Run the tester for the student
            df_row = run_tester(student_name, tester_script_path, testing_dir)
            
            # Check if chess_sim.sh contains C code patterns
            chess_sim_path = os.path.join(testing_dir, 'chess_sim.sh')
            # Check if chess_sim.sh exists and contains C code patterns
            if os.path.isfile(chess_sim_path) and check_chess_sim_for_c_code(chess_sim_path):
                # Deduct 10 points and update the output
                df_row.loc[0, 'Total Score'] = max(0, df_row.loc[0, 'Total Score'] - 5)
                df_row.loc[0, 'Output'] += '\nIllegal usage of C code detected in chess_sim.sh. 10 points deducted.'
            cleanup_testing_directory(testing_dir)

            results.append(df_row)
    
    # Combine all DataFrame rows into a single DataFrame
    final_df = pd.concat(results, ignore_index=True)
    
    # Save the final DataFrame to a CSV file
    save_results_to_csv(final_df, output_csv)

    # Remove the directory named '2' inside the tester script path (if exists)
    dir_to_remove = os.path.join(os.path.dirname(tester_script_path), '2')
    if os.path.exists(dir_to_remove) and os.path.isdir(dir_to_remove):
        print(f"Removing directory {dir_to_remove}")
        shutil.rmtree(dir_to_remove)

    # Delete specific files from the tester.sh directory if they exist
    files_to_delete = ["chess_sim.py", "chess_sim.sh", "pgn_split.sh", "split_pgn.sh"]
    for file_name in files_to_delete:
        file_path = os.path.join(os.path.dirname(tester_script_path), file_name)
        if os.path.isfile(file_path):
            print(f"Deleting file {file_path}")
            os.remove(file_path)

# Example usage
students_dir = "/home/itay/Documents/OS_Exercises/Exercises/ex1"
testing_dir = "/home/itay/Documents/OS_Exercises/Tester/Ex1"
tester_script_path = "/home/itay/Documents/OS_Exercises/Tester/Ex1/tester/tester.sh"
testing_script_path_dir = "/home/itay/Documents/OS_Exercises/Tester/Ex1/tester"
output_csv = "test_results.csv"

process_students_and_run_tests(students_dir, testing_dir, tester_script_path, output_csv)