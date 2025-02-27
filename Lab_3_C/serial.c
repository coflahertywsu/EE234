#include "serial.h"
#include <sleep.h>

/************************************************************
 * Function: serial_init
 * Description: Initializes the UART with the specified 
 *              parameters.
 * Input parameters: 
 *      - stop_bit: Number of stop bits
 *      - data_bits: Number of data bits
 *      - parity: Parity setting
 *      - baudrate: Bauderate (Designed for MACRO)
 * Returns: None
 ************************************************************/
void serial_init(uint32_t stop_bit, uint32_t data_bits, uint32_t parity, uint32_t baudrate[])
{
    // Resetting transmitter/receiver and clearing FIFO buffer
    *((uint32_t*)UART1_CTRL_ADDR) = 0b11;

    int reset_pending = *((uint32_t*)UART1_CTRL_ADDR) & 0b11;

    while(reset_pending)
    {
        reset_pending = *((uint32_t*)UART1_CTRL_ADDR) & 0b11;
    }

    // Enabling TX and RX
    *((uint32_t*)UART1_CTRL_ADDR) = 0b10100;

    // Setting mode, stop bits, data bits, and parity
    *((uint32_t*)UART1_MODE_ADDR) = 0b0000100000 | 
                                    ((stop_bit & 0b11) << 6) | 
                                    ((data_bits & 0b11) << 1) |
                                    ((parity & 0b111) << 3);
        
    // Setting baudrate 
    *((uint32_t*)UART1_BAUDGEN_ADDR) = baudrate[0];
    *((uint32_t*)UART1_BAUDRATE_D_ADDR) = baudrate[1];

    // Enabling FIFO full and empty interrupts
    *((uint32_t*)UART1_INTERRUPT_EN_ADDR) = 0b11000;      
}

/************************************************************
 * Function: serial_print
 * Description: Prints a formatted string to the serial console.
 * Input parameters: 
 *      - c_string: The format string
 *      - ...: Additional arguments for the format string
 * Returns: None
 ************************************************************/
void serial_print(char c_string[], ...)
{
    // Parsing string to replace format specifiers with input args 
    char parsed_string[64];
    va_list args;
    va_start(args, c_string);
    vsnprintf(parsed_string, sizeof(parsed_string), c_string, args);
    va_end(args);

    char *string_iter = parsed_string;

    // Write characters to serial console until null character is reached
    while(*string_iter)
    {       
        // If fifo buffer is full wait until empty
        if(*(uint32_t*)UART1_INTERRUPT_STAT_ADDR & 0b10000)
        {
            // Clearing full flag
            *(uint32_t*)UART1_INTERRUPT_STAT_ADDR = *(uint32_t*)UART1_INTERRUPT_STAT_ADDR | 0b10000;

            uint32_t buffer_empyt = *(uint32_t*)UART1_INTERRUPT_STAT_ADDR & 0b1000;

            // Waiting until empty. May need to update with timeout if it causes freeze.
            while(!buffer_empyt)
            {
                msleep(10);
                buffer_empyt = *(uint32_t*)UART1_INTERRUPT_STAT_ADDR & 0b1000;
            }
        }
            
        // Write next element in char array to fifo buffer and increment to next element
        *((uint32_t*)UART1_TRX_FIFO_ADDR) = *string_iter;
        string_iter++;
    }
}