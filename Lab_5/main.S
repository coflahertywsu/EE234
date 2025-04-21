
 .include "../src/timers.S"
 .include "../src/sevensegdisplay.S"
 .include "../src/switches.S"
 .include "../src/led.S"
 .include "../src/interrupt.S"
 .include "../src/serial.S"

 .global main
 .global count

 .data
 count: .word 0
 timer_interval_us: .word 2000000           @ initial interval for timer is 2 seconds 
 timer_interval_indicator: .word 0b1001     @ indicator intended to be displayed on LEDs 0-3, 1001 = 2s, 1000 = 1s, 0111 = 0.5s...
 timer_config: .word 0b00                   @ LSB = counter enable (0 = disable), MSB = decrement (0 = increment)

 .text

 main:
    BL init_seven_seg                       @ Initialize the seven segment display

    LDR r1, =on_timer_interrupt             @ Setting ISRs for GTC, BTN4, and BTN5
    BL set_GTC_ISR
    LDR r1, =on_BTN4_interrupt
    BL set_BTN4_ISR
    LDR r1, =on_BTN5_interrupt
    BL set_BTN5_ISR

    BL disable_interrupts          
        MOV r0, #5                          @ Registering interrupts, Xil_ExceptionRegisterHandler(5, IRQ_Handler, NULL);
        LDR r1, =IRQ_Handler
        MOV r2, #0
        BL Xil_ExceptionRegisterHandler

        BL init_GIC                         @ Initializing interrupt controller
        BL init_GPIO_interrupts             @ Initializing GPIO interrupts for BTN4 and BTN5
    BL enable_interrupts      

    BL set_led_10_red                       @ Turn on LED 10 red
    MOV r1, #10
    MOV r2, #1
    BL set_LED                   

    LDR r2, =timer_interval_indicator
    LDR r1, [r2]                
    BL set_led_10_bit                       @ display timer_interval_indicator on LEDs 0-3 (initial value 0b1001)


	whileOne:                               @ main loop
        BL wait_for_button_inf          
		CMP r0, #0                          @ wait for buttons 0-3, blocks everything except interrupts
        BLEQ enable_up_counter
        CMP r0, #1
        BLEQ enable_down_counter
        CMP r0, #2
        BLEQ stop_counter
        CMP r0, #3
        BLEQ reset_counter

        LDR r1, =300000                     @ 300ms button debounce delay
        BL blocking_delay

	B whileOne

@************************************************************
@ Function: on_timer_interrupt
@ Description: Interrupt Service Routine (ISR) for the Global 
@              Timer Counter (GTC). Updates the counter value 
@              and displays it on the seven-segment display.
@ Input parameters: None
@ Returns: None
@************************************************************

