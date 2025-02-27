#ifndef PMODB_H
#define PMODB_H

#include <stdint.h>

#define DATA2_OUTPUT_ADDR 0xE000A048
#define DATA2_INPUT_ADDR 0xE000A068
#define DATA2_DIR 0xE000A284
#define DATA2_OUT_EN 0xE000A288

#define PMODB_MASK 0x7F80

void pmod_set_pin_directions(uint32_t direction);
void pmod_set_pin_direction(uint8_t pin, uint8_t direction);
uint8_t pmod_read_pins();
uint8_t pmod_read_pin(uint8_t pin);
void pmod_write_pins(uint32_t value);
void pmod_write_pin(uint8_t pin, uint8_t value);





#endif // PMOD_H