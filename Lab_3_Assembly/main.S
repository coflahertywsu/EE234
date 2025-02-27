@****************************************************************************
@  Programmer: Chris OFlaherty                                                 
@  Class: EE 234                                                               
@  Programming Assignment: Lab 3                                              
@  Date: February 26, 2025                                                     
@                                                                             
@  Description: This program is a calculator that has 16 arithmetica/logical
@               operations.  The calculator works with a hexidecimal keypad,
@               slide switches, button 3, and the serial console as an output.                                      
@*****************************************************************************

.global main
.include "../src/serial.S"
.include "../src/hexpad.S"
.include "../src/timers.S"
.include "../src/switches.S"

.data
    operand_storage: .word 0

    instruction1_text: .asciz "\n1. Select OpCode, Press Enter.\n"
    instruction2_text: .asciz "2. Input 1st Value, Press Enter.\n"
    instruction3_text: .asciz "3. Input 2nd Value, Press Enter.\n\n"
    op_selected_text: .asciz " Operation Selected:\n\n"
    dashed_line_text: .asciz "-----\n"
    newline_text: .asciz "\n"
    tab_text: .asciz "\t"

    calculate_table:
        .word addition
        .word subtraction
        .word r_subtraction
        .word multiplication
        .word mulyiply_accumulate
        .word test_equivalence
        .word left_shift
        .word right_shift
        .word bit_and
        .word bit_or
        .word bit_xor
        .word bit_clear
        .word not
        .word count_leading_zeros
        .word store
        .word load

    calculate_text_table:
        .asciz "ADD"
        .asciz "SUB"
        .asciz "RSB"
        .asciz "MUL"
        .asciz "MLA"
        .asciz "TEQ"
        .asciz "LSL"
        .asciz "LSR"
        .asciz "AND"
        .asciz "ORR"
        .asciz "EOR"
        .asciz "BIC"
        .asciz "MVN"
        .asciz "CLZ"
        .asciz "STR"
        .asciz "LDR"

.text

@************************************************************
@ Function: main
@ Description: Main function that initializes the system and
@              runs the calculator loop.
@ Input parameters: None
@ Returns: None
@************************************************************
main:
    BL serial_init
    BL hexpad_init
    LDR r1, =1
    BL enable_global_timer

while_one:
    @ Printing Calculator instructions
    BL print_instructions

    @ Getting operation selection from user
    BL get_calc_operation_val_and_text 
    MOV r4, r1
    MOV r3, r0
    @ Printing selected operation 
    BL serial_print_string
    LDR r1, =op_selected_text
    BL serial_print_string

    @ If operation is load, load value and start over
    CMP r3, #15
    BEQ load_value
    
    @ Getting first operand from user
    BL get_and_print_operand
    BL wait_for_button
    @ Printing operation after first operand
    LDR r1, =tab_text
    BL serial_print_string
    MOV r1, r4
    BL serial_print_string
    @ Starting new line on console
    LDR r1, =newline_text
    BL serial_print_string
    @ Copying operand to r1 to use as input for calculate subroutine
    MOV r1, r0
    
    @ If operation is store, store value and start over
    CMP r3, #14
    BEQ store_value
    @ If operation only requires one operand skip second operand
    CMP r3, #12
    BGE calculate

    @ Getting second operand from user
    BL get_and_print_operand
    BL wait_for_button
    @ Copying operand to r2 to use as input for calculate subroutine
    MOV r2, r0

    calculate:
    @ Calculating and printing result
    BL calculate_result
    @ Printing dashed line for result
    LDR r1, =newline_text
    BL serial_print_string
    LDR r1, =dashed_line_text
    BL serial_print_string
    @ Printing result
    MOV r1, r0
    BL serial_print_hex
    LDR r1, =newline_text
    BL serial_print_string

    @ Waiting for user to press button to reset calculator
    @ LDR r1, =500
    @ BL blocking_delay_ms
    BL wait_for_button
    
B while_one

@************************************************************
@ Function: print_instructions
@ Description: Prints the calculator instructions to the serial
@              console.
@ Input parameters: None
@ Returns: None
@************************************************************
print_instructions:
    PUSH {r1, lr}
    LDR r1, =instruction1_text
    BL serial_print_string
    LDR r1, =100
    BL blocking_delay_ms
    LDR r1, =instruction2_text
    BL serial_print_string
    LDR r1, =100
    BL blocking_delay_ms
    LDR r1, =instruction3_text
    BL serial_print_string
    POP {r1, lr}
    BX lr

