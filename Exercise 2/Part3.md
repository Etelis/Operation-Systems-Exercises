
# Assignment: Buffered File I/O with O_PREAPPEND Flag

**Objective:**
To understand the implementation of a buffered I/O library in C, including support for a custom flag (`O_PREAPPEND`) that allows writing to the beginning of a file without overriding existing content. This exercise involves creating a wrapper for the original `open`, `write`, and `read` functions to achieve buffered reading and writing, with special handling for the `O_PREAPPEND` flag.

## Instructions

### Part 1: Implementing Buffered Functions

In this part, you will focus on implementing basic buffered reading and writing functionalities.

#### Task Description:

1. **Buffered File Structure**: 
   - Use the `buffered_file_t` structure to manage the file descriptor, buffer, buffer size, buffer position, and flags.

2. **Buffered Open Function**:
   - Initialize the `buffered_file_t` structure.
   - Remove the `O_PREAPPEND` flag before calling the original `open` function.

3. **Buffered Write Function**:
   - Write data to the buffer.
   - Flush the buffer when it's full.

4. **Buffered Read Function**:
   - Read data from the buffer if available.
   - Read from the file descriptor if the buffer is empty.

5. **Flush Function**:
   - Write the buffered data to the file.

6. **Close Function**:
   - Flush the buffer and close the file descriptor.

### Part 2: Adding the O_PREAPPEND Logic

Now, let's add the logic for the `O_PREAPPEND` flag to support writing to the beginning of the file without overriding existing content.

#### Task Description:

1. **Buffered Write Function with O_PREAPPEND**:
   - If `O_PREAPPEND` is set, read the existing file content into a temporary buffer, write the new data at the beginning, and then append the existing content.

2. **Flush Function with O_PREAPPEND**:
   - Handle the logic for writing to the beginning of the file without overriding existing content when the buffer is flushed.

### Provided Header File (`buffered_open.h`)
```c
#ifndef BUFFERED_OPEN_H
#define BUFFERED_OPEN_H

#include <fcntl.h>
#include <unistd.h>

// Define a new flag that doesn't collide with existing flags
#define O_PREAPPEND 0x40000000

// Structure to hold the buffer and original flags
typedef struct {
    int fd;
    char *buffer;
    size_t buffer_size;
    size_t buffer_pos;
    int flags;
    int preappend; // flag to remember if O_PREAPPEND was used
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