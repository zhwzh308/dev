.equ TIMER, 0x10002000
.equ RED_LEDS, 0x10000000
.equ ADDR_7SEG2, 0x10000030
.equ ADDR_PUSHBUTTONS, 0x10000050
.equ LCD_DISPLAY, 0x10003050
/************************************************************************
 *tutorial: LCD								*
 *	shift left: 0x18						*
 *	shift right: 0x1c						*
 *	cursor off: 0x0c						*
 *	cursor blink on: 0x0f						*
 *	clear: 0x01							*
 *TIMER	0x05F5E100 is one full second. for how long is still up to you. *
 *HEX	0x065B077F is for 7-seg, display 1278				*
 ************************************************************************/

.global INTERRUPT_LCD
.org 0x20
	/*	Exception handler	*/
			/**************************************
			 * Need to exam IRQ line bits 0 and 1 *
			 **************************************/
	# r4 is PUSHBUTTON_BASE
	rdctl et, ipending		# Check if external interrupt occurred; et(r24): Exception Temporary
	beq et, r0, OTHER_EXCEPTIONS	# If zero, check exceptions
			/* instruction upon return to main program */
	andi r13, et, 0b0000011		# Check if irq0, 1, and/or 6 are asserted using bitwise and.
	beq r13, r0, OTHER_EXCEPTIONS	# If not, check other external interrupts
	br WHAT_INTERRUPTS
HEX_MOVE:
	ldwio r10, 0(r6)
	stwio r10,0(r3)		/* Write to 7-seg display */
	addi r6, r6, 4		# move to next display.
	beq r10, r0, END_TIME
	ret
	/* If yes, check what is the source of interrupt. */
WHAT_INTERRUPTS:
	movui r10, 1
	andi r13, et, 0b01	# Check timer interrupt
	beq r13, r10, EXT_IRQ0
	movi r10, 2
	andi r13, et, 0b10	# Check for pushbutton interrupt
	beq r13, r10, EXT_IRQ1
	br END_HANDLER /* Done with hardware interrupts */

OTHER_EXCEPTIONS:
	eret # We don't care about other interrupts.

END_HANDLER: # Ready to return PC to main program
	stwio r0, 0(r2)
	eret /* Return from exception */
/* Interrupt-service routine for the desired hardware interrupt */
EXT_IRQ0: # Timer interrupt
	# Increment the recording time by 1 second.
	stwio r0, 0(r2)		# Clear the interrupt.
	movui r8, 0x02fa
	stwio r8, 12(r2)
	movui r8, 0xf080
	stwio r8, 8(r2)
	movia r8, 5
	stwio r8, 4(r2)		# Restart the count down when run.
	call HEX_MOVE
	subi ea, ea, 4			# Hardware interrupt, decrement ea to execute the interrupted
	br END_HANDLER /* Return from the interrupt-service routine */
EXT_IRQ1: # Pushbutton Interrupt
/****************************************************************************************
 * Requirement:										*
 *	1. Enable bit 8(ADDR_PUSHBUTTONS)'s bit 1-3 (DONE at begining of program)	*
 *	2. Load r2 with 0(ADDR_PUSHBUTTONS) (DONE at the begining of exception)		*
 *	3. Check which button is pushed (checking)					*
 *	4. Update LCD	(br to corresponding label)					*
 *	5. Clear 12(ADDR_PUSHBUTTONS) b4 exiting interrupt handler			*
 ****************************************************************************************/
	# Assume r4 has ADDR_PUSHBUTTONS
	ldwio r9, 12(r4)	# Read in the edge reg
	stwio r0, 12(r4)	# clear the Edge reg
	beq r9, zero, END_HANDLER
	beq r9, r22, MOVSTOP
	beq r9, r23, MOVREC
	beq r7, r0, MOVPLAY
	movia ea, PAUSE
MOVSTOP:
	movia ea, STOP
	br END_HANDLER
MOVREC:
	movia ea, RECORD
	br END_HANDLER
