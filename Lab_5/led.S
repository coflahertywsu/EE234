.ifndef LED_S
.set LED_S, 1

.set LED_BASEADDR, 0x41210000

.set RGB_BASEADDR, 0x43C00000
.set RGB10_BASEADDR, 0x43C00000
.set RGB11_BASEADDR, 0x43C00030
.set RGB_BLUE_OFFSET, 0x0
.set RGB_GREEN_OFFSET, 0x10
.set RGB_RED_OFFSET, 0x20
.set RGB_ENABLE_OFFSET, 0x0
.set RGB_PERIOD_OFFSET, 0x4
.set RGB_WIDTH_OFFSET, 0x8
.set RGB_COLOR_OFFSET, 0x10

.text

@************************************************************
@ Function: set_RGB_color
@ Description: Configures the RGB LED color and period for 
@              specific RGB LEDs (RGB10 or RGB11).
@ Input parameters:
@      - r1: RGB LED identifier (10 or 11)
@      - r2: Red intensity value
@      - r3: Green intensity value
@      - r4: Blue intensity value
@ Returns: None
@************************************************************

set_RGB_color:
    PUSH {r1-r9, lr}  

    MOV r5, #0
    LDR r6, =RGB_BASEADDR
    ADD r6, r6, #RGB_PERIOD_OFFSET
    LDR r7, =RGB_COLOR_OFFSET
    LDR r8, =1024

    set_period_for_all_RGB:
        MUL r9, r5, r7
        ADD r9, r9, r6
        STR r8, [r9]  @ Set the period for each RGB channel
        ADD r5, r5, #1
        CMP r5, #6
        BNE set_period_for_all_RGB

    CMP r1, #10
    BEQ set_RGB_10_color
    CMP r1, #11
    BEQ set_RGB_11_color
    B set_RGB_color_end

    set_RGB_10_color:
        LDR r5, =RGB10_BASEADDR
        ADD r5, r5, #RGB_WIDTH_OFFSET
        STR r2, [r5, #RGB_RED_OFFSET]  @ Set the red color for RGB10
        STR r3, [r5, #RGB_GREEN_OFFSET]  @ Set the green color for RGB10
        STR r4, [r5, #RGB_BLUE_OFFSET]  @ Set the blue color for RGB10
        B set_RGB_color_end
    
    set_RGB_11_color:
        LDR r5, =RGB11_BASEADDR
        ADD r5, r5, #RGB_WIDTH_OFFSET
        STR r2, [r5, #RGB_RED_OFFSET]  @ Set the red color for RGB11
        STR r3, [r5, #RGB_GREEN_OFFSET]  @ Set the green color for RGB11
        STR r4, [r5, #RGB_BLUE_OFFSET]  @ Set the blue color for RGB11

    set_RGB_color_end:
        POP {r1-r9, lr}
        BX lr

@************************************************************
@ Function: set_LED
@ Description: Sets the state of a standard LED or enables 
@              RGB LEDs (RGB10 or RGB11).
@ Input parameters:
@      - r1: LED identifier (0-9 for standard LEDs, 10 or 11 for RGB LEDs)
@      - r2: LED state
@ Returns: None
@************************************************************

set_LED:
    PUSH {r1-r4, lr}  

    CMP r1, #9
    BLT set_standard_LED
    CMP r1, #10
    BEQ set_RGB_10
    CMP r1, #11
    BEQ set_RGB_11
    B set_LED_end

    set_standard_LED:
        LSL r2, r2, r1              @ Shift the LED bit to the left based on LED number
        LDR r3, =LED_BASEADDR
        LDR r4, [r3]
        ORR r4, r4, r2              @ Set the desired LED bit low/high
        STR r4, [r3]                @ Set the LED state
        B set_LED_end

    set_RGB_10:
        LDR r3, =RGB10_BASEADDR
        STR r2, [r3, #RGB_RED_OFFSET]  @ enable red
        STR r2, [r3, #RGB_GREEN_OFFSET]  @ enable green
        STR r2, [r3, #RGB_BLUE_OFFSET]  @ enable blue
        B set_LED_end
    
    set_RGB_11:
        LDR r3, =RGB11_BASEADDR
        STR r2, [r3, #RGB_RED_OFFSET]  @ enable red
        STR r2, [r3, #RGB_GREEN_OFFSET]  @ enable green
        STR r2, [r3, #RGB_BLUE_OFFSET]  @ enable blue
        B set_LED_end

    set_LED_end:
        POP {r1-r4, lr}
        BX lr

@************************************************************
@ Function: set_led_10_bit
@ Description: Sets the state of all 10 standard LEDs using 
@              a 10-bit value.
@ Input parameters:
@      - r1: 10-bit value representing the state of all LEDs
@ Returns: None
@************************************************************

set_led_10_bit:
    PUSH {r1, r2, lr}
    LDR r2, =LED_BASEADDR
    STR r1, [r2]
    POP {r1, r2, lr}
    BX lr


.endif @ LED_S