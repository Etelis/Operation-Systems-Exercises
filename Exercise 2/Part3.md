# Buffered File I/O with O_PREAPPEND Flag

## Objective
To understand the implementation of a buffered I/O library in C, including support for a custom flag (`O_PREAPPEND`) that allows writing to the beginning of a file without overriding existing content. This exercise involves creating a wrapper for the original `open`, `write`, and `read` functions to achieve buffered reading and writing, with special handling for the `O_PREAPPEND` flag.

## Instructions

### Part 1: Implementing Buffered Functions

In this part, you will focus on implementing basic buffered reading and writing functionalities using separate buffers for read and write operations.

#### Task Description:

1. **Buffered File Structure**:
   - Use the `buffered_file_t` structure to manage the file descriptor, separate read and write buffers, their sizes, current positions within these buffers, and the flags.
   - 
2. **Buffered Open Function**:
   - Initialize the `buffered_file_t` structure with the file descriptor and allocate memory for both read and write buffers.
   - Remove the `O_PREAPPEND` flag from the flags before calling the original `open` function to avoid conflicts with standard file operations.

3. **Buffered Write Function**:
   - Write data to the write buffer.
   - **Flush the write buffer only when it is full** to ensure efficient use of system resources and reduce the number of write operations to the file.
   - If the write buffer does not have enough space for the new data, flush the buffer to the file first and then write the new data.

4. **Buffered Read Function**:
   - Read data from the read buffer if it contains data.
   - If the read buffer is empty, fill it by reading from the file descriptor and then provide the requested data from this buffer.
   - **Note**: Both buffers can be used to store the read and writes to the file, but students should remember to track the file offset in the open file table to ensure data consistency.

5. **Flush Function**:
   - Implement a flush function that writes any pending data in the write buffer to the file.
   - This function ensures that the file's content is updated with all buffered write operations.

6. **Close Function**:
   - Ensure that the close function handles both normal and abnormal program exits by flushing the write buffer to the file before closing the file descriptor.
   - This step is crucial to prevent data loss and ensure that all buffered writes are properly written to the file before the program terminates.

### Additional Notes:

- **Buffer Synchronization**:
  - Properly manage the transitions between reading and writing by keeping track of the last operation. If switching from writing to reading or vice versa, ensure the buffer state is correctly handled.
  - Always flush the write buffer when switching from writing to reading to maintain file consistency.

- **File Offset Management**:
  - Keep in mind the file offset maintained by the operating system in the open file table. Ensure that the file pointer is correctly updated after each read and write operation to maintain synchronization between the buffer and the actual file content.
  - 
### Part 2: Adding the O_PREAPPEND Logic

Now, let's add the logic for the `O_PREAPPEND` flag to support writing to the beginning of the file without overriding existing content.

#### Task Description:

1. **Buffered Write Function with O_PREAPPEND**:
   - If `O_PREAPPEND` is set, read the existing file content into a temporary buffer, write the new data at the beginning, and then append the existing content.

2. **Flush Function with O_PREAPPEND**:
   - Handle the logic for writing to the beginning of the file without overriding existing content when the buffer is flushed.

3. **Reading in Between**:
   - **Flush Before Reading:** Before performing any read operation, always flush the write buffer. This ensures that all pending data is written to the file in an append manner, adhering to the O_PREAPPEND logic. This flush operation ensures that the buffer's contents are correctly written to the file before any read occurs.
   - **Appending After Reads:** If a read is followed by a write operation, ensure that the write does not override the existing data at the current file position. Instead, handle the next write such that it is effectively appended at this position without disturbing the original content.
   - 
### Provided Header File (`buffered_open.h`)
```c
#ifndef BUFFERED_OPEN_H
#define BUFFERED_OPEN_H

#include <fcntl.h>
#include <unistd.h>

// Define a new flag that doesn't collide with existing flags
#define O_PREAPPEND 0x40000000

// Define the standard buffer size for read and write operations
#define BUFFER_SIZE 4096

// Structure to hold the buffer and original flags
typedef struct {
    int fd;                     // File descriptor for the opened file

    char *read_buffer;          // Buffer for reading operations, holds data read from the file
    char *write_buffer;         // Buffer for writing operations, holds data to be written to the file

    size_t read_buffer_size;    // Size of the read buffer, indicating how much data it can hold
    size_t write_buffer_size;   // Size of the write buffer, indicating how much data it can hold

    size_t read_buffer_pos;     // Current position in the read buffer, indicating the next byte to be read
    size_t write_buffer_pos;    // Current position in the write buffer, indicating the next byte to be written

    int flags;                  // File flags used to control file access modes and options (like O_RDONLY, O_WRONLY)

    int preappend;              // Flag to remember if the O_PREAPPEND flag was used, indicating special handling for writes
} buffered_file_t;

// Function to wrap the original open function
buffered_file_t *buffered_open(const char *pathname, int flags, ...);

// Function to write to the buffered file
ssize_t buffered_write(buffered_file_t *bf, const void *buf, size_t count);

// Function to read from the buffered file
ssize_t buffered_read(buffered_file_t *bf, void *buf, size_t count);

// Function to flush the buffer to the file
int buffered_flush(buffered_file_t *bf);

// Function to close the buffered file
int buffered_close(buffered_file_t *bf);

#endif // BUFFERED_OPEN_H

```

### Example Usage
Here's how your code should be used:

```c
#include "buffered_open.h"
#include <stdio.h>
#include <string.h>

int main() {
    buffered_file_t *bf = buffered_open("example.txt", O_WRONLY | O_CREAT | O_PREAPPEND, 0644);
    if (!bf) {
        perror("buffered_open");
        return 1;
    }

    const char *text = "Hello, World!";
    if (buffered_write(bf, text, strlen(text)) == -1) {
        perror("buffered_write");
        buffered_close(bf);
        return 1;
    }

    if (buffered_close(bf) == -1) {
        perror("buffered_close");
        return 1;
    }

    return 0;
}
```

### Error Handling
- Use `errno` to identify problems and provide meaningful error messages.
- Common errors include file open failures, buffer allocation issues, and read/write errors.
- Example:
  ```c
  buffered_file_t *bf = buffered_open("example.txt", O_WRONLY | O_CREAT | O_PREAPPEND, 0644);
  if (!bf) {
      perror("buffered_open");
      return 1;
  }
  ```
