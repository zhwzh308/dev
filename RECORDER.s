.equ TIMER, 0x10002000
.equ ADDR_7SEG2, 0x10000030
.equ ADDR_PUSHBUTTONS, 0x10000050
.equ LCD_DISPLAY, 0x10003050
.equ AUDIO_CODEC, 0x10003040
.equ RED_LED_BASE, 0x10000000
.equ GREEN_LED_BASE, 0x10000010
.equ PUSHBUTTON_BASE, 0x10000050

.global _start
.org 0x20	# Exception handler for (TIMER) and (PUSHBUTTON_Debounced)
	rdctl et, ipending		# Check if external interrupt occurred;
	beq et, r0, OTHER_EXCEPTIONS	# If zero, check exceptions
			/* instruction upon return to main program */
	andi r8, et, 0b0000011		# Check if irq0, 1, and/or 6 are asserted using bitwise and.
	beq r8, r0, OTHER_EXCEPTIONS	# If not, check other external interrupts
	br WHAT_INTERRUPT
HEX_MOVE:
	ldwio r20, 0(r6)
	stwio r20,0(r3)		/* Write to 7-seg display */
	addi r6, r6, 4		# move to next display.
	beq r20, r0, END_TIME
	ret
WHAT_INTERRUPT:
	movui r20, 1
	andi r8, et, 0b01	# Check timer interrupt
	beq r8, r20, EXT_IRQ0
	movi r20, 2
	andi r8, et, 0b10	# Check for pushbutton interrupt
	beq r8, r20, EXT_IRQ1
	br END_HANDLER		/* Done with hardware interrupts */
OTHER_EXCEPTIONS:
	eret # We don't care about other interrupts.
END_HANDLER: # Ready to return PC to main program
	stwio r0, 0(r2)	Make sure time is not requesting new Interrupt.
	eret	# Now we are safe to return.
EXT_IRQ0: # Timer interrupt
	# Increment the recording time by 1 second.
	stwio r0, 0(r2)		# Clear the interrupt.
	movui r8, 0x02fa
	stwio r8, 12(r2)
	movui r8, 0xf080
	stwio r8, 8(r2)
	movia r8, 5
	stwio r8, 4(r2)		# Restart the count down when run.
	mov r8, ra
	call HEX_MOVE
	mov ra, r8
	subi ea, ea, 4			# Hardware interrupt, decrement ea to execute the interrupted instruction
	br END_HANDLER
EXT_IRQ1: # Pushbutton Interrupt
	movia r23, 0x2
	ldwio r19, 12(r4)	# Read in the edge reg
	stwio r0, 12(r4)	# clear the Edge reg
	beq r19, zero, END_HANDLER
	beq r19, r22, MOVSTOP
	beq r19, r23, MOVREC
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

.text
_start:
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
	movia r9, RED_LED_BASE
	movia r10, 0x3ffff
	stwio r10, 0(r9)	# Ignit all RED_LEDS
	movia r10, RED_LED_PATTERN
	movia r11, GREEN_LED_BASE
	movia r12, 0xFF
	stwio r12, 0(r11)	# All Green LEDs
	movia r12, GREEN_LED_PATTERN
	movia r13, AUDIO_CODEC # Contains the base address of audio codec.
	movia r14, AUDIO_FILE
	movia r15, 0x7ff000	# File size
	mov r16, r14		# Current Write
	mov r17, r14		# Current play

# r2 - r17, r23 are reserved.

WELCOME:			# Control flows here.
	mov r7, zero		# Idle
	movui r21, 0x8
	movui r22, 0x4
	movia r8, welcome	# Addr for string
	call MOVE
idle:	# I wait for interrupt :)
	br idle
PLAY:
	movui r7, 0x1		# Run
	stwio r0, 0(r2)		# Clear TO bit
	movia r20, 1
	wrctl status, r20	# Renable PIE bit.
	movia r8, 0x5
	stwio r8, 4(r2)		# Run the timer with IRQ
	call LCD_CLEAN
	movia r8, play		# Move play label to r5
	call MOVE
	add r23, r14, r15	# EOF
	br data_read
RECORD:
	movia r7, 0x1		# Run
	stwio r0, 0(r2)		# Clear TO bit
	movia r20, 1
	wrctl status, r20	# Renable PIE bit.
	movia r8, 0x5
	stwio r8, 4(r2)		# Run the timer with IRQ
	call LCD_CLEAN
	movia r8, recording
	call MOVE		# LCD message location
	add r23, r14, r15	# EOF
	br SAMPLE
STOP:
	mov r7, zero		# This is idle
	stwio r0, 0(r2)		# Clear timer TO bit
	movia r20, 1
	wrctl status, r20	# Renable PIE bit.
	movia r8, 0x8
	stwio r8, 4(r2)		# Stop timer and disable interrupt.
	call LCD_CLEAN
	movia r8, stop		# LCD message location
	call MOVE
	movia r6, DIGITS
	mov r16, r14
	mov r17, r14
	br idle
PAUSE:
	mov r7, zero		# This is idle
	stwio r0, 0(r2)		# Clear timer TO bit
	movia r20, 1
	wrctl status, r20	# Renable PIE bit.
	movia r8, 0x8
	stwio r8, 4(r2)		# Stop timer and disable interrupt.
	call LCD_CLEAN
	movia r8, pause		# LCD message again
	call MOVE
	br idle
