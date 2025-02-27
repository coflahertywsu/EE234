#ifndef HEXPAD_H
#define HEXPAD_H

#include <stdint.h>
#include <stdbool.h>
#include <sleep.h>
#include "pmodb.h"
#include "serial.h"

static bool hexpad_initialized = false;

void hexpad_init();
int32_t wait_for_next_hexkey();
int32_t get_hexkey();

#endif // HEXPAD_H