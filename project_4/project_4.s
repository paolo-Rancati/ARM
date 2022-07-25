	.data

	.global output

output:	.string "           *", 13, 0

	.text

	.global project4
	.global read_character
	.global output_character
	.global output_string
	.global timer_init
	.global Timer_Handler
	.global UART0_init
	.global UART0_Handler
	.global Switches_Handler

UART0IM:	.equ 0x038		; UART0 Interrupt Mask Register Offset
EN0:		.equ 0x100		; Interrupt 0-31 Set Enable Register ( EN0 ) Offset
UART0ICR:	.equ 0x044		; UART0 Interrupt Clear Register Offset

ptr_to_output:		.word output


project4:
	PUSH {lr}   ; Store lr to stack

	;bl timer_init   ; When you are ready to enable the timer interrupt,
			 ; uncomment this line!

	bl UART0_init
	mov r5, #0x0
infinity:
	; ldr r0, ptr_to_output <-------- confirmed this works
	; bl output_string
	cmp r5, #0x1
	bne infinity


		; Your code is placed here.  This is your main routine for
		; Project #4.  This should call your other routines such as
		; read_from_push_button and illuminate_RGB_LED.

	POP {pc}


UART0_init:

	PUSH {r2-r3, lr}

	mov r3, #0xC000			; load the UART0 base address
	movt r3, #0x4000		; into register
	ldrb r2, [r3, #UART0IM]	; load first byte of interrupt mask register
	orr r2, r2, #0x10		; Set the Receive Interrupt Mask (RXIM) bit
	strb r2, [r3, #UART0IM]	; Store the updated RXIM bit value

	mov r3, #0xE000			; load the Interrupt 0-31 Set Enable Register
	movt r3, #0xE000		; base address into register
	ldrb r2, [r3, #EN0]		; load the first byte of Set Enable Register
	orr r2, r2, #0x20		; Set UART0 bit, which is bit 5
	strb r2, [r3, #EN0]

	POP {r2-r3, pc}


UART0_Handler:

	push {r4-r11}
	; first, we clear the interrupt
	mov r3, #0xC000				; load the UART0 base address
	movt r3, #0x4000			; into register
	ldrb r2, [r3, #UART0ICR]	; load first byte of uart0 interrupt clear register
	orr r2, r2, #0x10			; Set the bit 4 (RXIC) in the UART Interrupt Clear Register (UARTICR)
	strb r2, [r3, #UART0ICR]	; Set the UART0 bit, which is bit 4

	; next, we handle the interrupt
	push {lr}
	bl read_character			; collect user input
	pop {lr}

	pop {r4-r11}


	bx lr   ; Return (remember, don't use mov pc,lr to return from a handler)




Switches_Handler:

	; This is a place holder for a switch interrupt handler
	; Not required for project 4.


	bx lr   ; Return (remember, don't use mov pc,lr to return from a handler)



Timer_Handler:
	; The following code is to clear the timer interrupt.
	; Keep this at the beginning of the handler to allow enough time for
	; the reset to occur.

	mov r0, #0
	movt r0, #0x4003
	ldrb r1, [r0, #0x024]
	orr r1, r1, #1
	strb r1, [r0, #0x024]

	; Your code to handler the timer interrupt is placed here.

	bx lr   ; Return (remember, don't use mov pc,lr to return from a handler)

timer_init:
	; Enable Clock for Timer 0
	mov r0, #0xE000
	movt r0, #0x400F
	ldrb r1, [r0, #0x604]
	orr r1, r1, #1
	strb r1, [r0, #0x604]

	; Disable Timer0
	mov r0, #0
	movt r0, #0x4003
	ldrb r1, [r0, #0x00C]
	bic r1, r1, #1
	strb r1, [r0, #0x00C]


	; Put Timer in 32-bit Mode
	mov r0, #0
	movt r0, #0x4003
	mov r1, #0
	strb r1, [r0]

	; Put Timer in Periodic MOde
	mov r0, #0
	movt r0, #0x4003
	ldrb r1, [r0, #0x004]
	bic r1, r1, #1
	orr r1, r1, #2
	strb r1, [r0, #0x004]

	; Setup Interval Period
	mov r0, #0
	movt r0, #0x4003
	mov r1, #0x1200
	movt r1, #0x7A
	str r1, [r0, #0x028]

	; Enable Timer to Interrupt Processor
	mov r0, #0
	movt r0, #0x4003
	ldrb r1, [r0, #0x018]
	orr r1, r1, #1
	str r1, [r0, #0x018]


	; Configure Processor to Allow Timer to Interrupt Processor
	mov r0, #0xE000
	movt r0, #0xE000
	ldr r1, [r0, #0x100]
	orr r1, r1, #0x80000
	str r1, [r0, #0x100]

	; Enable Timer0
	mov r0, #0
	movt r0, #0x4003
	ldrb r1, [r0, #0x00C]
	orr r1, r1, #1
	strb r1, [r0, #0x00C]

	mov pc, lr

	.end
