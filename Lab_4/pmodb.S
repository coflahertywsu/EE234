.ifndef PMODB_S
.set PMODB_S, 1

.set DATA2_OUTPUT_ADDR, 0xE000A048
.set DATA2_INPUT_ADDR, 0xE000A068
.set DATA2_DIR, 0xE000A284
.set DATA2_OUT_EN, 0xE000A288
.set PMODB_MASK, 0x7F80

.text

@************************************************************
@ Function: set_pmodb_pin_directions                        
@ Description: This function sets the directions of the     
@              PMODB pins by updating the direction and     
@              output enable registers.                     
@ Input parameters: r1 - Value representing the directions
@                   of the pins. Each bit corresponds to a  
@                   pin (1 for output, 0 for input).        
@ Returns: None                                             
@************************************************************
set_pmodb_pin_directions:
    @ clearing PMODB pins based on input r1
    PUSH {r1, r2, r3, r4, r5, r6}
        @ inverting the mask
    LDR r2, =PMODB_MASK
    MVN r2, r2
    
        @ clearing the direction register for PMODB pins
    LDR r3, =DATA2_DIR   
    LDR r4, [r3]        @ holds current value of DATA2_DIR
    LDR r5, =DATA2_OUT_EN
    LDR r6, [r5]        @ holds current value of DATA2_OUT_EN
    AND r4, r4, r2
    AND r6, r6, r2

        @ shifting input left by 7 bits to align with PMODB pins
    LSL r1, r1, #7

        @ setting the direction register for PMODB pins based on input r1
    ORR r4, r4, r1
    ORR r6, r6, r1
    STR r4, [r3]
    STR r6, [r5]

    POP {r1, r2, r3, r4, r5, r6}
    BX lr

@************************************************************
@ Function: set_pmodb_pin_direction                         
@ Description: This function sets the direction of a        
@              specific PMODB pin.                          
@ Input parameters: r1 - The pin number (1-8).              
@                   r2 - The direction (0 for input, 1 for  
@                   output).                                
@ Returns: None                                             
@************************************************************
set_pmodb_pin_direction:
    PUSH {r1, r2, lr}
    @ masking direction value so only LSB is used
    AND r2, r2, #1

    @ shifting direction bit to correct PMODB pin position based on input r2
    SUB r1, r1, #1
    LSL r1, r2, r1 

    @ setting the direction of the PMODB pin using set_pmodb_pin_directions
    BL set_pmodb_pin_directions

    POP {r1, r2, lr}
    BX lr

@************************************************************
@ Function: read_pmodb_pins                                 
@ Description: This function reads the input state of all   
@              PMODB pins.                                  
@ Input parameters: None                                    
@ Returns: r0 - Value representing the state of the pins. 
@          Each bit corresponds to a pin (1 for high, 0 for 
@          low).                                            
@************************************************************
read_pmodb_pins:
    PUSH {r1}
    @ setting the value of the PMODB pins to r0
    LDR r0, =DATA2_INPUT_ADDR
    LDR r1, =PMODB_MASK
    LDR r0, [r0]    @ holds current value of DATA2_INPUT_ADDR
        @ masking off non-PMODB pins
    AND r0, r0, r1
        @ shifting value to right to align with LSBs of r0
    LSR r0, r0, #7

    POP {r1}
    BX lr

@************************************************************
@ Function: read_pmodb_pin                                  
@ Description: This function reads the value of a specific   
@              PMODB pin.                          
@ Input parameters: r1 - The pin number (1-8).              
@ Returns: r0 - The state of the pin (0 for low, 1 for high)
@************************************************************
read_pmodb_pin:
    PUSH {r1, r2, lr}

    BL read_pmodb_pins

    SUB r1, r1, #1
    LSR r0, r0, r1 
    AND r0, r0, #1

    POP {r1, r2, lr}
    BX lr 

@************************************************************
@ Function: write_pmodb_pins                                
@ Description: This function sets the PMODB pin values by  
@              writing to the Xilinx DATA2 register.        
@ Input parameters: r1 - Value representing the values to 
@                   write to the pins. Each bit corresponds 
@                   to a pin (1 for high, 0 for low).       
@ Returns: None                                             
@************************************************************
write_pmodb_pins:
    PUSH {r1, r2, r3, r4}

    @ inverting PMODB_MASK
    LDR r2, =PMODB_MASK   
    MVN r2, r2      @ holds inverted PMODB_MASK

    @ aligning input value to PMODB pins and setting other bits to 1
    LSL r1, r1, #7
    ORR r1, r1, r2
    
    @ setting PMODB pin values with non-PMODB pins unchanged
    LDR r3, =DATA2_OUTPUT_ADDR
    LDR r4, [r3]
    AND r4, r4, r1 
    STR r4, [r3]

    POP {r1, r2, r3, r4}
    BX lr

@************************************************************
@ Function: write_pmodb_pin                                 
@ Description: This function writes a value to a specific   
@              PMODB pin.                                   
@ Input parameters: r1 - The pin number (1-8).              
@                   r2 - The value to write (0 for low, 1   
@                   for high).                              
@ Returns: None                                             
@************************************************************
write_pmodb_pin:
    PUSH {r1, r2, r3, r4, r5}

    @ Creating bit mask and aligning to correct PMOD pin based on r1
    ADD r1, r1, #6
    LDR r3, =1
    LSL r3, r3, r1 @ holds bit mask

    @ getting current value of DATA2_OUTPUT_ADDR
    LDR r4, =DATA2_OUTPUT_ADDR
    LDR r5, [r4]    @ holds current value of DATA2_OUTPUT_ADDR

    @ if r2 is >= 1 then set PMODB pin, else clear it
    CMP r2, #1 
    ORRGE r5, r5, r3
    MVNLT r3, r3
    ANDLT r5, r5, r3
        @ writing back value to DATA2_OUTPUT_ADDR
    STR r5, [r4]

    POP {r1, r2, r3, r4, r5}
    BX lr

.endif /* PMODB_S */