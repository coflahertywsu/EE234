#include "pmodb.h"
#include <stdint.h>

/*************************************************************
 * Function: void pmod_set_pin_directions(uint32_t)          *
 * Description: This function sets the directions of the     *
 *              PMODB pins by updating the direction and     *
 *              output enable registers.                     *
 * Input parameters: pin_directions - Bitmask representing   *
 *                   the directions of the pins. Each bit    *
 *                   corresponds to a pin (1 for output,     *
 *                   0 for input).                           *
 * Returns: None                                             *
 *************************************************************/
void pmod_set_pin_directions(uint32_t pin_directions)
{
       // Clearing PMODB pins w/o affecting other pins
    *((uint32_t*)DATA2_DIR) &= ~PMODB_MASK;
    *((uint32_t*)DATA2_OUT_EN) &= ~PMODB_MASK;

        // Setting PMODB pins to desired direction w/o affecting other pins 
        // by shifting and masking
    *((uint32_t*)DATA2_DIR) |= (pin_directions << 7);
    *((uint32_t*)DATA2_OUT_EN) |= (pin_directions << 7);
}

/*************************************************************
 * Function: void pmod_set_pin_direction(uint8_t, uint8_t)   *
 * Description: This function sets the direction of a        *
 *              specific PMODB pin.                          *
 * Input parameters: pin - The pin number (1-8).             *
 *                   direction - The direction (0 for input, *
 *                   1 for output).                          *
 * Returns: None                                             *
 *************************************************************/
void pmod_set_pin_direction(uint8_t pin, uint8_t direction)
{
        // Convinience function to set direction of individual pmodb pin
    pmod_set_pin_directions((direction & 1) << (pin - 1));
}

/*************************************************************
 * Function: uint8_t pmod_read_pins()                        *
 * Description: This function reads the input state of all   *
 *              PMODB pins.                                  *
 * Input parameters: None                                    *
 * Returns: uint8_t - Bitmask representing the state of the  *
 *          pins. Each bit corresponds to a pin (1 for high, *
 *          0 for low).                                      *
 *************************************************************/
uint8_t pmod_read_pins()
{
        // Returning value associate with PMODB pins by shifting and masking
    return (*((uint32_t*)DATA2_INPUT_ADDR) & PMODB_MASK) >> 7;
}

/*************************************************************
 * Function: uint8_t pmod_read_pin(uint8_t)                  *
 * Description: This function reads the input state of a     *
 *              specific PMODB pin.                          *
 * Input parameters: pin - The pin number (1-8).             *
 * Returns: uint8_t - The state of the pin (0 for low,       *
 *          1 for high).                                     *
 *************************************************************/
uint8_t pmod_read_pin(uint8_t pin)
{
        // Returning only the desired pin's value
    return (pmod_read_pins() >> (pin - 1)) & 1;
}

/*************************************************************
 * Function: void pmod_write_pins(uint32_t)                  *
 * Description: This function writes values to the PMODB     *
 *              pins by updating the output register.        *
 * Input parameters: value - Bitmask representing the values *
 *                   to write to the pins. Each bit          *
 *                   corresponds to a pin (1 for high,       *
 *                   0 for low).                             *
 * Returns: None                                             *
 *************************************************************/
void pmod_write_pins(uint32_t value)
{       // Setting only DATA2 pins associated with PMODB to value
    *((uint32_t*)DATA2_OUTPUT_ADDR) &= (((uint32_t)value << 7) | ~PMODB_MASK);
}

/*************************************************************
 * Function: void pmod_write_pin(uint8_t, uint8_t)           *
 * Description: This function writes a value to a specific   *
 *              PMODB pin.                                   *
 * Input parameters: pin - The pin number (1-8).             *
 *                   value - The value to write (0 for low,  *
 *                   1 for high).                            *
 * Returns: None                                             *
 *************************************************************/
void pmod_write_pin(uint8_t pin, uint8_t value)
{
        // Creating mask so only desired pin is affected
    uint32_t mask = 1 << (pin + 6);  

    if (value)
    {
            // Set bit if value is 1 (or greater)
        *((uint32_t*)DATA2_OUTPUT_ADDR) |= mask;  
    }        
    else
    {
            // Clear bit if value is 0
        *((uint32_t*)DATA2_OUTPUT_ADDR) &= ~mask;  
    }
}