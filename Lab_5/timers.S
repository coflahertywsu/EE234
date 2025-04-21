.ifndef TIMERS_S
.set TIMERS_S, 1

.set GTC_BASEADDR, 0xF8F00000
.set GTC_LOWER32, 0x200
.set GTC_UPPER32, 0x204
.set GTC_CTRL, 0x208
.set GTC_ISR, 0x20C
.set GTC_COMPARE_LOWER32, 0x210
.set GTC_COMPARE_UPPER32, 0x214
.set GTC_AI, 0x218

.text

@************************************************************
@ Function: start_GTC_with_interrupt
@ Description: Starts the Global Timer Counter (GTC) with 
@              interrupts enabled. Configures the timer, 
@              comparator, and auto-increment registers.
@ Input parameters:
@      - r1: Auto-increment value in microseconds.
@ Returns: None
@************************************************************
start_GTC_with_interrupt:
    PUSH {r1, r2, r3, lr}
    
    MOV r2, #0                              @ Disabling GTC and resetting GTC registers (resetting everything)
    LDR r3, =GTC_BASEADDR       
    STR r2, [r3, #GTC_CTRL]
    STR r2, [r3, #GTC_LOWER32]
    STR r2, [r3, #GTC_UPPER32]
    STR r2, [r3, #GTC_COMPARE_LOWER32]
    STR r2, [r3, #GTC_COMPARE_UPPER32]  
        
    MOV r2, #1                              @ Clearing interrupt flag
    STR r2, [r3, #GTC_ISR]

    MOV r2, #2                              @ Calculating auto increment value based on 167 prescaler and setting AI register
    MUL r1, r1, r2
    STR r1, [r3, #GTC_COMPARE_LOWER32]
    STR r1, [r3, #GTC_AI]

    LDR r2, =0xA60F                         @ Enabling timer, comparator, interrupt, auto-increment, and setting scaler value
    STR r2, [r3, #GTC_CTRL]

    POP {r1, r2, r3, lr}
    BX lr

@************************************************************
@ Function: set_GTC_auto_increment
@ Description: Configures the auto-increment value for the 
@              Global Timer Counter (GTC).
@ Input parameters:
@      - r1: Auto-increment value in microseconds.
@ Returns: None
@************************************************************
set_GTC_auto_increment:
    PUSH {r1, r2, r3, lr}

    LDR r3, =GTC_BASEADDR

    MOV r2, #2                          @ Calculating auto increment value based on 167 prescaler and setting AI register
    MUL r1, r1, r2
    STR r1, [r3, #GTC_AI]

    POP {r1, r2, r3, lr}
    BX lr

@************************************************************
@ Function: blocking_delay
@ Description: Implements a blocking delay using the Global 
@              Timer Counter (GTC). The delay is based on the 
@              specified number of microseconds.
@ Input parameters:
@      - r1: Delay duration in microseconds.
@ Returns: None
@************************************************************
blocking_delay:
    PUSH {r1, r2, r3, lr}                @ Save registers

    MOV r2, #2
    MUL r1, r1, r2                      @ Convert input (r1) from microseconds to GTC clock cycles based on 167 prescaler

    LDR r2, =GTC_BASEADDR

    LDR r3, [r2, #GTC_LOWER32]          @ Read the current value of the timer
    LDR r4, [r2, #GTC_UPPER32]

    ADDS r5, r3, r1                     @ Add the delay value to the current timer value
    ADCS r6, r4, #0

    blocking_delay_loop:
        LDR r3, [r2, #GTC_LOWER32]      @ Read the current value of the timer
        LDR r4, [r2, #GTC_UPPER32]
        
        CMP r4, r6                      @ Compare time and timer value upper32
        BGT blocking_delay_end          @ If time upper32 is greater, exit loop
        BLT blocking_delay_loop         @ If time lower32 is greater, continue loop

        CMP r3, r5                      @ If upper32 is equal, check lower32
        BGE blocking_delay_end
        B blocking_delay_loop           

    blocking_delay_end:
        POP {r1, r2, r3, lr}
        BX lr

.endif /* TIMERS_S */