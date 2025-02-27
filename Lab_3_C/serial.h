#ifndef SERIAL_H
#define SERIAL_H

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdarg.h>
#include <sleep.h>

#define UART1_CTRL_ADDR 0xE0001000
#define UART1_MODE_ADDR 0xE0001004
#define UART1_BAUDGEN_ADDR 0xE0001018
#define UART1_BAUDRATE_D_ADDR 0xE0001034
#define UART1_TRX_FIFO_ADDR 0xE0001030
#define UART1_INTERRUPT_EN_ADDR 0xE0001008
#define UART1_INTERRUPT_STAT_ADDR 0xE0001014

#define UART_STOP_BIT_1 0

#define UART_DATA_BITS_8 0

#define UART_PARITY_NONE 0b100

#define UART_BAUDRATE_9600 (uint32_t[]){0x7C, 83}
#define UART_BAUDRATE_115200 (uint32_t[]){0x7C, 6}

#define UART_TIMEOUT_MILLIS 100

void serial_init(uint32_t stop_bit, uint32_t data_bits, uint32_t parity, uint32_t baudrate[]);
void serial_print(char c_string[], ...);

#endif // SERIAL_H