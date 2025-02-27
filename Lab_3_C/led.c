#include "led.h"

/*************************************************************
 * Function: void set_rgb_color(uint32_t, uint32_t,          *
 *                              uint32_t, uint32_t)          *   
 * Date Created: January 24, 2025                            *   
 * Date Last Modified: January 24, 2025                      *   
 * Description: This function sets the color and intensity   *
 *              of RGB LEDs 10 or 11.  Values from 0-1024    *
 *               are valid                                   * 
 * Input parameters: LED, red val, green val, blue val.      *   
 * Returns: None                .                            *                       
 * Usages: Used to set the color and intensity of RGB LEDs   *           
 * Preconditions: None                                       *   
 * Postconditions: RGB LED color and intensity set.          *   
 *************************************************************/

void set_rgb_color(uint32_t LED, uint32_t red, uint32_t green, uint32_t blue)
{

        //Setting the period on every color of RGBs to 1024
    for(int i = 0; i < 6; i++ )
    {
        *((uint32_t*)(RGB_BASEADDR + RGB_PERIOD_OFFSET + i * RGB_COLOR_OFFSET)) = 1024;
    }

        //Setting color of RGB by setting pulse width of colors based on input colors and LED
    switch (LED) 
    {    
        case 10:
        {
            *((uint32_t*)(RGB10_BASEADDR + RGB_RED_OFFSET + RGB_WIDTH_OFFSET)) = red;
            *((uint32_t*)(RGB10_BASEADDR + RGB_GREEN_OFFSET + RGB_WIDTH_OFFSET)) = green;
            *((uint32_t*)(RGB10_BASEADDR + RGB_BLUE_OFFSET + RGB_WIDTH_OFFSET)) = blue;  
            break;                  
        }
        case 11:
        {
            *((uint32_t*)(RGB11_BASEADDR + RGB_RED_OFFSET + RGB_WIDTH_OFFSET)) = red;
            *((uint32_t*)(RGB11_BASEADDR + RGB_GREEN_OFFSET + RGB_WIDTH_OFFSET)) = green;
            *((uint32_t*)(RGB11_BASEADDR + RGB_BLUE_OFFSET + RGB_WIDTH_OFFSET)) = blue;  
            break; 
        }
    }
}

/*************************************************************
 * Function: void set_led(uint32_t, bool)                    *   
 * Date Created: January 24, 2025                            *   
 * Date Last Modified: January 24, 2025                      *   
 * Description: This function turns LEDs 0-11 on or off      *
 *              individually.  This includes RGB LEDs.       * 
 * Input parameters: LED, enable/disable                     *   
 * Returns: None                .                            *                       
 * Usages: Used to turn LEDs on/off individually             *           
 * Preconditions: None                                       *   
 * Postconditions: Selected LED set to on/off                *   
 *************************************************************/

void set_led(uint32_t LED, bool enable)
{
        //Turining on/off selected green LED if input is 1-9
    if(LED <= 9)
    {
        *((uint32_t*)LED_BASEADDR) = enable << LED;
    }
        //Turining on all colors of LED 10 if input is 10
    if(LED == 10)
    {
        *((uint32_t*)(RGB10_BASEADDR + RGB_RED_OFFSET)) = enable;        
        *((uint32_t*)(RGB10_BASEADDR + RGB_BLUE_OFFSET)) = enable;
        *((uint32_t*)(RGB10_BASEADDR + RGB_GREEN_OFFSET)) = enable;
    }
        //Turining on all colors of LED 11 if input is 11
    if(LED == 11)
    {
        *((uint32_t*)(RGB11_BASEADDR + RGB_RED_OFFSET)) = enable;        
        *((uint32_t*)(RGB11_BASEADDR + RGB_BLUE_OFFSET)) = enable;
        *((uint32_t*)(RGB11_BASEADDR + RGB_GREEN_OFFSET)) = enable;
    }
}

/*************************************************************
 * Function: void set_leds_10bit(uint32_t)                   *   
 * Date Created: January 24, 2025                            *   
 * Date Last Modified: January 24, 2025                      *   
 * Description: This function turns on/off all LEDs 0-9 by   *
 *              writing to LED register.                     * 
 * Input parameters: 10-bit binary value to display on LEDs. *   
 * Returns: None                .                            *                       
 * Usages: Used to turn LEDs 0-9 on/off as a set.            *           
 * Preconditions: None                                       *   
 * Postconditions: 10-bit binary value displaed on LEDs.     *   
 *************************************************************/

void set_leds_10bit(uint32_t value)
{
        //Setting LED register to input value and masking off unused bits
    *((uint32_t*)LED_BASEADDR) = value & 0b1111111111;
}

/*************************************************************
 * Function: void set_leds_12bit(uint32_t)                   *   
 * Date Created: January 24, 2025                            *   
 * Date Last Modified: January 24, 2025                      *   
 * Description: This function turns on/off all LEDs 0-11 by  *
 *              writing to LED register.                     * 
 * Input parameters: 12-bit binary value to display on LEDs. *   
 * Returns: None                .                            *                       
 * Usages: Used to turn LEDs 0-11 on/off as a set.           *           
 * Preconditions: None                                       *   
 * Postconditions: 12-bit binary value displaed on LEDs.     *   
 *************************************************************/

void set_leds_12bit(uint32_t value)
{
        //Setting LEDs 1-9 based on input value
    set_leds_10bit(value);

        //Turning LED10 on/off depending on value of 11th bit of LED_value
    set_led(10, (value & 0b10000000000));

        //Turning LED11 on/off depending on value of 11th bit of LED_value
    set_led(11, (value & 0b100000000000));
}

    //Tests all functions shown above.  Results shown on LEDs.
void led_test()
{
        //Testing individual colors and RGB mixed, testing incorrect inputs (9 and 12)
    for(int i = 9; i < 13; i++)
    {
        set_led(i, true);
        set_rgb_color(i, 100, 0, 0);
        usleep(250000);
        set_rgb_color(i, 0, 100, 0);
        usleep(250000);
        set_rgb_color(i, 0, 0, 100);
        usleep(250000);
        set_rgb_color(i, 100, 100, 100);
        set_led(i, false);
    }

    for(int i = -1; i < 13; i++)
    {
        set_led(i, true);
        usleep(250000);
        set_led(i, false);
    }

    set_leds_10bit(0x1FF);
    usleep(250000);
    set_leds_10bit(0);
    usleep(250000);


    int i = 1;

    while(i < 0xFFF)
    {
        set_leds_10bit(i);
        usleep(250000);
        i = i*2;
    }

    set_leds_12bit(0xFFF);
    usleep(250000);
    set_leds_12bit(0);
    usleep(250000);

    i = 1;
    
    while(i < 0xFFFF)
    {
        set_leds_12bit(i);
        usleep(250000);
        i = i*2;
    }

}