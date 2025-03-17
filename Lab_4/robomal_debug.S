.ifndef ROBOMAL_DEBUG_S
.set ROBOMAL_DEBUG_S, 1

.include "../src/serial.S"

.data

decode_data_transfer_instructs:
    .word decode_read
    .word decode_write
    .word decode_load
    .word decode_store

decode_math_instructs:
    .word decode_add
    .word decode_subtract
    .word decode_multiply

decode_branch_instructs:
    .word decode_branch
    .word decode_brancheq
    .word decode_branchne
    .word decode_halt

decode_robot_instructs:
    .word decode_left
    .word decode_right
    .word decode_forward
    .word decode_backward
    .word decode_brake

@ Strings that go with instructs
read_str: .asciz "read"
write_str: .asciz "write"
load_str: .asciz "load"
store_str: .asciz "store"
add_str: .asciz "add"
subtract_str: .asciz "subtract"
multiply_str: .asciz "multiply"
branch_str: .asciz "branch"
brancheq_str: .asciz "brancheq"
branchne_str: .asciz "branchne"
halt_str: .asciz "halt"
left_str: .asciz "left"
right_str: .asciz "right"
forward_str: .asciz "forward"
backward_str: .asciz "backward"
brake_str: .asciz "brake"

reg9_str: .asciz ", operand = "
reg5_str: .asciz ", accumulator = "
num1_str: .asciz ", num1 = "
num2_str: .asciz ", num2 = "
reg6_str: .asciz ", pc = "
newline_str: .asciz "\n"

.text

@************************************************************
@ Function: debug_robomal_instruction
@ Description: Prints last opcode used, operand, accumulator, 
@              and other relevant registers.
@ Input parameters: r5 - r10
@ Returns: None
@************************************************************
debug_robomal_instruction:
    PUSH {r1, r2, lr}
    
    BL set_opcode_string
    BL serial_print_string
    LDR r1, =reg9_str
    BL serial_print_string
    MOV r1, r9
    BL serial_print_hex
    LDR r1, =reg5_str
    BL serial_print_string
    MOV r1, r5
    BL serial_print_hex
    LDR r1, =num1_str
    BL serial_print_string
    LDR r2, =ROBO_Data
    LDRH r1, [r2]
    BL serial_print_hex
    LDR r1, =num2_str
    BL serial_print_string
    ADD r2, r2, #2
    LDRH r1, [r2]
    BL serial_print_hex
    LDR r1, =reg6_str
    BL serial_print_string
    MOV r1, r6
    BL serial_print_hex
    LDR r1, =newline_str
    BL serial_print_string

    POP {r1, r2, lr}
    BX lr

@************************************************************
@ Function: set_opcode_string
@ Description: Sets the opcode string based on the current opcode
@              value in r8. It uses a jump table to determine the
@              appropriate string.
@ Input parameters: r5 - r10
@ Returns: None
@************************************************************
set_opcode_string:
    PUSH {r2, r3, lr}

    @ Getting high nibble (r1) and low nibble (r2)
    MOV r1, r8
    LSR r1, #4
    AND r2, r8, #0xF

    @ Loading appropriate jump table based on high nibble
    CMP r1, #2
    LDRLT r3, =decode_data_transfer_instructs
    BLT load_decode_table
    LDREQ r3, =decode_math_instructs
    BEQ load_decode_table
    CMP r1, #4
    LDRLT r3, =decode_branch_instructs
    BLT load_decode_table
    LDREQ r3, =decode_robot_instructs
    BEQ load_decode_table

    load_decode_table:
    @ Loading table + offset using low nibble
    LDR r1, [r3, r2, LSL #2]

    @ Converting opcode value to string
    BL decode_opcode

    POP {r2, r3, lr}
    MOV pc, lr

@************************************************************
@ Function: decode_opcode
@ Description: Decodes the opcode by branching to the appropriate
@              decode function based on the value in r1.
@ Input parameters: None
@ Returns: None
@************************************************************
decode_opcode:
    PUSH {lr}
    BX r1

	decode_read:
	    LDR r1, =read_str
	    B end_decode_opcode

	decode_write:
	    LDR r1, =write_str
	    B end_decode_opcode

	decode_load:
	    LDR r1, =load_str
	    B end_decode_opcode

	decode_store:
	    LDR r1, =store_str
	    B end_decode_opcode

	decode_add:
	    LDR r1, =add_str
	    B end_decode_opcode

	decode_subtract:
	    LDR r1, =subtract_str
	    B end_decode_opcode

	decode_multiply:
	    LDR r1, =multiply_str
	    B end_decode_opcode

	decode_branch:
	    LDR r1, =branch_str
	    B end_decode_opcode

	decode_brancheq:
	    LDR r1, =brancheq_str
	    B end_decode_opcode

	decode_branchne:
	    LDR r1, =branchne_str
	    B end_decode_opcode

	decode_halt:
	    LDR r1, =halt_str
	    B end_decode_opcode

	decode_left:
	    LDR r1, =left_str
	    B end_decode_opcode

	decode_right:
	    LDR r1, =right_str
	    B end_decode_opcode

	decode_forward:
	    LDR r1, =forward_str
	    B end_decode_opcode

	decode_backward:
	    LDR r1, =backward_str
	    B end_decode_opcode

	decode_brake:
	    LDR r1, =brake_str
	    B end_decode_opcode

	end_decode_opcode:
	    POP {lr}
	    BX lr

.endif @ ROBOMAL_DEBUG_S