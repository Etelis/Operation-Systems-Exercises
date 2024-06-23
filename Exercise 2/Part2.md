
# Assignment: Implementing a Synchronization Lock for File Access

**Objective:**
To implement a synchronization lock for file access, ensuring that only one process writes to the file at a time while the others wait. This assignment will involve creating a dynamic number of child processes and using a separate file as a lock to control access.

## Instructions

### Task Description:

- Write a program that forks a dynamic number of child processes. All child processes should write to the same file in a specified order.
- Implement a synchronization mechanism using a lock file to ensure that only one process can write to the file at a time.
- The parent process should wait for all child processes to complete their writing.
- The program should accept input parameters to specify the messages and the number of times each process writes to the file.
- Save your program as `part2.c`.

### Requirements:

1. **File Creation:**
   - Use a separate lock file named `lockfile.lock`.

2. **Process Writing:**
   - Each child process should print a specified message to `stdout` a specified number of times using the provided `write_message` function.

3. **Synchronization Lock:**
   - Implement a locking mechanism using `lockfile.lock` to ensure that only one process can write to the file at a time.
   - Other processes must wait until the lock is released before they can write.
   - The idea is to create a lock file (`lockfile.lock`) that acts as a mutual exclusion (mutex) for file access:
     - **Acquiring the Lock:** When a process wants to write to the file, it first attempts to create the lock file. If the lock file already exists, it means another process is currently writing, so the process waits (e.g., using `usleep`) and retries until the lock file is available.
     - **Releasing the Lock:** After the process completes its writing, it deletes the lock file, signaling that other processes can now acquire the lock and write to the file.

4. **Forking and Writing:**
   - Fork a dynamic number of child processes based on input arguments.
   - ** First open the file needed for writing, and then fork the children in a loop, finally waiting for them ** 
   - The parent process should wait for all child processes to complete their writing.

5. **Error Handling:**
   - If a call to `fork`, `wait`, `sleep`, etc., fails, print an error message using `perror`.

6. **Command-Line Arguments:**
   - The program should accept command-line arguments to define:
     - The messages each process should write.
     - The number of times each process should write to the file.

7. **Output Redirection:**
   - Redirect the output of the program to a file named `output2.txt` using output redirection when running the program.

### Deliverables:

- Source code of the program saved as `part2.c`.

### Example Inputs and Expected Outputs:

1. **Example Input:**

   ```bash
   ./part2 "First message" "Second message" "Third message" 3 > output2.txt
   ```

2. **Expected Output in `output2.txt`:**

   ```
   First message
   First message
   First message
   Third message
   Third message
   Third message
   Second message
   Second message
   Second message
   ```

### Additional Details:

**Command-Line Argument Handling:**

Ensure the program accepts the necessary arguments for the messages(at least 3 messages), and the count of writes.

```c
if (argc <= 4) {
    fprintf(stderr, "Usage: %s <message1> <message2> ... <count>
", argv[0]);
    return 1;
}
```

**Locking Mechanism:**

Implement a simple locking mechanism using a lock file. Each process should create the lock file before writing and remove it after writing, ensuring mutual exclusion.

**Provided Function:**

You will use the provided `write_message` function to handle the printing with random delays.

```c
void write_message(const char *message, int count) {
    for (int i = 0; i < count; i++) {
        printf("%s\n", message);
        usleep((rand() % 100) * 1000); // Random delay between 0 and 99 milliseconds
    }
}
```
