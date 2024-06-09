# Assignment: Implementing a Directory Copy Library in C

**Objective:**
To implement a C library that provides functionalities similar to Python's `shutil.copytree`. This library will allow users to copy entire directory trees, including files and subdirectories, from a source location to a destination location, while handling symbolic links and file permissions as specified by flags.

## Instructions

### Task Description:

- Implement a C library to copy files and directories recursively from a source directory to a destination directory.
- The library should handle symbolic links and file permissions based on specified flags.
- You will be provided with a header file (`copytree.h`). Your task is to write the corresponding source file (`copytree.c`) and a main program (`main.c`) to utilize this library.

### Provided Header File (`copytree.h`):

```c
// copytree.h
#ifndef COPYTREE_H
#define COPYTREE_H

#ifdef __cplusplus
extern "C" {
#endif

void copy_file(const char *src, const char *dest, int copy_symlinks, int copy_permissions);
void copy_directory(const char *src, const char *dest, int copy_symlinks, int copy_permissions);

#ifdef __cplusplus
}
#endif

#endif // COPYTREE_H
```

### Requirements:

1. **File Copy Function (`copy_file`):**
   - Implement a function to copy a file from a source path to a destination path.
   - Handle symbolic links based on a flag (`copy_symlinks`).
   - Copy file permissions if a flag (`copy_permissions`) is set.
   - On error, print `perror("COMMAND failed")`.

2. **Directory Creation Function:**
   - Implement a helper function to create directories recursively, ensuring that all necessary parent directories are created.
   - On error, print `perror("COMMAND failed")`.

3. **Directory Copy Function (`copy_directory`):**
   - Implement a function to recursively copy a directory tree from a source path to a destination path.
   - Use the `copy_file` function to copy individual files.
   - Handle symbolic links and permissions as specified by the flags.
   - On error, print `perror("COMMAND failed")`.

4. **Error Handling:**
   - Implement robust error handling to ensure that errors are reported and handled appropriately.
   - Clean up any resources (e.g., file descriptors) in case of errors.

### Explanation of Flags:

- **`copy_symlinks` Flag:** When set to 1, the function should copy symbolic links as symbolic links rather than copying the content they point to.
- **`copy_permissions` Flag:** When set to 1, the function should copy the file permissions from the source file to the destination file.

### Main Program

Create a main program (`part4.c`) that uses your library to copy directories. The program should handle command-line arguments for the source and destination paths and optional flags for handling symbolic links and permissions.

#### Example Main Program (`part4.c`):

```c
#include "copytree.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void print_usage(const char *prog_name) {
    fprintf(stderr, "Usage: %s [-l] [-p] <source_directory> <destination_directory>
", prog_name);
    fprintf(stderr, "  -l: Copy symbolic links as links
");
    fprintf(stderr, "  -p: Copy file permissions
");
}

int main(int argc, char *argv[]) {
    int opt;
    int copy_symlinks = 0;
    int copy_permissions = 0;

    # HANDLE THE FLAGS HERE

    if (optind + 2 != argc) {
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }

    const char *src_dir = argv[optind];
    const char *dest_dir = argv[optind + 1];

    copy_directory(src_dir, dest_dir, copy_symlinks, copy_permissions);

    return 0;
}
```

### Testing the Library

To test your implementation, follow these steps:

1. **Set Up a Test Directory:**

   Create a directory structure like this in your source directory:

   ```
   source_directory/
   ├── file1.txt
   ├── file2.txt
   ├── subdir1/
   │   ├── file3.txt
   │   └── file4.txt
   └── subdir2/
       ├── file5.txt
       └── link_to_file1 -> ../file1.txt
   ```

2. **Compile and Run Your Program:**

   Compile your library and main program:

   ```sh
   gcc -c copytree.c -o copytree.o
   ar rcs libcopytree.a copytree.o
   gcc main.c -L. -lcopytree -o main_program
   ./main_program source_directory destination_directory
   ```

   To test with symbolic links and permissions:

   ```sh
   ./main_program -l -p source_directory destination_directory
   ```

3. **Verify the Results:**

   After running the program, the `destination_directory` should mirror the structure of `source_directory`.

4. **Handling Errors:**

   - If the program fails to open a file or directory, ensure that the paths are correct and you have the necessary permissions.
   - Check for symbolic link handling issues if the `-l` flag is used.
   - Make sure the destination directory does not already exist or is empty to avoid conflicts.