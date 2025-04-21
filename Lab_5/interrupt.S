.ifndef SRC_INTERRUPT_S
.set SRC_INTERRUPT_S, 1

.set ICCICR_BASEADDR, 0xF8F00100 	@ CPU Interface Control Register
.set ICCPMR_BASEADDR, 0xF8F00104	@ Interrupt Priority Mask Register
.set ICCIAR_BASEADDR, 0xF8F0010C	@ Interrupt Acknowledge Register
.set ICCEOIR_BASEADDR, 0xF8F00110	@ End of Interrupt Register
.set ICDDCR_BASEADDR, 0xF8F01000	@ Distributor Control Register
.set ICDISER_BASEADDR, 0xF8F01100	@ Interrupt Set Enable Registers
.set ICDICER_BASEADDR, 0xF8F01180	@ Interrupt Clear Enable Registers
.set ICDIPR_BASEADDR, 0xF8F01400	@ Interrupt Priority Registers
.set ICDIPTR_BASEADDR, 0xF8F01800	@ Interrupt Processor Targets Registers
.set ICDICFR_BASEADDR, 0xF8F01C00	@ Interrupt Configuration Registers

    @ Important Base Registers of GPIO
.set GPIO_BASEADDR, 0xE000A000

    @ Important Base Registers of GTC
.set GTC_BASEADDR, 0xF8F00000

.data
GTC_ISR: .word 0
BTN4_ISR: .word 0
BTN5_ISR: .word 0

.text

@************************************************************
@ Function: disable_interrupts
@ Description: Disables all IRQ interrupts on the CPU by 
@              setting the IRQ mask bit in the CPSR register.
@ Input parameters: None
@ Returns: None
@************************************************************
disable_interrupts:
# Grab the current value of the CPSR register
MRS r0, cpsr
# Set the IRQ mask bit to a '1', CPSR[7] = 0b1
# to DISABLE IRQ Interrupts on the CPU
ORR r0, r0, #0b10000000
# Store back out the value to the CPSR register (note the 'c' field was added which only writes to the LSB of the CPSR register)
MSR cpsr_c, r0

BX lr

@************************************************************
@ Function: enable_interrupts
@ Description: Enables all IRQ interrupts on the CPU by 
@              clearing the IRQ mask bit in the CPSR register.
@ Input parameters: None
@ Returns: None
@************************************************************
enable_interrupts:
# Grab the current value of the CPSR register
MRS r0, cpsr
# Clear the IRQ mask bit to a '0', CPSR[7] = 0b0
# to ENABLE IRQ Interrupts on the CPU
MVN r1, #0b10000000
AND r0, r0, r1
# Store back out the value to the CPSR register (note the 'c' field was added which only writes to the LSB of the CPSR register)
MSR cpsr_c, r0

BX lr

@************************************************************
@ Function: init_GIC
@ Description: Initializes the Generic Interrupt Controller (GIC) 
@              by configuring the distributor and CPU interface.
@ Input parameters: None
@ Returns: None
@************************************************************
init_GIC:

    PUSH {lr}

        @ Disable the GIC distributor (ICDDCR) to avoid spurious interrupts
    LDR r0, =ICDDCR_BASEADDR
    MOV r1, #0b00
    STR r1, [r0]

        @ Drive IRQ from the GIC (ICCICR)
    LDR r0, =ICCICR_BASEADDR
    MOV r1, #0b00011
    STR r1, [r0]

        @ Set GIC priority mask (255 = lowest priority, 0 = highest priority)
    LDR r0, =ICCPMR_BASEADDR
    MOV r1, #255
    STR r1, [r0]

        @ Configure settings for specific interrupt IDs
    BL configure_ID27
    BL configure_ID52

        @ Reenable the GIC distributor (ICDDCR)
    LDR r0, =ICDDCR_BASEADDR
    MOV r1, #0b11
    STR r1, [r0]

    POP {lr}
    BX lr