@************************************************************
@ Function: get_calc_operation_val_and_text
@ Description: Gets the operation value from the switches and
@              loads the corresponding operation text.
@ Input parameters: None
@ Returns: r0 - Operation value
@          r1 - Operation text
@************************************************************
get_calc_operation_val_and_text:
    PUSH {r2, lr}

    @ Getting value from switch register on button press
    LDR r1, =0b1000
    BL wait_for_button_inf
    BL get_switches
    MOV r1, r0
    
    @ Loading string associated with selected operation
    LDR r1, =calculate_text_table
    ADD r1, r1, r0, LSL #2   

    POP {r2, lr}
    BX lr

@************************************************************
@ Function: wait_for_button
@ Description: Waits for a button press.
@ Input parameters: None
@ Returns: None
@************************************************************
wait_for_button:
    PUSH {r0, r1, lr}
    LDR r1, =0b1000
    BL wait_for_button_inf
    @ Debounce delay
    LDR r1, =250
    BL blocking_delay_ms
    POP {r0, r1, lr}
    BX lr

@************************************************************
@ Function: get_and_print_operand
@ Description: Waits for a hex key press, gets the operand value,
@              and prints it to the serial console.
@ Input parameters: None
@ Returns: r0 - Operand value
@************************************************************
get_and_print_operand:
    PUSH {r1, lr}
    BL wait_for_hexkey_inf
    MOV r1, r0
    BL serial_print_hex
    POP {r1, lr}
    BX lr

@************************************************************
@ Function: load_value
@ Description: Loads a value from memory and prints it to the
@              serial console.
@ Input parameters: None
@ Returns: None
@************************************************************
load_value:
    BL calculate_result
    MOV r1, r0
    BL serial_print_hex
    LDR r1, =tab_text
    BL serial_print_string
    LDR r1, =newline_text
    BL serial_print_string
    BL wait_for_button
    B while_one

@************************************************************
@ Function: store_value
@ Description: Stores a value to memory and prints a newline to
@              the serial console.
@ Input parameters: None
@ Returns: None
@************************************************************
store_value:
    BL calculate_result
    LDR r1, =newline_text
    BL serial_print_string
    BL wait_for_button
    B while_one

@************************************************************
@ Function: calculate_result
@ Description: Calls the appropriate calculation function from
@              calculate_table jump talbe on the operation value.
@ Input parameters: None
@ Returns: r0 - Calculation result
@************************************************************
calculate_result:
    PUSH {r1, r2, r3, r4, r5, lr}
    LDR r4, =calculate_table
    LDR r5, [r4, r3, LSL #2]
    BX r5

addition:
    ADD r0, r1, r2
    B end_calculate

subtraction:
    SUB r0, r1, r2
    B end_calculate

r_subtraction:
    RSB r0, r1, r2
    B end_calculate

multiplication:
    MUL r0, r1, r2
    B end_calculate

mulyiply_accumulate:
    LDR r3, =operand_storage
    LDR r3, [r3]
    MLA r0, r1, r2, r3
    B end_calculate

test_equivalence:
    TEQ r1, r2
    MOVEQ r0, #1
    MOVNE r0, #0    
    B end_calculate

left_shift:
    LSL r0, r1, r2
    B end_calculate

right_shift:
    LSR r0, r1, r2
    B end_calculate

bit_and:
    AND r0, r1, r2
    B end_calculate

bit_or:
    ORR r0, r1, r2
    B end_calculate

bit_xor:
    EOR r0, r1, r2
    B end_calculate

bit_clear:
    BIC r0, r1, r2
    B end_calculate

not:
    MVN r0, r1
    AND r0, r0, #0xF
    B end_calculate

count_leading_zeros:
    CLZ r0, r1
    SUB r0, r0, #28
    B end_calculate

store:
    LDR r2, =operand_storage
    STR r1, [r2]
    B end_calculate

load:
    LDR r1, =operand_storage
    LDR r0, [r1]
    B end_calculate

end_calculate:
    POP {r1, r2, r3, r4, r5, lr}
    BX lr

.end