on_timer_interrupt:
    PUSH {r1-r5, lr}
    
    LDR r3, =timer_config           @ load current timer_config (enable/disable and increment/decrement settings)
    LDR r3, [r3]                    
    AND r4, r3, #0b01               
    CMP r4, #0                      
    BEQ end_on_timer_interrupt      @ if counter is disabled, exit ISR

    LDR r2, =count                  @ load count variable
    LDR r1, [r2]

    AND r4, r3, #0b10               
    LSR r4, r4, #1
    CMP r4, #1         
    BEQ decrement_count             @ if counter is set to decrement goto decrement_count

    LDR r5, =9999
    CMP r1, r5
    LDREQ r1, =0                    @ if count == 9999, reset to 0
    ADDNE r1, r1, #1                @ else count = count + 1
    B update_and_display_count

    decrement_count:
        CMP r1, #0
        BEQ end_on_timer_interrupt   @ if count == 0, exit ISR (don't roll over backward)
        SUB r1, r1, #1               @ else count = count - 1 if decrementing

    update_and_display_count:
        STR r1, [r2]                
        BL write_seven_seg_dec      @ write count to seven segment display

    end_on_timer_interrupt:
        POP {r1-r5, lr}
        BX lr


@************************************************************
@ Function: on_BTN4_interrupt
@ Description: Interrupt Service Routine (ISR) for Button 4. 
@              Decreases the timer interval and updates the 
@              corresponding indicator on LEDs 0-3.
@ Input parameters: None
@ Returns: None
@************************************************************

on_BTN4_interrupt:
    PUSH {r1-r2, lr}

    LDR r2, =timer_interval_indicator   
    LDR r1, [r2]
    CMP r1, #0
    BEQ end_BTN4_interrupt      @ if timer_interval_indicator is 0, exit ISR (0 is minimum allowed)

    SUB r1, r1, #1              
    STR r1, [r2]                @ decrement timer_interval_indicator and display on LEDs 0-3
    BL set_led_10_bit 

    LDR r2, =timer_interval_us  @ Load timer_interval_us variable
    LDR r1, [r2]    
    LSR r1, r1, #1              @ timer_interval_us = timer_interval_us / 2

    BL set_GTC_auto_increment   @ set new auto increment value for GTC
    STR r1, [r2]                @ store new timer_interval_us value    
   
    end_BTN4_interrupt:
        POP {r1-r2, lr}
        BX lr

        
@************************************************************
@ Function: on_BTN5_interrupt
@ Description: Interrupt Service Routine (ISR) for Button 5. 
@              Increases the timer interval and updates the 
@              corresponding indicator on LEDs 0-3.
@ Input parameters: None
@ Returns: None
@************************************************************

on_BTN5_interrupt:
    PUSH {r1-r2, lr}

    LDR r2, =timer_interval_indicator   
    LDR r1, [r2]
    CMP r1, #0b1111
    BEQ end_BTN5_interrupt      @ if timer_interval_indicator is 0, exit ISR (0 is minimum allowed)

    ADD r1, r1, #1              
    STR r1, [r2]                @ decrement timer_interval_indicator and display on LEDs 0-3
    BL set_led_10_bit 

    LDR r3, =timer_interval_us  @ Load timer_interval_us variable
    MOV r2, #2
    LDR r1, [r3]    
    MUL r1, r1, r2              @ timer_interval_us = timer_interval_us * 2

    BL set_GTC_auto_increment   @ set new auto increment value for GTC
    STR r1, [r3]                @ store new timer_interval_us value

    end_BTN5_interrupt:
        POP {r1-r2, lr}
        BX lr

@************************************************************
@ Function: enable_up_counter
@ Description: Enables the counter in increment mode and starts 
@              the Global Timer Counter (GTC). Sets LED 10 to 
@              blue to indicate the counter is counting up.
@ Input parameters: None
@ Returns: None
@************************************************************

enable_up_counter:
    PUSH {r1, r2, lr}

    LDR r1, =timer_config
    MOV r2, #0b01
    STR r2, [r1]

    BL set_led_10_blue              @ Set LED 10 to green to indicate counter is counting up

    LDR r1, =timer_interval_us      @ Starting GTC
    LDR r1, [r1]
    BL start_GTC_with_interrupt

    POP {r1, r2, lr}
    BX lr


@************************************************************
@ Function: enable_down_counter
@ Description: Enables the counter in decrement mode and starts 
@              the Global Timer Counter (GTC). Sets LED 10 to 
@              green to indicate the counter is counting down.
@ Input parameters: None
@ Returns: None
@************************************************************

enable_down_counter:
    PUSH {r1, r2, lr}

    LDR r1, =timer_config
    MOV r2, #0b11
    STR r2, [r1]

    LDR r1, =timer_interval_us      @ Starting GTC
    LDR r1, [r1]
    BL start_GTC_with_interrupt

    BL set_led_10_green             @ Set LED 10 to blue to indicate counter is decrementing

    POP {r1, r2, lr}
    BX lr


@************************************************************
@ Function: stop_counter
@ Description: Stops the counter by disabling it. Sets LED 10 
@              to red to indicate the counter is stopped.
@ Input parameters: None
@ Returns: None
@************************************************************

stop_counter:
    PUSH {r1, r2, lr}

    LDR r1, =timer_config
    MOV r2, #0b00
    STR r2, [r1]

    BL set_led_10_red      @ Set LED 10 to red to indicate counter is stopped

    POP {r1, r2, lr}
    BX lr


@************************************************************
@ Function: reset_counter
@ Description: Resets the counter value to 0 and updates the 
@              seven-segment display to reflect the reset value.
@ Input parameters: None
@ Returns: None
@************************************************************

reset_counter:
    PUSH {r1, r2, lr}

    LDR r2, =count
    MOV r1, #0
    STR r1, [r2]
    BL write_seven_seg_dec      @ write count to seven segment display            

    POP {r1, r2, lr}
    BX lr


@************************************************************
@ Function: set_led_10_red
@ Description: Sets LED 10 to red by configuring the RGB LED 
@              color values.
@ Input parameters: None
@ Returns: None
@************************************************************

set_led_10_red:
    PUSH {r1, r2, lr}

    MOV r1, #10
    MOV r2, #15
    MOV r3, #0
    MOV r4, #0
    BL set_RGB_color      @ Set RGB color to red

    POP {r1, r2, lr}
   
    BX lr

@************************************************************
@ Function: set_led_10_green
@ Description: Sets LED 10 to green by configuring the RGB LED 
@              color values.
@ Input parameters: None
@ Returns: None
@************************************************************

set_led_10_green:
    PUSH {r1, r2, lr}

    MOV r1, #10
    MOV r2, #0
    MOV r3, #10
    MOV r4, #0
    BL set_RGB_color      @ Set RGB color to green

    POP {r1, r2, lr}
    BX lr

@************************************************************
@ Function: set_led_10_blue
@ Description: Sets LED 10 to blue by configuring the RGB LED 
@              color values.
@ Input parameters: None
@ Returns: None
@************************************************************

set_led_10_blue:
    PUSH {r1, r2, lr}

    MOV r1, #10
    MOV r2, #0
    MOV r3, #0
    MOV r4, #15
    BL set_RGB_color      @ Set RGB color to blue

    POP {r1, r2, lr}
    BX lr

.end
