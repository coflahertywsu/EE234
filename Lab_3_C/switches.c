#include "switches.h"
#include "led.h"

/*************************************************************
 * Function: uint32_t get_switches()                         *   
 * Date Created: January 24, 2025                            *   
 * Date Last Modified: January 24, 2025                      *   
 * Description: This function returns the value of the       *   
 *              swiches register,and masks off the unused    *
 *              bits.                                        *                    
 * Input parameters: None                                    *   
 * Returns: Status of switches 0-11                          *                       
 * Usages: Used to read the status of switches 0-11.         *           
 * Preconditions: None                                       *   
 * Postconditions: None                                      *   
 *************************************************************/

uint32_t get_switches()
{
    return *((uint32_t*)SWITCH_BASEADDR) & 0xFFF;
}

/*************************************************************
 * Function: uint32_t get_buttons()                          *   
 * Date Created: January 24, 2025                            *   
 * Date Last Modified: January 24, 2025                      *   
 * Description: This function returns the value of the       *   
 *              buttons register,and masks off the unused    *
 *              bits.                                        *                    
 * Input parameters: None                                    *   
 * Returns: Status of switches 0-3                           *                       
 * Usages: Used to read the status of buttons 0-3  .         *           
 * Preconditions: None                                       *   
 * Postconditions: None                                      *   
 *************************************************************/

uint32_t get_buttons()
{
    return *((uint32_t*)BUTTON_BASEADDR) & 0xF;
}

/*************************************************************
 * Function: int32_t wait_for_next_button(uint32_t)          *   
 * Date Created: January 24, 2025                            *   
 * Date Last Modified: January 24, 2025                      *   
 * Description: This function returns the number of the last *
 *              button that was pressed (0-3) or -1 if       *
 *              timout is reached                            * 
 * Input parameters: Timout.                                 *   
 * Returns: First button pressed.                            *                       
 * Usages: Used to get the value of the next button pressed. *           
 * Preconditions: None                                       *   
 * Postconditions: None                                      *   
 *************************************************************/

int32_t wait_for_next_button(uint32_t timeout_millis)
{

    for(uint32_t i = 0; i < (timeout_millis * 10); i++)
    {
        uint32_t buttons = get_buttons();        

        switch(buttons)
        {
            case 0b0001:
                return 0;
            
            case 0b0010:
                return 1;
            
            case 0b0100:
                return 2;

            case 0b1000:
                return 3;
        }

        usleep(100);
        
    }

    return -1;

}

    //Reads slide switches 0-11 and displays value on LEDs 0-11 for 10 seconds
void switch_test()
{
    for(int i = 0; i < 10000; i++)
    {
        set_leds_12bit(get_switches());
        usleep(1000);
    }  
}

    //Gets next button pressed and displays on LED x4, then displays active
    //  buttons pressed for 10 seconds
void button_test()
{
        //Testing phase: testing wait_for_next_button()
    for(int i = 0; i < 4; i++)
    {
        int button_pressed = wait_for_next_button(5000);
        set_led(button_pressed, true);
        sleep(2);
        set_led(button_pressed, false);        
    }
        //Turning all LEDs on then off to indicate swiching test phase
    set_leds_12bit(0xFFF);
    sleep(2);
    set_leds_12bit(0x0);
    sleep(2);
        //Testing phase: testing get_buttons()
    for(int i = 0; i < 10000; i++)
    {
        set_leds_10bit(get_buttons());
        usleep(1000);
    }
}