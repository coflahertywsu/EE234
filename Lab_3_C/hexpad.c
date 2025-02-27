#include "hexpad.h"
#include <stdint.h>

/************************************************************
 * Function: hexpad_init
 * Description: Initializes the hex keypad by setting the pin
 *              directions and writing initial values to the pins.
 * Input parameters: None
 * Returns: None
 ************************************************************/
void hexpad_init()
{
    pmod_set_pin_directions(0b00001111);
    pmod_write_pins(0b00001111);
}

/************************************************************
 * Function: parse_key_number
 * Description: Parses the row and column values to determine
 *              the corresponding key number on the hex keypad.
 * Input parameters: 
 *      - row: The row value of the key press
 *      - column: The column value of the key press
 * Returns: The key number corresponding to the row and column
 *          values, or -1 for null/invalid press.
 ************************************************************/
int32_t parse_key_number(uint32_t row, uint32_t column)
{
    if(row < 4 && column < 4)
    {
        return column + (row - 1) * 3;
    }
    else if(column == 4)                // Condition key is A-D
    {
        return row + 9;
    }
    else if(row == 4 && column == 1)
    {
        return 0;
    }
    else if(row == 4 && column < 4)
    {
        return 17 - column;
    }
    else
    {
        return -1;
    }
}

/************************************************************
 * Function: get_hexkey
 * Description: Reads the hex keypad to determine which key
 *              has been pressed.
 * Input parameters: None
 * Returns: The key number corresponding to the pressed key,
 *          or -1 if no valid key press is detected.
 ************************************************************/
int32_t get_hexkey()
{
    uint32_t column = 0;
    uint32_t row = 0;

    for(int i = 4; i >= 1; i--)
    {
        for(int j = 8; j >= 5; j--)
        {
            pmod_write_pin(i, 0);

            if(!pmod_read_pin(j))
            {
                column = 5 - i;
                row = 9 - j;
            }
                
            pmod_write_pin(i, 1);
        }
    }

    return parse_key_number(row, column);
}

/************************************************************
 * Function: wait_for_next_hexkey
 * Description: Waits indefinitely for the next valid hex key
 *              press.
 * Input parameters: None
 * Returns: The key number corresponding to the pressed key.
 ************************************************************/
int32_t wait_for_next_hexkey()
{
    int32_t key_number = -1;

    while(key_number < 0)       
    {
        key_number = get_hexkey();
    }

    return key_number;
}