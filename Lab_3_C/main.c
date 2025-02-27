/*******************************************************************************
 * Programmer: Chris OFlaherty                                                 
 * Class: EE 234                                                               
 * Programming Assignment: Lab 3                                              
 * Date: February 26, 2025                                                     
 *                                                                            
 * Description: This program is a calculator that has 16 arithmetica/logical
 *              operations.  The calculator works with a hexidecimal keypad,
 *              slide switches, button 3, and the serial console as an output.                                  
 ******************************************************************************/

#include "serial.h"
#include <sleep.h>
#include <stdint.h>
#include <stdio.h>
#include "hexpad.h"
#include "switches.h"

void print_calculator_instructions();
int32_t get_operand();
int32_t get_opcode();
void print_opcode(uint32_t opcode);
int32_t calculate(uint32_t op1, uint32_t op2, uint32_t opcode, int32_t *storage);
int32_t count_zeros(uint32_t val);

int main(void)
{
    serial_init(UART_STOP_BIT_1, UART_DATA_BITS_8, UART_PARITY_NONE, UART_BAUDRATE_115200);
    hexpad_init();
    print_calculator_instructions();

    int32_t op1_val = -1;
    int32_t op2_val = -1;
    int32_t opcode = -1;
    int32_t result = 0;
    int32_t storage = 0; 

    while(1)
    {   
        serial_print("Enter opcode and press enter...\n");
        opcode = get_opcode();
        print_opcode(opcode);      
        serial_print(" opcode set.  Enter operands and press enter.\n");
                
        // Only get operands if opcode is not LOAD     
        if(opcode != 15)
        {
            op1_val = get_operand();
            serial_print("\t");     
            print_opcode(opcode);
            serial_print("\n");
            // Only get second operand for opcodes associated with 2 operands
            if(opcode < 12) op2_val = get_operand();
            // Only print the equals line if opcode is not store
            if(opcode != 14)
            {
                serial_print("\n----------\n");                
            }
            else 
            {
                serial_print("\n");
            }            
        }
        
        // Printing the opcode still needs to occur but at a different time for load operation
        if(opcode == 15) serial_print("LOAD\n");

        result = calculate(op1_val, op2_val, opcode, &storage);
        // Don't print result on a store operation
        if(opcode != 14) serial_print("%x\n\n", result);                                                 
    }
}

/************************************************************
 * Function: print_calculator_instructions
 * Description: Prints instructions on how to use the calculator
 *              to the serial console.
 * Input parameters: None
 * Returns: None
 ************************************************************/
void print_calculator_instructions()
{
    serial_print("\n\nWelcome to the 32-bit Calculator\n\n");    
    serial_print("1. Set switches to opcode and press enter.\n");   
    serial_print("2. Input first operand and press enter.\n");
    serial_print("3. Input second operand and press enter.\n\n");
}

/************************************************************
 * Function: get_operand
 * Description: Gets and prints hexpad presses until the enter
 *              button is pressed, and then returns the result.
 * Input parameters: None
 * Returns: int32_t - The operand value entered by the user.
 ************************************************************/
int32_t get_operand()
{
    bool enter_pressed = false;
    int32_t value = -1;
    int i = 0;       
     
    // Quickly checking pushbuttons and hexpad for user entries,
    // and escapes loop once btn3 (enter button) is pressed.
    while(!enter_pressed)
    {        
        int32_t hexkey = get_hexkey();

        if(hexkey >= 0 && i < 4)
        {
            serial_print("%x", hexkey);
            
            if(i) 
                value = value << 4;
            else
                value = 0;

            value |= hexkey;                       
            i++;
            
            msleep(250);            
        }

        if(get_buttons() & 0b1000)
        {
            enter_pressed = true;
            msleep(250);        
        }
    }

    return value;
}

/************************************************************
 * Function: get_opcode
 * Description: Gets the opcode from the switches and waits for
 *              the enter button to be pressed.
 * Input parameters: None
 * Returns: int32_t - The opcode value.
 ************************************************************/
