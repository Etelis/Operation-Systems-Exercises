
# Assignment: Advanced Synchronization of File Access with Naive Methods

**Objective:**
To understand the challenges of synchronizing file access between parent and child processes using naive methods such as `wait` or `sleep`, with a more complex scenario involving multiple processes and varied writing patterns. The program should also handle input parameters for testing purposes.

## Instructions

### Task Description:

- Write a program that forks two child processes. Both the parent and the two child processes should write to the same file.
- Implement naive synchronization to ensure that the file writes do not interleave. You can use methods like `wait` or `sleep` to achieve this.
- The parent process should start writing only after both child processes have completed their writing.
- The program should accept input parameters to specify the messages and the number of times each process writes to the file.
- Save your program as `part1.c`.

### Requirements:

1. **File Creation:**
   - Create a file named `output.txt`.

2. **Process Writing:**
   - Each child process and the parent process should write a specified message to the file a specified number of times.

3. **Naive Synchronization:**
   - Ensure that the writes from the parent and child processes do not interleave using naive synchronization.
   - Use `wait` or `sleep` for synchronization. Do not use locks or sync mechanisms.

4. **Forking and Writing:**
   - You must initially fork both child processes before writing to the file.
   - Do not wait for one child process to finish before forking the second one.

5. **Error Handling:**
   - If a call to `fork`, `wait`, `sleep`, etc., fails, print an error message using `perror`.

6. **Command-Line Arguments:**
   - The program should accept command-line arguments to define:
     - The number of times each process should write to the file.
     - The message each process should write.

### Deliverables:

- Source code of the program saved as `part1.c`.

### Example Inputs and Expected Outputs:

1. **Example Input:**

```bash
   ./part1 "Parent message
" "Child1 message
" "Child2 message
" 3
```

2. **Expected Output in `output.txt`:**

   ```
   Child1 message
   Child1 message
   Child1 message
   Child2 message
   Child2 message
   Child2 message
   Parent message
   Parent message
   Parent message
   ```

### Additional Details:

**Command-Line Argument Handling:**

Ensure the program accepts four arguments: parent message, child1 message, child2 message, and the count of writes.

```c
if (argc != 5) {
    fprintf(stderr, "Usage: %s <parent_message> <child1_message> <child2_message> <count>
", argv[0]);
    return 1;
}
```
