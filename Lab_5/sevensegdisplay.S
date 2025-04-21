.ifndef SEVENSEGDISPLAY_S
.set SEVENSEGDISPLAY_S, 1

.set SEVSEG_BASEADDR, 0x43C10000
.set SEVSEG_CTRL, 0x0
.set SEVSEG_DATA, 0x4

.text

@************************************************************
@ Function: init_seven_seg
@ Description: Initializes the seven-segment display by enabling 
@              it and setting it to BCD mode.
@ Input parameters: None
@ Returns: None
@************************************************************
init_seven_seg:
    PUSH {r1, r2, r3, lr}

    LDR r2, =SEVSEG_BASEADDR
    LDR r3, =1
    LSL r1, r1, #1
    ORR r1, r1, r3
    STR r1, [r2, #SEVSEG_CTRL]  @ enable the seven segment display and set it to BCD mode

    POP {r1, r2, r3, lr}
    BX lr

@************************************************************
@ Function: write_seven_seg_dec
@ Description: Writes a decimal value to the seven-segment display 
@              by converting it to BCD format.
@ Input parameters:
@      - r1: Decimal value to display
@ Returns: None
@************************************************************
write_seven_seg_dec:
    PUSH {r1, r2, lr}

    LDR r2, =SEVSEG_BASEADDR

    BL bin_to_bcd
    MOV r1, r0
    STR r1, [r2, #SEVSEG_DATA]  @ write the BCD value to the display

    POP {r1, r2, lr}
    BX lr

@************************************************************
@ Function: bin_to_bcd
@ Description: Converts a binary value to its BCD (Binary-Coded Decimal) 
@              representation.
@ Input parameters:
@      - r1: Binary value to convert
@ Returns:
@      - r0: BCD representation of the input value
@************************************************************
bin_to_bcd:
    PUSH {r1 - r6, lr}

    MOV r2, #10         @ denominator for modulus and division
    MOV r3, #0          @ loop iterator i
    MOV r4, #8          @ shift multiplier
    MOV r5, #0          @ bcd value

    while_loop:
        BL unsigned_division  @ r0 = quotient, r1 = remainder
        MUL r6, r3, r4      @ multiplying i by shift multiplier
        LSL r1, r1, r6      @ shifting remainder of division by i * 8
        ORR r5, r5, r1      @ Setting the BCD nibble in the correct position
        ADD r3, r3, #1      @ incrementing loop iterator
        MOV r1, r0          @ moving quotient to r1 for next iteration

        CMP r1, #0
        BNE while_loop

    MOV r0, r5          @ return the BCD value in r0

    POP {r1 - r6, lr}
    BX lr

@************************************************************
@ Function: unsigned_division
@ Description: Performs unsigned integer division.
@ Input parameters:
@      - r1: Numerator
@      - r2: Denominator
@ Returns:
@      - r0: Quotient
@      - r1: Remainder
@************************************************************
unsigned_division:
    PUSH {r2, r3, r4, r5, lr}

    MOV r4, #0          @ r4 will hold the quotient
    MOV r5, r1          @ r5 will hold the dividend
    MOV r3, r2          @ r3 will hold the divisor

    CMP r3, #0          @ Check if divisor is zero
    LDREQ r4, =-1       @ Set quotient to -1 if divisor is zero
    LDREQ r5, =-1       @ Set quotient and dividend to -1 if divisor is zero
    BEQ div_done        @ Branch if divisor is zero

    @ Perform division
    div_loop:
        CMP r5, r3          @ Compare dividend and divisor
        BLT div_done        @ If dividend < divisor, division is done

        SUB r5, r5, r3      @ Subtract divisor from dividend
        ADD r4, r4, #1      @ Increment quotient

        B div_loop          @ Repeat the loop

    div_done:
        MOV r0, r4          @ Move quotient to r0
        MOV r1, r5          @ Move remainder to r1
        POP {r2, r3, r4, r5, lr}
        BX lr

.endif @ SEVENSEGDISPLAY_S