MOVPLAY:
	movia ea, PLAY
	br END_HANDLER

.data
welcome:
.string "Welcome!"
recording:
.string "Recording..."
stop:
.string "Stopped."
play:
.string "Playing..."
pause:
.string "Paused."
	/********************************
	 *	HEX LUP:		*
	 *	0: 0b00111111, 0x3F	*
	 *	1: 0b00000110, 0x06	*
	 *	2: 0b01011011, 0x5B	*
	 *	3: 0b01001111, 0x4F	*
	 *	4: 0b01100110, 0x66	*
	 *	5: 0b01101101, 0x6D	*
	 *	6: 0b01111101, 0x7D	*
	 *	7: 0b00000111, 0x07	*
	 *	8: 0b01111111, 0x7f	*
	 *	9: 0b01101111, 0x6F	*
	 ********************************/
.align 2
DIGITS:
.word 0x3f3f3f3f
.word 0x3f3f3f06
.word 0x3f3f3f5b
.word 0x3f3f3f4f
.word 0x3f3f3f66
.word 0x3f3f3f6d
.word 0x3f3f3f7d
.word 0x3f3f3f07
.word 0x3f3f3f7f
.word 0x3f3f3f6f # 09
.word 0x3f3f063f
.word 0x3f3f0606
.word 0x3f3f065b
.word 0x3f3f064f
.word 0x3f3f0666
.word 0x3f3f066d
.word 0x3f3f067d
.word 0x3f3f0607
.word 0x3f3f067f
.word 0x3f3f066f # 19
.word 0x3f3f5b3f
.word 0x3f3f5b06
.word 0x3f3f5b5b
.word 0x3f3f5b4f
.word 0x3f3f5b66
.word 0x3f3f5b6d
.word 0x3f3f5b7d
.word 0x3f3f5b07
.word 0x3f3f5b7f
.word 0x3f3f5b6f # 29
.word 0x3f3f4f3f
.word 0x3f3f4f06
.word 0x3f3f4f5b
.word 0x3f3f4f4f
.word 0x3f3f4f66
.word 0x3f3f4f6d
.word 0x3f3f4f7d
.word 0x3f3f4f07
.word 0x3f3f4f7f
.word 0x3f3f4f6f # 39
.word 0x3f3f663f
.word 0x3f3f6606
.word 0x3f3f665b
.word 0x3f3f664f
.word 0x3f3f6666
.word 0x3f3f666d
.word 0x3f3f667d
.word 0x3f3f6607
.word 0x3f3f667f
.word 0x3f3f666f # 49
.word 0x3f3f6d3f
.word 0x3f3f6d06
.word 0x3f3f6d5b
.word 0x3f3f6d4f
.word 0x3f3f6d66
.word 0x3f3f6d6d
.word 0x3f3f6d7d
.word 0x3f3f6d07
.word 0x3f3f6d7f
.word 0x3f3f6d6f # 59
.word 0x3f063f3f # 0x3f063f06, 0x3f063f5b, 0x3f063f4f, 0x3f063f66, 0x3f063f6d, 0x3f063f7d, 0x3f063f07, 0x3f063f7f, 0x3f063f6f,
.word 0x0 # counts one minute. HEX OFF.

.text

INTERRUPT_LCD:
/****************************************************
 * Warm up: enable all interrupts in this section.  *
 ****************************************************/
# Enable IRQ 0,1
	movia r2, 0x1
	wrctl status, r2
	movia r2, 0b00000011
	wrctl ienable, r2	# Check ipending in the exception handler
	/*******************************************
	 * Now let's start with hardware addresses *
	 *******************************************/
