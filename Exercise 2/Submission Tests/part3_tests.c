#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <assert.h>
#include "buffered_open.h"

#define BUFFER_SIZE_1 1024

void write_result(const char *test_name, const char *result) {
    FILE *output = fopen("part3_output.txt", "a");
    if (output == NULL) {
        perror("Error opening output file");
        exit(EXIT_FAILURE);
    }
    fprintf(output, "%s, %s\n", test_name, result);
    fclose(output);
}

void test_buffered_open() {
    const char *test_name = "TEST_BUFFERED_OPEN";
    buffered_file_t *bf = buffered_open("buffered_testfile.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    const char *write_data = "Hello, Buffered World!";
    int bytes_written = buffered_write(bf, write_data, strlen(write_data));
    if (bytes_written != strlen(write_data)) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    buffered_close(bf);

    bf = buffered_open("buffered_testfile.txt", O_RDONLY, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    char read_buffer[BUFFER_SIZE_1];
    int bytes_read = buffered_read(bf, read_buffer, strlen(write_data));
    if (bytes_read != strlen(write_data) || strcmp(read_buffer, write_data) != 0) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    write_result(test_name, "PASSED");
    buffered_close(bf);
}

void test_buffered_append() {
    const char *test_name = "TEST_BUFFERED_APPEND";
    // Initial write to file
    buffered_file_t *bf = buffered_open("buffered_testfile.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    const char *initial_data = "Hello, Buffered World!";
    int bytes_written = buffered_write(bf, initial_data, strlen(initial_data));
    if (bytes_written != strlen(initial_data)) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    buffered_close(bf);

    // Append to the file
    bf = buffered_open("buffered_testfile.txt", O_RDWR | O_APPEND, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    const char *append_data = " Append!";
    bytes_written = buffered_write(bf, append_data, strlen(append_data));
    if (bytes_written != strlen(append_data)) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    buffered_close(bf);

    // Read the entire content of the file
    bf = buffered_open("buffered_testfile.txt", O_RDONLY, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    char read_buffer[BUFFER_SIZE_1];
    int bytes_read = buffered_read(bf, read_buffer, BUFFER_SIZE_1 - 1);
    if (bytes_read <= 0 || strcmp(read_buffer, "Hello, Buffered World! Append!") != 0) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    write_result(test_name, "PASSED");
    buffered_close(bf);
}

void test_buffered_read_write() {
    const char *test_name = "TEST_BUFFERED_READ_WRITE";
    buffered_file_t *bf = buffered_open("buffered_testfile.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    const char *write_data = "Hello, Buffered World!";
    int bytes_written = buffered_write(bf, write_data, strlen(write_data));
    if (bytes_written != strlen(write_data)) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    // Flush buffer to ensure data is written to the file
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    // Close and reopen the file for reading
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    bf = buffered_open("buffered_testfile.txt", O_RDWR, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    char read_buffer[BUFFER_SIZE_1];
    int bytes_read = buffered_read(bf, read_buffer, 5);
    if (bytes_read != 5 || strncmp(read_buffer, "Hello", 5) != 0) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    // Close and reopen the file for appending
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    bf = buffered_open("buffered_testfile.txt", O_RDWR | O_APPEND, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    const char *append_data = " Append!";
    bytes_written = buffered_write(bf, append_data, strlen(append_data));
    if (bytes_written != strlen(append_data)) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    // Flush buffer to ensure data is written to the file
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    // Close and reopen the file for reading
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    bf = buffered_open("buffered_testfile.txt", O_RDONLY, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    bytes_read = buffered_read(bf, read_buffer, BUFFER_SIZE_1 - 1);
    if (bytes_read <= 0 || strcmp(read_buffer, "Hello, Buffered World! Append!") != 0) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    write_result(test_name, "PASSED");
    buffered_close(bf);
}


void test1() {
    const char *test_name = "TEST_1";
    const char *inputTest1 = "Test1";
    char readBuffer[1024] = {0};
    const char *expectedOutTest1 = "Test1";
    // Open file for writing
    buffered_file_t *bf = buffered_open("Test3Output.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    // Write text to the file
    if (buffered_write(bf, inputTest1, strlen(inputTest1)) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    // Flush the buffer
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    // Close the buffered file
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    // Reopen file for reading with standard I/O to verify contents
    int fd = open("Test3Output.txt", O_RDWR);
    if (fd == -1) {
        write_result(test_name, "FAILED");
        return;
    }
    ssize_t bytes_read = read(fd, readBuffer, sizeof(readBuffer) - 1);
    if (bytes_read == -1 || strcmp(readBuffer, expectedOutTest1) != 0) {
        write_result(test_name, "FAILED");
        close(fd);
        return;
    }

    write_result(test_name, "PASSED");
    close(fd);
}

void test2() {
    const char *test_name = "TEST_2";
    const char *inputTest2 = "Test2";
    char readBuffer[1024] = {0};
    const char *expectedOutTest2 = "Test2Test1";
    // Open file with preappend flag
    buffered_file_t *bf = buffered_open("Test3Output.txt", O_RDWR | O_PREAPPEND, 0);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    if (buffered_write(bf, inputTest2, strlen(inputTest2)) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    // Close the buffered file
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    // Reopen file for reading with standard I/O to verify contents
    int fd = open("Test3Output.txt", O_RDWR);
    if (fd == -1) {
        write_result(test_name, "FAILED");
        return;
    }
    ssize_t bytes_read = read(fd, readBuffer, sizeof(readBuffer) - 1);
    if (bytes_read == -1 || strcmp(readBuffer, expectedOutTest2) != 0) {
        write_result(test_name, "FAILED");
        close(fd);
        return;
    }

    write_result(test_name, "PASSED");
    close(fd);
}

void test3() {
    const char *test_name = "TEST_3";
    const char *inputTest3 = "Test3";
    char readBuffer[1024] = {0};
    const char *expectedOutTest3 = "Test2Test1Test3";
    // Open file without preappend flag
    buffered_file_t *bf = buffered_open("Test3Output.txt", O_RDWR | O_APPEND, 0);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    if (buffered_write(bf, inputTest3, strlen(inputTest3)) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    // Close the buffered file
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    // Reopen file for reading with standard I/O to verify contents
    int fd = open("Test3Output.txt", O_RDWR);
    if (fd == -1) {
        write_result(test_name, "FAILED");
        return;
    }
    ssize_t bytes_read = read(fd, readBuffer, sizeof(readBuffer) - 1);
    if (bytes_read == -1 || strcmp(readBuffer, expectedOutTest3) != 0) {
        write_result(test_name, "FAILED");
        close(fd);
        return;
    }

    write_result(test_name, "PASSED");
    close(fd);
}

void test4() {
    const char *test_name = "TEST_4";
    char readBuffer_file[1024] = {0};
    char readBuffer[1024] = {0};
    const char *expectedOutTest4_file = "Test2Test1Test3";
    const char *expectedOutTest4 = "Test";
    // Open file without preappend flag
    buffered_file_t *bf = buffered_open("Test3Output.txt", O_RDWR, 0);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }
    ssize_t bytes_read;
    bytes_read = buffered_read(bf, readBuffer, 4);
    if (bytes_read == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }

    // ======== TEST Empty flush ==========
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    // Reopen file for reading with standard I/O to verify contents
    int fd = open("Test3Output.txt", O_RDWR);
    if (fd == -1) {
        write_result(test_name, "FAILED");
        return;
    }
    ssize_t bytes_read_file = read(fd, readBuffer_file, sizeof(readBuffer_file) - 1);
    if (bytes_read_file == -1 || strcmp(readBuffer_file, expectedOutTest4_file) != 0) {
        write_result(test_name, "FAILED");
        close(fd);
        return;
    }
    // Close the buffered file
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    readBuffer[bytes_read] = '\0';  // Null-terminate the string
    if (strcmp(readBuffer, expectedOutTest4) != 0) {
        write_result(test_name, "FAILED");
        return;
    }

    write_result(test_name, "PASSED");
    close(fd);
}

void test5() {
    const char *test_name = "TEST_5";
    const char *inputTest5 = "Test5";
    char readBuffer[1024] = {0};
    const char *expectedOutTest5_1 = "Test5Test5Test5Test2Test1Test3";
    // Open file with preappend flag
    buffered_file_t *bf = buffered_open("Test3Output.txt", O_RDWR | O_PREAPPEND, 0);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    if (buffered_write(bf, inputTest5, strlen(inputTest5)) == -1 || 
        buffered_write(bf, inputTest5, strlen(inputTest5)) == -1 || 
        buffered_write(bf, inputTest5, strlen(inputTest5)) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    // Close the buffered file
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    // Reopen file for reading with standard I/O to verify contents
    int fd = open("Test3Output.txt", O_RDWR);
    if (fd == -1) {
        write_result(test_name, "FAILED");
        return;
    }
    ssize_t bytes_read = read(fd, readBuffer, sizeof(readBuffer) - 1);
    if (bytes_read == -1 || strcmp(readBuffer, expectedOutTest5_1) != 0) {
        write_result(test_name, "FAILED");
        close(fd);
        return;
    }
    close(fd);

    const char *expectedOutTest5_2 = "Test5Test5Test5Test2Test1Test3Test5Test5Test5Test5";
    bf = buffered_open("Test3Output.txt", O_RDWR | O_APPEND, 0);
    if (buffered_write(bf, inputTest5, strlen(inputTest5)) == -1 || 
        buffered_write(bf, inputTest5, strlen(inputTest5)) == -1 || 
        buffered_write(bf, inputTest5, strlen(inputTest5)) == -1 || 
        buffered_write(bf, inputTest5, strlen(inputTest5)) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    // Close the buffered file
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    // Reopen file for reading with standard I/O to verify contents
    fd = open("Test3Output.txt", O_RDWR);
    if (fd == -1) {
        write_result(test_name, "FAILED");
        return;
    }
    bytes_read = read(fd, readBuffer, sizeof(readBuffer) - 1);
    if (bytes_read == -1 || strcmp(readBuffer, expectedOutTest5_2) != 0) {
        write_result(test_name, "FAILED");
        close(fd);
        return;
    }

    write_result(test_name, "PASSED");
    close(fd);
}

void test6() {
    const char *test_name = "TEST_6";
    char readBuffer[1024] = {0};
    const char *expectedOutTest6 = "Test5Test5Test5Test2";
    buffered_file_t *bf = buffered_open("Test3Output.txt", O_RDWR, 0);
    if (bf == NULL) {
        write_result(test_name, "FAILED");
        return;
    }

    ssize_t bytes_read;
    bytes_read = buffered_read(bf, readBuffer, 5);
    if (bytes_read == -1 || 
        buffered_read(bf, readBuffer + 5, 5) == -1 || 
        buffered_read(bf, readBuffer + 10, 5) == -1 || 
        buffered_read(bf, readBuffer + 15, 5) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    if (buffered_flush(bf) == -1) {
        write_result(test_name, "FAILED");
        buffered_close(bf);
        return;
    }
    // Close the buffered file
    if (buffered_close(bf) == -1) {
        write_result(test_name, "FAILED");
        return;
    }

    readBuffer[20] = '\0';  // Null-terminate the string
    if (strcmp(readBuffer, expectedOutTest6) != 0) {
        write_result(test_name, "FAILED");
        return;
    }

    write_result(test_name, "PASSED");
}

int main() {
    // Clear the output file at the start of the test run
    FILE *output = fopen("part3_output.txt", "w");
    if (output != NULL) {
        fclose(output);
    }

    test_buffered_open();
    test_buffered_append();
    test_buffered_read_write();
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();

    return 0;
}
