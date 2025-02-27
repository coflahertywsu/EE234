.ifndef TIMERS_S
.set TIMERS_S, 1

.set GTC_LOWER32, 0xF8F00200
.set GTC_UPPER32, 0xF8F00204
.set GTC_COMPARE_LOWER32, 0xF8F00210
.set GTC_COMPARE_UPPER32, 0xF8F00214
.set GTC_ISR, 0xF8F0020C
.set GTC_CTRL, 0xF8F00208

@************************************************************
@ Function: enable_global_timer
@ Description: This function enables or disables the global 
@              timer and the compare registers based on the 
@              input parameter.
@ Input parameters: r1 - 0 to disable, non-zero to enable.
@************************************************************

enable_global_timer:
    PUSH {r1, r2}
    
    @ Loading timer ctrl register address
    LDR r2, =GTC_CTRL

    @ Enabling/Disabling GTC and GTC_COMPARE based on input
    CMP r1, #0
    LDREQ r1, =0b00
    LDRNE r1, =0b11
    STR r1, [r2]

    POP {r1, r2}
    BX lr

@************************************************************
@ Function: blocking_delay_ms
@ Description: This function creates a blocking delay for a 
@              specified number of milliseconds.
@ Input parameters: r1 - The delay in milliseconds.
@************************************************************

blocking_delay_ms:
    PUSH {r1, r2, r3, r4, r5}

    @ Converting input delay in ms to delay in 3ns increments
    LDR r2, =333333
    MUL r1, r1, r2

    @ Loading current_time in registers r2 and r3
    LDR r2, =GTC_LOWER32
    LDR r3, =GTC_UPPER32
    LDR r2, [r2]
    LDR r3, [r3]

    @ Loading addresses of compare registers in r4 and r5
    LDR r4, =GTC_COMPARE_LOWER32
    LDR r5, =GTC_COMPARE_UPPER32

    @ Adding current_time + delay into r2 and r3
    ADDS r2, r2, r1
    ADC r3, r3, #0

    @ Storing current_time + delay into compare registers
    STR r2, [r4]
    STR r3, [r5]

    @ Clearing compare flag
    LDR r1, =GTC_ISR
    LDR r2, =1
    STR r2, [r1]

    @ Blocking loop that continues until compare flag is set
    blocking_delay_ms_loop:
        @ Loading and masking compare_flag
        LDR r2, [r1]
        AND r2, r2, #1

        @ Continue loop if compare_flag == 0
        CMP r2, #0
        BEQ blocking_delay_ms_loop

    POP {r1, r2, r3, r4, r5}
    BX lr


.endif /* TIMERS_S */