# Permenent regs: r2 (TIMER), r3 (ADDR_7SEG2), r4 (ADDR_PUSHBUTTONS) r5 (LCD)
	movia r2, TIMER
	movia r0, 0(r2)
	movia r0, 4(r2)		# Clear em timer up
	movia r3, ADDR_7SEG2
	movia r4, 0x3f3f3f3f
	stwio r4, 0(r3)		# put 0000 on the timer.
	movia r4, ADDR_PUSHBUTTONS
	stwio r0, 12(r4)	# Clear EDGE Capture regs.	
	movia r5, 0b1110
	stwio r5, 8(r4)		# Enable Interrupt mask for push buttons
	movia r5, LCD_DISPLAY
	movia r6, DIGITS	# Hex counter mem
	movia r7, 0x0		# FSM for run/idle.
# ABOVE regs are permanant, r8 and after available
TIMER_INITIALIZATION:		# Initialize timer for 1 second count, But don't come back to this point!
	movui r8, 0x02fa
	stwio r8, 12(r2)
	movui r8, 0xf080
	stwio r8, 8(r2)		# SET the Timer.
	/*      Not Counting Yet!      */
# Old timer, Disgard.
/****************************************************************************************
 *	stwio r0,16(r11)	Tell Timer to take a snapshot of the timer 		*
 *	ldwio r3,16(r11)	Read snapshot bits 0..15 				*
 *	ldwio r4,20(r11)	Read snapshot bits 16...31 				*
 *	slli  r4,r4,16		Shift left logically					*
 *	or    r4,r4,r3		Combine bits 0...15 and 16...31 into one register	*
 *	bne r4, r5, LOOP								*
 *	ret	# Return to the addr of caller						*
 ****************************************************************************************/

WELCOME:			# Control flows here.
	mov r7, zero		# Idle
	movui r21, 0x8
	movui r22, 0x4
	movui r23, 0x2		# Parameter
	movia r8, welcome	# Addr for string
	call MOVE
idle:	# I wait for interrupt :)
	br idle
PLAY:
	movui r7, 0x1		# Run
	stwio r0, 0(r2)		# Clear TO bit
	movia r10, 1
	wrctl status, r10	# Renable PIE bit.
	movia r8, 0x5
	stwio r8, 4(r2)		# Run the timer with IRQ
	call LCD_CLEAN
	movia r8, play		# Move play label to r5
	call MOVE
	br idle			# Wait for now, br data_read later
RECORD:
	movia r7, 0x1		# Run
	stwio r0, 0(r2)		# Clear TO bit
	movia r10, 1
	wrctl status, r10	# Renable PIE bit.
	movia r8, 0x5
	stwio r8, 4(r2)		# Run the timer with IRQ
	call LCD_CLEAN
	movia r8, recording
	call MOVE		# LCD message location
	br idle
	# br data_write later.
STOP:
	mov r7, zero		# This is idle
	stwio r0, 0(r2)		# Clear timer TO bit
	movia r10, 1
	wrctl status, r10	# Renable PIE bit.
	movia r8, 0x8
	stwio r8, 4(r2)		# Stop timer and disable interrupt.
	call LCD_CLEAN
	movia r8, stop		# LCD message location
	call MOVE
	br idle
PAUSE:
	mov r7, zero		# This is idle
	stwio r0, 0(r2)		# Clear timer TO bit
	movia r10, 1
	wrctl status, r10	# Renable PIE bit.
	movia r8, 0x8
	stwio r8, 4(r2)		# Stop timer and disable interrupt.
	call LCD_CLEAN
	movia r8, pause		# LCD message again
	call MOVE
	br idle
# All LCD messages are printed by loop, hehe

MOVE:	# Print info on LCD
	ldbio r9, 0(r8) # r9 has the word in mem(r5)
	stbio r9, 1(r5) # Write char to LCD
	addi r8, r8, 1
	ldbio r9, 0(r8) # r12 is the switch.
	bne r9, zero, MOVE
	ret	# Return to the addr of caller

LCD_CLEAN:
	movui	r8,0x1
	stbio r8, 0(r5)	# This will clean LCD
	ret	# Return to the addr of caller
/* all chars should be on the display. */

END_TIME:
	# CLEAR ALL INTERRUPT
	wrctl status, r0
	call LCD_CLEAN
	br INTERRUPT_LCD