int32_t get_opcode()
{
    bool enter_pressed = false;

    while(!enter_pressed)
    {
        enter_pressed = get_buttons() & 0b1000;
    }

    int32_t opcode = (0b1111 & get_switches());

    msleep(250);  

    return opcode;
}

/************************************************************
 * Function: print_opcode
 * Description: Prints the opcode to the serial console.
 * Input parameters: 
 *      - opcode: The opcode value to print.
 * Returns: None
 ************************************************************/
void print_opcode(uint32_t opcode)
{
    switch(opcode)
    {
        case 0:
        serial_print("+");
        break;

        case 1:
        serial_print("-");
        break;

        case 2:
        serial_print(" - (REVERSE SUBTRACT)");
        break;

        case 3:
        serial_print("x");
        break;
        
        case 4:
        serial_print("x (MULTIPLY + STORED)");
        break;

        case 5:
        serial_print("<<");
        break;

        case 6:
        serial_print(">>");
        break;

        case 7:
        serial_print("== (TEST EQUAL)"); 
        break;
              
        case 8:
        serial_print("AND");
        break;

        case 9:
        serial_print("OR");
        break;

        case 10:
        serial_print("XOR");
        break;

        case 11:
        serial_print("BIT CLEAR");
        break;

        case 12:
        serial_print("NOT");
        break;

        case 13:
        serial_print("COUNT ZEROS");
        break;

        case 14:
        serial_print("STORE");
        break;

        case 15:
        serial_print("LOAD");
        break;

        default:
        serial_print("Error");        
    }
}

/************************************************************
 * Function: calculate
 * Description: Performs the calculation based on the opcode and
 *              operands provided.
 * Input parameters: 
 *      - op1: The first operand.
 *      - op2: The second operand.
 *      - opcode: The opcode value.
 *      - storage: Pointer to the storage value.
 * Returns: int32_t - The result of the calculation.
 ************************************************************/
int32_t calculate(uint32_t op1, uint32_t op2, uint32_t opcode, int32_t *storage)
{
    int32_t result_val = 0;
    uint32_t sixteen_bit_mask = 0xFFFF;
    switch(opcode)
    {
        case 0:
        result_val = op1 + op2;
        break;

        case 1:
        result_val = op1 - op2;
        break;

        case 2:
        result_val = op2 - op1;
        break;

        case 3:
        result_val = op1 * op2;        
        break;

        case 4:
        result_val = op1 * op2 + *storage;      // Cumulative multiply
        break;

        case 5:
        result_val = op1 == op2;                // Test Equivalence        
        break;

        case 6:
        result_val = op1 << op2;
        break;

        case 7:
        result_val = op1 >> op2;              
        break;

        case 8:
        result_val = op1 & op2; 
        break;

        case 9:
        result_val = op1 | op2;        
        break;

        case 10:
        result_val = op1 ^ op2;                 // XOR        
        break;

        case 11:
        result_val = (op1 & ~op2) & sixteen_bit_mask;
        break;

        case 12:
        result_val = (~op1 & sixteen_bit_mask); 
        break;

        case 13:
        result_val = count_zeros(op1);
        break;

        case 14:
        *storage = op1;
        // serial_print("Value Stored = %x\n", *storage);     
        break;

        case 15:
        // serial_print("Loading value = %x\n", *storage);
        result_val = *storage;   
        break;       

        default:
        serial_print("Error");        
    }

    return result_val;
}

/************************************************************
 * Function: count_zeros
 * Description: Counts the number of leading zeros in a 16-bit
 *              value.
 * Input parameters: 
 *      - val: The value to count leading zeros in.
 * Returns: int32_t - The number of leading zeros.
 ************************************************************/
int32_t count_zeros(uint32_t val)
{
    uint32_t count = 0;
    uint32_t mask = 0x8000;   
    
    for(int i = 0; i < 16; i++)
    {
        if(!(val & (mask >> i))) 
        {
            count++;   
        }
        else 
        {
            return count;
        }            
    }

    return count;
}