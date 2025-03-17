.ifndef ROBOMAL_S
 .set ROBOMAL_S, 1

 .include "../src/serial.S"
 .include "../src/timers.S"
 .include "../src/switches.S"
 .include "../src/pmodb.S"
 .include "../src/robomal_debug.S"

 .data

 # ROBOMAL Architecture: 16-bit architecture

 # Spoofing Harvard Architecture
 ROBO_Instructions: .hword 0x1002, 0x1202, 0x2100, 0x310C, 0x415A, 0x300E, 0x405A, 0x4201, 0x4403, 0x3300
 
 @ Alternate instruction set to test read and write with hexpad
 @ ROBO_Instructions: .hword 0x120E, 0x1100, 0x1000, 0x1102, 0x1002, 0x1300, 0x3300

 ROBO_Data: .hword 0x0080, 0x0000

 @ Alternate data for testing read and write with hexpad
 @ ROBO_Data: .hword 0x000E, 0x000F

@ Jump tables for groups of opcodes
data_transfer_instructs:
     .word read
     .word write
    .word load
    .word store

math_instructs:
    .word add
    .word subtract
    .word multiply

branch_instructs:
    .word branch
    .word brancheq
    .word branchne
    .word halt

robot_instructs:
    .word left
    .word right
    .word forward
    .word backward
    .word brake


@ string for invalid opcode error
op_error_str: .asciz " opcode is not valid\n"

