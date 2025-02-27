#ifndef LED_H
#define LED_H

#include <stdbool.h>
#include <stdint.h>
#include <sleep.h>

#define LED_BASEADDR 0x41210000

#define RGB_BASEADDR 0x43C00000
#define RGB10_BASEADDR 0x43C00000
#define RGB11_BASEADDR 0x43C00030
#define RGB_BLUE_OFFSET 0x0
#define RGB_GREEN_OFFSET 0x10
#define RGB_RED_OFFSET 0x20
#define RGB_ENABLE_OFFSET 0x0
#define RGB_PERIOD_OFFSET 0x4
#define RGB_WIDTH_OFFSET 0x8
#define RGB_COLOR_OFFSET 0x10

void set_rgb_color(uint32_t LED, uint32_t red, uint32_t green, uint32_t blue);
void set_led(uint32_t LED, bool enable);
void set_leds_10bit(uint32_t value);
void set_leds_12bit(uint32_t value);

void led_test();

#endif // LED_H