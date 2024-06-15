#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <errno.h>

#define BAUDRATE B500000
#define CHUNK_SIZE 8192

void send_binary_file_over_uart(const char *file_path, const char *uart_port) {
    int file_fd, uart_fd;
    struct termios options;
    unsigned char buffer[CHUNK_SIZE];
    ssize_t bytes_read, bytes_written;

    // Open the binary file in read-only mode
    file_fd = open(file_path, O_RDONLY);
    if (file_fd < 0) {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }

    // Open the UART port
    uart_fd = open(uart_port, O_RDWR | O_NOCTTY | O_SYNC);
    if (uart_fd < 0) {
        perror("Error opening UART port");
        close(file_fd);
        exit(EXIT_FAILURE);
    }

    // Get current UART port settings
    if (tcgetattr(uart_fd, &options) != 0) {
        perror("Error getting UART attributes");
        close(file_fd);
        close(uart_fd);
        exit(EXIT_FAILURE);
    }

    // Set baud rate
    cfsetospeed(&options, BAUDRATE);
    cfsetispeed(&options, BAUDRATE);

    // Configure UART settings
    options.c_cflag = (options.c_cflag & ~CSIZE) | CS8; // 8 data bits
    options.c_iflag &= ~IGNBRK; // Disable break processing
    options.c_lflag = 0; // No signaling chars, no echo, no canonical processing
    options.c_oflag = 0; // No remapping, no delays
    options.c_cc[VMIN] = 1; // Read at least 1 character
    options.c_cc[VTIME] = 1; // 0.1 seconds read timeout

    options.c_cflag |= (CLOCAL | CREAD); // Enable receiver and set local mode
    options.c_cflag &= ~(PARENB | PARODD); // No parity
    options.c_cflag &= ~CSTOPB; // 1 stop bit
    options.c_cflag &= ~CRTSCTS; // No hardware flow control

    // Apply the UART settings
    if (tcsetattr(uart_fd, TCSANOW, &options) != 0) {
        perror("Error setting UART attributes");
        close(file_fd);
        close(uart_fd);
        exit(EXIT_FAILURE);
    }

    // Read the binary file in chunks and send each chunk over UART
    while ((bytes_read = read(file_fd, buffer, CHUNK_SIZE)) > 0) {
        bytes_written = write(uart_fd, buffer, bytes_read);
        if (bytes_written < 0) {
            perror("Error writing to UART port");
            close(file_fd);
            close(uart_fd);
            exit(EXIT_FAILURE);
        }
        printf("Sent %zd bytes\n", bytes_written);
    }

    if (bytes_read < 0) {
        perror("Error reading file");
    }

    // Close file and UART port
    close(file_fd);
    close(uart_fd);

    printf("File sent successfully.\n");
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <file_path> <uart_port>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    send_binary_file_over_uart(argv[1], argv[2]);

    return 0;
}
