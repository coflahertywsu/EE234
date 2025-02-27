.ifndef HEXPAD_S
.set HEXPAD_S, 1

.include "../src/pmodb.S"

.text

@************************************************************
@ Function: hexpad_init
@ Description: This function initializes the hex keypad by 
@              setting the column pins as outputs and setting 
@              all column pins high.
@ Input parameters: None
@ Returns: None
@************************************************************
hexpad_init:
    PUSH {r1, lr}

    @ Setting column pins as outputs
    LDR r1, =0b1111
    BL set_pmodb_pin_directions

    @ Setting all column pins high
    BL write_pmodb_pins
    
    POP {r1, lr}
    BX lr

@************************************************************
@ Function: get_hexkey
@ Description: This function scans the hex keypad to detect 
@              which key is pressed, and calculates the row 
@              and column values of the pressed key.
@ Input parameters: None
@ Returns: r0 - The value of the pressed key, or -1 if no 
@          key is pressed.
@************************************************************
get_hexkey:
    PUSH {r1, r2, r3, r4, r5, r6, lr}

    LDR r3, =0   @ column value
    LDR r4, =0   @ row value
    LDR r5, =4   @ column iterator

    @ iterate through columns 1-4 (pmodb pins 4-1)
    column_loop:
        LDR r6, =8   @ row iterator

        @ set column pin low based on column iterator value
        MOV r1, r5
        LDR r2, =0
        BL write_pmodb_pin

        @ iterate through rows 1-4 (pmodb pins 8-5)
        row_loop:
            @ read row pin based on row iterator value
            MOV r1, r6
            BL read_pmodb_pin

            @ if row pin is low calc row and column values and store in designated row/column value registers
            CMP r0, #0
            RSBEQ r3, r5, #5
            RSBEQ r4, r6, #9

            @ decrement row iterator and check condition to continue loop
            SUB r6, r6, #1
            CMP r6, #5
            BGE row_loop

    @ set column pin back to high
    MOV r1, r5
    LDR r2, =1
    BL write_pmodb_pin
    
    @ decrement column iterator and check condition to continue loop
    SUB r5, r5, #1
    CMP r5, #1
    BGE column_loop

    @ decode hexkey value based on row and column values and end subroutine
    MOV r1, r4
    MOV r2, r3
    BL decode_hexkey_value
    POP {r1, r2, r3, r4, r5, r6, lr}
    BX lr

@************************************************************
@ Function: decode_hexkey_value
@ Description: This function decodes the row and column values 
@              of the pressed key into a hex key value.
@ Input parameters: r1 - The row value.
@                   r2 - The column value.
@ Returns: r0 - The decoded hex key value.
@************************************************************
decode_hexkey_value:
PUSH {r1, r2, r3}

    @ Checking for invalid/null input values
    CMP r1, #0
    BEQ button_invalid
    CMP r1, #4
    BGT button_invalid
    CMP r2, #0
    BEQ button_invalid
    CMP r2, #4
    BGT button_invalid

    @ if column is 4 go to buttons_a_to_d
    BEQ buttons_a_to_d

    @ if row is 4 go to buttons_e_f_0
    CMP r1, #4
    BEQ buttons_e_f_0

    @ if row  is 1 to 3 and column is 1 to 3 go to buttons_1_to_9
    BLT buttons_1_to_9

    @ End of decode_hexkey_value subroutine.  Placed here in case all conditions fall through.
    end_decode_hexkey_value:
    POP {r1, r2, r3}
    BX lr

    @ if (0 < row < 4) AND (0 < column < 4) return column + (row - 1)*3
    buttons_1_to_9:
        PUSH {r1}
        SUB r1, r1, #1
        LDR r3, =3
        MUL r1, r1, r3
        ADD r0, r1, r2
        POP {r1}
        B end_decode_hexkey_value

    @ if (column == 4) return row + 9 
    buttons_a_to_d:
        ADD r0, r1, #9
        B end_decode_hexkey_value
        
    @ if (row == 4) return e, f, or 0 depending on column value 
    buttons_e_f_0:
        CMP r2, #1
        MOVEQ r0, #0
        CMP r2, #2
        MOVEQ r0, #15
        CMP r2, #3
        MOVEQ r0, #14
        B end_decode_hexkey_value

    @ if row or column values are not 1-4 return -1
    button_invalid:
        LDR r0, =-1
        B end_decode_hexkey_value


@************************************************************
@ Function: wait_for_hexkey_inf
@ Description: This function waits indefinitely for a hex key 
@              press. It continuously calls the get_hexkey 
@              function until a valid key press is detected.
@ Input parameters: None
@ Returns: r0 - The value of the pressed key.
@************************************************************

wait_for_hexkey_inf:
    PUSH {lr}
    
    wait_for_hexkey_inf_loop:
        BL get_hexkey
        CMP r0, #-1
        BEQ wait_for_hexkey_inf_loop
    
    POP {lr}
    BX lr


.endif /* HEXPAD_S */