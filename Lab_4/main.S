
 .include "../src/robomal.S"

 .global main

 .text

 main:

	# want our embedded system to run forever
	# Just runs the ROBO-MAL 16-bit MCU emulator
	whileOne:
		BL runROBO_Program

	B whileOne


.end
