#ifndef SWITCHES_H
#define SWITCHES_H

#include <stdint.h>
#include <sleep.h>


#define BUTTON_BASEADDR 0x41200000
#define SWITCH_BASEADDR 0x41220000

uint32_t get_switches();
uint32_t get_buttons();
int32_t wait_for_next_button(uint32_t timeout_millis);

void switch_test();
void button_test();



#endif // SWITCHES_H