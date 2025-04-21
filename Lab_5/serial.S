.ifndef SERIAL_S
.set SERIAL_S, 1

.set UART1_CTRL_ADDR, 0xE0001000
.set UART1_MODE_ADDR, 0xE0001004
.set UART1_BAUDGEN_ADDR, 0xE0001018
.set UART1_BAUDRATE_D_ADDR, 0xE0001034
.set UART1_TRX_FIFO_ADDR, 0xE0001030
.set UART1_INTERRUPT_EN_ADDR, 0xE0001008
.set UART1_INTERRUPT_STAT_ADDR, 0xE0001014

.text

@************************************************************
@ Function: serial_init
@ Description: Initializes the UART with the specified parameters.
@ Input parameters: None
@ Returns: None
@************************************************************
serial_init:
    PUSH {r1, r2, r3, lr}
    LDR r1, =UART1_CTRL_ADDR
    LDR r2, =0b11
    STR r2, [r1] 
    
@ reset_pending_loop:
     LDR r3, [r1]
     AND r3, r3, #0b11
@     CMP r3, #0
@     BNE reset_pending_loop

    @ enabling TX and RX
    LDR r2, =0b10100
    STR r2, [r1]

    @ setting stop bits to 1, data bits to 8 and parity to none
    LDR r1, =UART1_MODE_ADDR
    LDR r2, =0b0000100000
    STR r2, [r1]

    @ setting baud rate to 115200
    LDR r1, =UART1_BAUDGEN_ADDR
    LDR r3, =0x7C
    STR r3, [r1]
    LDR r1, =UART1_BAUDRATE_D_ADDR
    LDR r3, =6
    STR r3, [r1]

    @ enabling FIFO full and empty interrupts
    LDR r1, =UART1_INTERRUPT_EN_ADDR
    LDR r2, =0b11000
    STR r2, [r1]

    POP {r1, r2, r3, lr}
    BX lr

@************************************************************
@ Function: serial_print_string
@ Description: Prints a null-terminated string to the serial console.
@ Input parameters: 
@      - r1: Address of the null-terminated string
@ Returns: None
@************************************************************
serial_print_string:
    PUSH {r1, r2, r3, lr}
    LDR r3, =UART1_TRX_FIFO_ADDR
    
    print_string_loop:
        BL check_for_full_tx_buffer
        LDRB r2, [r1], #1  
        CMP r2, #0         
        BEQ print_string_done     
        STRB r2, [r3]      
        B print_string_loop       
    print_string_done:
        POP {r1, r2, r3, lr}
        BX lr


@************************************************************
@ Function: serial_print_hex
@ Description: Prints a hexadecimal value to the serial console.
@ Input parameters: 
@      - r1: The value to print
@ Returns: None
@************************************************************
serial_print_hex:
    PUSH {r1, r2, r3, r4, r5, lr}
    LDR r2, =UART1_TRX_FIFO_ADDR

    MOV r3, #28          @ Shift value
    MOV r4, #0           @ printing_started = false
    MOV r5, r1

    CMP r5, #0
    MOVEQ r3, #0
    BEQ print_hex_0_to_9

    print_hex_loop:
        BL check_for_full_tx_buffer
        MOV r5, r1           @ Copy the value to r1
        LSR r5, r5, r3       @ Shift the value to get the current nibble
        AND r5, r5, #0xF     @ Mask out all but the least significant nibble

        CMP r5, #0
        BEQ remove_leading_zeros

    calc_hex_range:
        CMP r5, #9
        BLE print_hex_0_to_9
        BGT print_hex_a_to_f

    remove_leading_zeros:
        CMP r4, #1
        BEQ calc_hex_range
        BNE print_hex_done

    print_hex_0_to_9:          
        ADD r5, r5, #48      @ Convert to ASCII ('0'-'9')
        STRB r5, [r2]
        MOV r4, #1
        B print_hex_done

    print_hex_a_to_f:
        ADD r5, r5, #87      @ Convert to ASCII ('a'-'f')
        STRB r5, [r2]
        MOV r4, #1

    print_hex_done:
        SUBS r3, r3, #4      @ Move to the next nibble
        BGE print_hex_loop   @ Repeat until all nibbles are processed

    POP {r1, r2, r3, r4, r5, lr}
    BX lr


@************************************************************
@ Function: check_for_full_tx_buffer
@ Description: Checks if the UART TX buffer is full and waits 
@              until it is empty before proceeding.
@ Input parameters: None
@ Returns: None
@************************************************************
check_for_full_tx_buffer:
    PUSH {r1, r2, lr}

    @ checking full buffer flag
    LDR r1, =UART1_INTERRUPT_STAT_ADDR
    LDR r2, [r1]
    AND r2, r2, #0b10000
    CMP r2, #0
    BEQ end_check_tx_buffer

    @ clearing full flag if full
    LDR r2, [r1]
    ORR r2, r2, #0b10000
    STR r2, [r1]

    wait_for_empty_tx_buffer:
        LDR r2, [r1]
        LSR r2, r2, #3
        AND r2, r2, #1
        CMP r2, #1
        BNE wait_for_empty_tx_buffer


    end_check_tx_buffer:
        POP {r1, r2, lr}
        BX lr

.endif /* SERIAL_S */