@ string to indicate end of instruction set reached
end_program_str: .asciz "End of ROBO_PROGRAM\n\n"


 # ROBOMAL Register File
 # r5 = accumulator register
 # r6 = program counter register
 # r7 = instruction register
 # r8 = opcode register
 # r9 = operand register
 # r10 = multiply top half solution register

 .text

 # tells the robot to run a program
 runROBO_Program:
     PUSH {lr}

     # Initialize PC to the "start" of my program
     MOV r6, #0

    BL init_pmodb
    BL serial_init
    MOV r1, #1
    BL enable_global_timer

     ROBO_Loop:
         BL simulateClockCycle
        CMP r8, #0x33
         BNE ROBO_Loop

        BL wait_for_button
        LDR r1, =end_program_str
        BL serial_print_string

     POP {lr}
     MOV pc, lr


 # simulate 1 fetch, decode, and execute instuction cycle
 simulateClockCycle:
     PUSH {lr}

    BL wait_for_button
    BL fetch
    BL decode
    BL execute

      POP {lr}
     MOV pc, lr

  # go grab an instruction (from instruction memory) located at the program counter register
 # r6 = PC
 # r7 = instruction register
 fetch:
    # get a pointer to the beginning of instruction memory
    LDR r0, =ROBO_Instructions

    # fetching the instruction located at ROBO_Instructions + offset (PC)
    LDRH r7, [r0, r6]

    # increment PC to point to next instruction
    ADD r6, r6, #0x2

    MOV pc, lr


 # break the instruction register up into opcode and operand
 # r7 = instruction register
 # r8 = opcode register
 # r9 = operand register
 decode:
     # get opcode
     LSR r8, r7, #8

     # get operand
     AND r9, r7, #0xFF

     MOV pc, lr


 # perform the operation
 # r5 = accumulator register
 # r6 = program counter register (if we are doing a branch)
 # r8 = opcode register
 # r9 = operand register
 # r10 = multiply top half solution register
 execute:
     # take opcode and perform the correct operation
    # get opcode
    PUSH {r1, r2, r3, lr}

    @ Getting high nibble (r1) and low nibble (r2)
    MOV r1, r8
    LSR r1, #4
    AND r2, r8, #0xF

    @ Checking opcode validity
    BL validate_opcode
    CMP r0, #0
    BLEQ invalid_opcode_error
    BEQ end_execute

    @ Loading appropriate jump table based on high nibble
    CMP r1, #2
    LDRLT r3, =data_transfer_instructs
    BLT load_instruction_table
    LDREQ r3, =math_instructs
    BEQ load_instruction_table
    CMP r1, #4
    LDRLT r3, =branch_instructs
    BLT load_instruction_table
    LDREQ r3, =robot_instructs
    BEQ load_instruction_table

    
    load_instruction_table:
    @ Loading table + offset using low nibble
    LDR r1, [r3, r2, LSL #2]

    @ Processing opcode
    BL process_opcode
    BL debug_robomal_instruction

    end_execute:
        POP {r1, r2, r3, lr}
         MOV pc, lr

@************************************************************
@ Function: process_opcode
@ Description: Processes the current opcode by branching to the
@              appropriate function based on the value in r1.
@ Input parameters: None
@ Returns: None
@************************************************************
process_opcode:
    PUSH {r1, r2, lr}
    BX r1

    read:
        BL read_pmodb_pins
        LSR r0, r0, #4
        LDR r1, =ROBO_Data
        STRH r0, [r1, r9]
        B end_process_opcode

    write:
        LDR r2, =ROBO_Data
        LDRH r1, [r2, r9]
        BL write_pmodb_pins
        B end_process_opcode

    load:
        LDR r1, =ROBO_Data
        LDRH r5, [r1, r9]
        B end_process_opcode

    store:
        LDR r1, =ROBO_Data
        STRH r5, [r1, r9]
        B end_process_opcode

    add:
        LDR r1, =ROBO_Data
        ADD r1, r1, r9
        LDR r1, [r1]
        ADD r5, r5, r1
        B end_process_opcode		

    subtract:
        LDR r1, =ROBO_Data
        ADD r1, r1, r9
        LDR r1, [r1]
        SUB r5, r5, r1
        B end_process_opcode	

    multiply:
        LDR r1, =ROBO_Data
        ADD r1, r1, r9
        LDR r1, [r1]
        MUL r5, r5, r1
        MOV r10, r5
        LSR r10, #16
        LDR r2, =0xFFFF
        AND r5, r5, r2
        B end_process_opcode	

    branch:		
        MOV r6, r9
        B end_process_opcode

    brancheq:
        CMP r5, #0
        MOVEQ r6, r9
        B end_process_opcode

    branchne:
        CMP r5, #0
        MOVNE r6, r9
        B end_process_opcode

    halt:
        B end_process_opcode

    left:
        @ left code goes here, handled in robomal_debug for now
        B end_process_opcode

    right:
        @ left code goes here, handled in robomal_debug for now
        B end_process_opcode

    forward:
        @ forward code goes here, handled in robomal_debug for now
        B end_process_opcode

    backward:
        @ backward code goes here, handled in robomal_debug for now
        B end_process_opcode

    brake:
        @ brake code goes here, handled in robomal_debug for now
        B end_process_opcode

    end_process_opcode:
        POP {r1, r2, lr}
        BX lr

@************************************************************
@ Function: validate_opcode
@ Description: Validates the current opcode by checking the high
@              and low nibbles. Sets r0 to 1 if valid, 0 if invalid.
@ Input parameters: None
@ Returns: r0 - 1 if valid, 0 if invalid
@************************************************************
validate_opcode:
    PUSH {r1, r2, lr}

    @ Initializing output to valid condition r0 =1
    MOV r0, #1

    @ Checking high nibble for invalid values, branching to check low nibble
    CMP r1, #1
    BLT invalidate_opcode
    BEQ group_1_and_3_opcode
    CMP r1, #3
    BLT group_2_opcode
    BEQ group_1_and_3_opcode
    CMP r1, #4
    BEQ group_4_opcode
    BGT invalidate_opcode

    @ Checking low nibble for invalid values
    group_1_and_3_opcode:
        CMP r2, #3
        BGT invalidate_opcode
        B end_validate_opcode

    group_2_opcode:
        CMP r2, #2
        BGT invalidate_opcode
        B end_validate_opcode

    group_4_opcode:
        CMP r2, #4
        BGT invalidate_opcode
        B end_validate_opcode
    
    invalidate_opcode:
        MOV r0, #0
        B end_validate_opcode

    end_validate_opcode:
        POP {r1, r2, lr}
        BX lr	 

@************************************************************
@ Function: invalid_opcode_error
@ Description: Prints an error message for an invalid opcode.
@ Input parameters: None
@ Returns: None
@************************************************************
invalid_opcode_error:
    PUSH {r1, lr}
    MOV r1, r8
    BL serial_print_hex
    LDR r1, =op_error_str
    BL serial_print_string
    POP {r1, lr}
    BX lr

@************************************************************
@ Function: wait_for_button
@ Description: Waits for a button press and adds debounce delay
@			   after button is pressed.
@ Input parameters: None
@ Returns: None
@************************************************************
wait_for_button:
    PUSH {r0, r1, lr}
    LDR r1, =0b1000
    BL wait_for_button_inf
    @ Debounce delay
    LDR r1, =350
    BL blocking_delay_ms
    POP {r0, r1, lr}
    BX lr

@************************************************************
@ Function: init_pmodb
@ Description: Initializes the PMODB pins 1-4 as output and 5-8
@			   as input.
@ Input parameters: None
@ Returns: None
@************************************************************
init_pmodb:
    PUSH {r1, lr}
    LDR r1, =0b1111
    BL set_pmodb_pin_directions
    POP {r1, lr}
    BX lr

.endif