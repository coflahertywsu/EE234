.ifndef SWITCHES_S
.set SWITCHES_S, 1

.set BUTTON_BASEADDR, 0x41200000
.set SWITCH_BASEADDR, 0x41220000
.set GPIO_BASEADDR, 0xE000A000

.data

button_mask: .word 0xF

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
@ Description: This function waits indefinitely for a button. 
@              Use set_button_mask to ignore undsired buttons.
@ Input parameters: none
@ Returns: r0 - The index of the pressed button (0-3).
@************************************************************
wait_for_button_inf:
    PUSH {r1, lr}
	
	LDR r1, =button_mask				@ Load button mask into r1
	LDR r1, [r1]						

    wait_for_button_inf_loop:
        BL get_buttons					@ Getting button values and masking off undesired button vals based on input
        AND r0, r0, r1
        
        CMP r0, #0						@ If no button of interest is pressed continue loop
        BEQ wait_for_button_inf_loop
        
        CLZ r0, r0						@ Else return 0 for btn0, 1 for btn1, etc. (return = 31-leading_zeros)
        RSB r0, r0, #31

    POP {r1, lr}
    BX lr

@************************************************************
@ Function: set_button_mask
@ Description: Sets the button mask to filter out undesired 
@              button inputs during button checks.
@ Input parameters:
@      - r1: Button mask value (4-bit value).
@ Returns: None
@************************************************************

set_button_mask:
	PUSH {r1, lr}
	LDR r2, =button_mask
	STR r1, [r2]						
	POP {r1, lr}
	BX lr

@************************************************************
@ Function: init_GPIO_interrupts
@ Description: Configures GPIO interrupts for BTN4 and BTN5, 
@              including disabling, setting edge sensitivity, 
@              clearing spurious interrupts, and enabling them.
@ Input parameters: None
@ Returns: None
@************************************************************

init_GPIO_interrupts:
    PUSH {r0-r2, lr}

LDR r0, =GPIO_BASEADDR

# 1. Disable BTN4 and BTN5 interrupts before modifying settings on them
	# INT_DIS_1[19:18] = 0b11; (0b11 << 18) = 0xC0000
	LDR r1, =#0xC0000
	# Set bits 18:16 of INT_DIS_1 to 0b11 (disables interrupts for those MIO pins)
	STR r1, [r0, #0x254]

# 2. Setup BTN4 and BTN5 as edge-sensitive
	# INT_TYPE_1[19:18] = 0b11; (0b11 << 18) = 0xC0000
	LDR r1, =#0xC0000
	# Get current contents of INT_TYPE_1
	LDR r2, [r0, #0x25C]
	# Set bits 19:18 to 0b11
	ORR r2, r2, r1
	# Store back out to INT_TYPE_1
	STR r2, [r0, #0x25C]

# 3. Setup BTN4 and BTN5 as rising-edge
	# INT_POL_1[19:18] = 0b11; (0b11 << 18) = 0xC0000
	LDR r1, =#0xC0000
	# Get current contents of INT_POL_1
	LDR r2, [r0, #0x260]
	# Set bits 19:18 to 0b11
	ORR r2, r2, r1
	# Store back out to INT_POL_1
	STR r2, [r0, #0x260]

# 4. Setup BTN4 and BTN5 as single edge
	# INT_ANY_1[19:18] = 0b00; ~(0b11 << 18) = ~0xC0000
	LDR r1, =#0xC0000
	# Invert constant to be ~0xC0000
	MVN r1, r1
	# Get current contents of INT_ANY_1
	LDR r2, [r0, #0x264]
	# Clear bits 19:18 to 0b00
	AND r2, r2, r1
	# Store back out to INT_ANY_1
	STR r2, [r0, #0x264]

# 5. Clear any spurious interrupt requests on BTN4 and BTN5
	# INT_STAT_1[19:18] = 0b11; (0b11 << 18) = 0xC0000
	LDR r1, =#0xC0000
	# Set bits 18:16 of INT_STAT_1 to 0b11 (clear any interrupt requests caused by modifying the settings for MIO pins)
	STR r1, [r0, #0x258]

# 6. Enable BTN4 and BTN5 interrupts now that we have finished modifying their settings
	# INT_EN_1[19:18] = 0b11; (0b11 << 18) = 0xC0000
	LDR r1, =#0xC0000
	# Set bits 18:16 of INT_EN_1 to 0b11 (enables interrupts for those MIO pins)
	STR r1, [r0, #0x250]

    POP {r0-r2, lr}
    BX lr

    

.endif @ SWITCHES_S