@************************************************************
@ Function: configure_ID27
@ Description: Configures interrupt ID 27, including priority, 
@              sensitivity, and enabling the interrupt.
@ Input parameters: None
@ Returns: None
@************************************************************
configure_ID27:
            @ Temporarily disable Interrupts from ID 27 to modify settings, preserve other bits
        LDR r0, =ICDIPTR_BASEADDR
        LDR r1, =#0x3000000
        MVN r1, r1
        LDR r2, [r0, #0x18]
        AND r2, r2, r1
        STR r2, [r0, #0x18]
            @ ICDICER0[27] = 0b1 (a clear register, i.e. don't need to worry about other bits)
        LDR r0, =ICDICER_BASEADDR
        LDR r1, =#0x8000000
        STR r1, [r0]

             @ Set Interrupt Sensitivity for ID 27
        LDR r0, =ICDICFR_BASEADDR
        LDR r1, =#0xC00000
        LDR r2, [r0, #0x04]
        ORR r2, r2, r1
        STR r2, [r0, #0x04]

        LDR r0, =ICDIPR_BASEADDR
        LDR r1, =#0xFF000000
        MVN r1, r1
        LDR r2, [r0, #0x18]
        AND r2, r2, r1
        LDR r1, =#0x50000000
        ORR r2, r2, r1
        STR r2, [r0, #0x18]

            @ Reenable Interrupts from ID 27, preserve other bits
        LDR r0, =ICDIPTR_BASEADDR
        LDR r1, =#0x1000000
        LDR r2, [r0, #0x18]
        ORR r2, r2, r1
        STR r2, [r0, #0x18]
            @ ICDISER0[27] = 0b1 (a set register, i.e. don't need to worry about other bits)
        LDR r0, =ICDISER_BASEADDR
        LDR r1, =#0x8000000
        STR r1, [r0]

        BX lr

@************************************************************
@ Function: configure_ID52
@ Description: Configures interrupt ID 52, including priority, 
@              sensitivity, and enabling the interrupt.
@ Input parameters: None
@ Returns: None
@************************************************************
configure_ID52:
            @ Temporarily disable Interrupts from ID 52 to modify settings, preserve other bits
        LDR r0, =ICDIPTR_BASEADDR
        MVN r1, #0b11
        LDR r2, [r0, #0x34]
        AND r2, r2, r1
        STR r2, [r0, #0x34]
            @ ICDICER1[20] = 0b1 (a clear register, i.e. don't need to worry about other bits)
        LDR r0, =ICDICER_BASEADDR
        LDR r1, =#0x100000
        STR r1, [r0, #0x04]

            @ Set Interrupt Sensitivity for ID 52
        LDR r0, =ICDICFR_BASEADDR
        MVN r1, #0b1100000000
        LDR r2, [r0, #0x0C]
        AND r2, r2, r1
        MOV r1, #0b0100000000
        ORR r2, r2, r1
        STR r2, [r0, #0x0C]

        LDR r0, =ICDIPR_BASEADDR
        MVN r1, #0xFF
        LDR r2, [r0, #0x34]
        AND r2, r2, r1
        MOV r1, #0xA0
        ORR r2, r2, r1
        STR r2, [r0, #0x34]

            @ Reenable Interrupts from ID 52, preserve other bits
        LDR r0, =ICDIPTR_BASEADDR
        MOV r1, #0b01
        LDR r2, [r0, #0x34]
        ORR r2, r2, r1
        STR r2, [r0, #0x34]
            @ ICDISER1[20] = 0b1 (a set register, i.e. don't need to worry about other bits)
        LDR r0, =ICDISER_BASEADDR
        LDR r1, =#0x100000
        STR r1, [r0, #0x04]

        BX lr

@************************************************************
@ Function: set_GTC_ISR
@ Description: Sets the ISR (Interrupt Service Routine) for 
@              the Global Timer Counter (GTC).
@ Input parameters:
@      - r1: Address of the ISR function
@ Returns: None
@************************************************************
set_GTC_ISR:
    PUSH {r1, r2, lr}
    LDR r2, =GTC_ISR
    STR r1, [r2]
    POP {r1, r2, lr}
    BX lr

@************************************************************
@ Function: set_BTN4_ISR
@ Description: Sets the ISR (Interrupt Service Routine) for 
@              Button 4.
@ Input parameters:
@      - r1: Address of the ISR function
@ Returns: None
@************************************************************
set_BTN4_ISR:
    PUSH {r1, r2, lr}
    LDR r2, =BTN4_ISR
    STR r1, [r2]
    POP {r1, r2, lr}
    BX lr

@************************************************************
@ Function: set_BTN5_ISR
@ Description: Sets the ISR (Interrupt Service Routine) for 
@              Button 5.
@ Input parameters:
@      - r1: Address of the ISR function
@ Returns: None
@************************************************************
set_BTN5_ISR:
    PUSH {r1, r2, lr}
    LDR r2, =BTN5_ISR
    STR r1, [r2]
    POP {r1, r2, lr}
    BX lr

@************************************************************
@ Function: IRQ_Handler
@ Description: Main IRQ handler that determines the source of 
@              the interrupt and calls the appropriate ISR.
@ Input parameters: None
@ Returns: None
@************************************************************
IRQ_Handler:
    PUSH {r0, r1, r2, r3, lr}

    # First grab the IRQ ID that caused us to enter the IRQ handler
    LDR r0, =ICCIAR_BASEADDR
    LDR r1, [r0]

    # Did we enter the handler because of IRQ ID 27?
    CMP r1, #27
    BEQ GTC_Int

    # Did we enter the handler because of IRQ ID 52?
    CMP r1, #52
    BNE endIRQ_Handler

    # Grab the GPIO_INT_STAT register to see if the interrupt was caused by BTN 4 or BTN 5
    LDR r0, =GPIO_BASEADDR
    LDR r2, [r0, #0x258]
    LSR r2, r2, #18
    AND r2, r2, #0b11

    # Did we enter the handler because of BTN4?
    CMP r2, #0b01
    BEQ BTN4_Int

    # Did we enter the handler because of BTN5?
    CMP r2, #0b10
    BEQ BTN5_Int
    B endIRQ_Handler

        GTC_Int:
        LDR r3, =GTC_ISR        @ Loads and executes GTC ISR passed in by user
        LDR r3, [r3]
        BLX r3 

        # clear the GTC_ISR status event flag associated with GTC
        LDR r3, =GTC_BASEADDR
        MOV r2, #1
        STR r2, [r3, #0x20C]
        B endIRQ_Handler


        BTN4_Int:
        LDR r3, =BTN4_ISR       @ Loads and executes BTN4 ISR passed in by user
        LDR r3, [r3]
        BLX r3

        # clear the GPIO_INT_STAT register bit associated with BTN4
        LDR r3, =0x40000
        STR r3, [r0, #0x258]
        B endIRQ_Handler

        BTN5_Int:
        LDR r3, =BTN5_ISR       @ Loads and executes BTN5 ISR passed in by user
        LDR r3, [r3]
        BLX r3

        # clear the GPIO_INT_STAT register bit associated with BTN5
        LDR r3, =0x80000
        STR r3, [r0, #0x258]
        B endIRQ_Handler

        endIRQ_Handler:
        # Acknowledge (clear) the IRQ ID that caused us to enter the IRQ handler
        LDR r0, =ICCEOIR_BASEADDR
        STR r1, [r0]

        POP {r0, r1, r2, r3, lr}
        BX lr

.endif @ SRC_INTERRUPT_S