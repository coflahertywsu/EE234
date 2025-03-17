.ifndef SWITCHES_S
.set SWITCHES_S, 1

.set BUTTON_BASEADDR, 0x41200000
.set SWITCH_BASEADDR, 0x41220000

@************************************************************
@ Function: get_switches
@ Description: This function reads the current state of the 
@              switches.
@ Input parameters: None
@ Returns: r0 - The state of the switches (12-bit value).
@************************************************************
get_switches:
    PUSH {r1}
    LDR r0, =SWITCH_BASEADDR
    LDR r0, [r0]
    LDR r1, =0xFFF
    AND r0, r0, r1
    POP {r1}
    BX lr

@************************************************************
@ Function: get_buttons
@ Description: This function reads the current state of the 
@              buttons.
@ Input parameters: None
@ Returns: r0 - The state of the buttons (4-bit value).
@************************************************************
get_buttons:
    LDR r0, =BUTTON_BASEADDR
    LDR r0, [r0]
    AND r0, r0, #0xF
    BX lr

@************************************************************
@ Function: wait_for_button_inf
@ Description: This function waits indefinitely for a button 
@              press that matches the mask provided in r1.
@ Input parameters: r1 - The button mask.
@ Returns: r0 - The index of the pressed button (0-3).
@************************************************************
wait_for_button_inf:
    PUSH {r1, lr}

    wait_for_button_inf_loop:
        @ Getting button values and masking off undesired button vals based on input
        BL get_buttons
        AND r0, r0, r1
        @ If no button of interest is pressed continue loop
        CMP r0, #0
        BEQ wait_for_button_inf_loop
        @ Else return 0 for btn0, 1 for btn1, etc. (return = 31-leading_zeros)
        CLZ r0, r0
        RSB r0, r0, #31

    POP {r1, lr}
    BX lr

.endif @ SWITCHES_S