# All LCD messages are printed by loop, hehe

MOVE:	# Print info on LCD
	ldbio r20, 0(r8) # r9 has the word in mem(r5)
	stbio r20, 1(r5) # Write char to LCD
	addi r8, r8, 1
	ldbio r20, 0(r8) # r12 is the switch.
	bne r20, zero, MOVE
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
	br _start

SAMPLE:	ldwio r19,4(r13)	/* Read fifospace register */
	andi  r19,r19,0xff	/* Extract # of samples in Input Right Channel FIFO */
	beq   r19,r0,SAMPLE	/* If no samples in FIFO, go back to start */
	ldwio r19,8(r13)
	stwio r19,8(r13)	/* Echo to left channel */
	movia r20, 18		# for 18 times
	movia r18, 0xffff	# Max. Volume
	and r19, r19, r18
	mov r8, zero
LEVEL_1:
	add r8, r8, r19		# Sample * 18 then devide by full volumn, obtain the level.
	subi r20, r20, 1
	bge r20, zero, LEVEL_1	# next is division
LEVEL_2:
	sub r8, r8, r18		# r18 has 0xffff
	addi r20, r20, 1
	bgt r8, zero, LEVEL_2
RED_SWITCH:
	add r20, r20, r20
	add r20, r20, r20
	add r20, r20, r10	# r10 is pattern
	ldwio r20, 0(r20)
	stwio r20, 0(r9)	# Shine the light
data_write: # Recording
	ldwio r19,12(r13)
	stwio r19,12(r13)	/* Echo to right channel */
	stwio r19, 0(r16)	# r19 has the sample. Recording is in MONO!
	addi r16, r16, 4	# One cycle done, prepare for next sample.
	call LIGHT_SWITCH	# Switch light to indicate memory status.
	blt r16, r23, SAMPLE	# If less than then branch until the mem is filled.
	sthio r0, 0(r16)	# Write the EOF to the recording.
	br STOP

LIGHT_SWITCH:
	sub r18, r16, r14	# r16-r14 = current size
				# We start with multiplication, muli r18, r18, 8
	add r18, r18, r18
	add r18, r18, r18
	add r18, r18, r18
# Division LOOP for implementing: r18/r15, mem use percentage
	mov r20, r0	# Clear R20 to accumulate result (counter)
DIV:	sub r18, r18, r15 # R15 == file size
	addi r20, r20, 1
	bgt r18, r15, DIV	# r20 = r20 * 4, for the offset
	add r20, r20, r20
	add r20, r20, r20
	add r20, r20, r12	# r12 for the addr of pattern with offset
	ldwio r20, 0(r20)	# r12 has the content
	stwio r20, 0(r11)	# load to r11 GREEN_LED_BASE
	ret

data_read: # Load the LCD first
	ldwio r19, 4(r13)		# Read from the audio codec (for the synced playback)
	andi r19,r19,0xff		# Only need last 1 byte
	beq r19, zero, data_read	# If no samples keep looking for them
	movia r19, 0x0		# Clear the reg for reading
	/* This segment of code keeps the playing rate and sample rate sync'ed. */
	ldwio r19, 0(r17)	# Play from r8 till end
	# File read from the mem.
	ldwio r18,8(r13)		# This is to sync time, what ever in r18 does not matter.
	stwio r19,8(r13)		# Left channel
	ldwio r18,12(r13)		# same reason.
	stwio r19,12(r13)		# Right channel
	call READING		# Pattern Solved by the function
	addi r17, r17, 4
	blt r8, r23, data_read	# r8 < r23, continue read.
	br STOP

READING:	# r12 has the base pattern addr.
	sub r18, r23, r17	# r18 = r23 - r17 is the sizeof audio file in bytes.

# We start with multiplication, muli r10, r10, 0x8
	add r18, r18, r18
	add r18, r18, r18
	add r18, r18, r18

# Division LOOP for implementing: div r7, r5, r6 # r7 = r5/r6, mem use percentage

	movi r20, 0	# Clear R11 to accumulate result (counter)
	mov r19, ra
	call DIV
	mov ra, r19
	ret
.data
# No need to align strings
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

.align 2
GREEN_LED_PATTERN:
	.word 0x0
	.word 0x1	# 1 light
	.word 0x3	# 2 lights
	.word 0x7	# 3 lights
	.word 0xf	# 4 lights
	.word 0x1f	# 5 lights
	.word 0x3f	# 6 lights
	.word 0x7f	# 7 lights
.align 2
RED_LED_PATTERN:
	.word 0x1
	.word 0x3
	.word 0x7
	.word 0xf
	.word 0x1f
	.word 0x3f
	.word 0x7f
	.word 0xff
	.word 0x1ff
	.word 0x3ff
	.word 0x7ff
	.word 0xfff
	.word 0x1fff
	.word 0x3fff
	.word 0x7fff
	.word 0xffff
	.word 0x1ffff
	.word 0x3ffff

.global AUDIO_FILE
.align 2
AUDIO_FILE:
	.skip 0x7ff000

