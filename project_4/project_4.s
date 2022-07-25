	.data

	.global output
	.global input
	.global prompt0
	.global prompt1
	.global prompt2


output:		.string "*                    ", 13, 0
input:		.string "s", 0
prompt0:	.string "Press 'a' to move left", 10, 13, 0
prompt1:	.string "Press 's' to move right", 10, 13, 0
prompt2:	.string "Press 'q' to quit", 10, 13, 10, 13, 0

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
ptr_to_input:		.word input
ptr_to_prompt0:		.word prompt0
ptr_to_prompt1:		.word prompt1
ptr_to_prompt2:		.word prompt2


project4:
	PUSH {lr}   ; Store lr to stack

	; display user prompts
	ldr r0, ptr_to_prompt0
	bl output_string
	ldr r0, ptr_to_prompt1
	bl output_string
	ldr r0, ptr_to_prompt2
	bl output_string

	; load input address into register 4
	ldr r4, ptr_to_input

	; initialize UART0 & timer for interrupts
	bl UART0_init
	bl timer_init

	; continue program until user input is 'q'
loop:
	ldrb r5, [r4]
	cmp r5, #0x71
	bne loop

	POP {pc}	  		; Restore lr from stack




UART0_init:

	mov r0, #0xC000			; load the UART0 base address
	movt r0, #0x4000		; into register
	ldrb r1, [r0, #UART0IM]	; load first byte of interrupt mask register
	orr r1, r1, #0x10		; Set the Receive Interrupt Mask (RXIM) bit
	strb r1, [r0, #UART0IM]	; Store the updated RXIM bit value

	mov r0, #0xE000			; load the Interrupt 0-31 Set Enable Register
	movt r0, #0xE000		; base address into register
	ldrb r1, [r0, #EN0]		; load the first byte of Set Enable Register
	orr r1, r1, #0x20		; Set UART0 bit, which is bit 5
	strb r1, [r0, #EN0]

	mov pc, lr

UART0_Handler:

	; first, we clear the interrupt
	mov r3, #0xC000				; load the UART0 base address
	movt r3, #0x4000			; into register 3
	ldrb r2, [r3, #UART0ICR]	; load first byte of uart0 interrupt clear register
	orr r2, r2, #0x10			; Set the bit 4 (RXIC) in the UART Interrupt Clear Register (UARTICR)
	strb r2, [r3, #UART0ICR]	; Set the UART0 bit, which is bit 4

	; next, we handle the interrupt
	push {lr}
	bl read_character			; collect user input
	pop {lr}
	cmp r0, #0x61				; ascii 'a'
	beq good_input				; this is an acceptable input
	cmp r0, #0x71				; ascii 'q'
	beq good_input				; this is an acceptable input
	cmp r0, #0x73				; ascii 's'
	beq good_input				; this is an acceptable input
	b finish					; if input is invalid, don't change movement direction

good_input:
	ldr r3, ptr_to_input		; load input address from memory into register 3
	strb r0, [r3]				; store the input at correct memory address

finish:

	bx lr   					; Return from Handler


Switches_Handler:

	; This is a place holder for a switch interrupt handler
	; Not required for project 4.


	bx lr   ; Return (remember, don't use mov pc,lr to return from a handler)



Timer_Handler:

	push {r4-r11}

	; clear the interrupt
	mov r0, #0
	movt r0, #0x4003
	ldrb r1, [r0, #0x024]
	orr r1, r1, #1
	strb r1, [r0, #0x024]

	; load pointer to user input
	; so we can determine direction of movement
	ldr r0, ptr_to_input
	ldrb r1, [r0]			; load input character into register 1

	ldr r0, ptr_to_output	; load the memory address of the output into register 0
	mov r2, #0x0			; character counter
begin:
	add r2, r2, #0x1		; increment character counter
	ldrb r3, [r0], #1		; load current character into register 3, increment pointer after
	cmp r3, #0x2A			; compare the value in r3 with ascii '*' value
	bne begin				; if we have not found the '*' character, repeat

	cmp r1, #0x61			; if user input is ascii 'a'
	beq move_left			; '*' moves left
							; otherwise, '*' moves right

	; moving right
move_right:
	cmp r2, #0x15			; if character count is 21
	beq return				; we cannot move the '*' further right
	mov r1, #0x2A			; store the ascii '*' in new loacation
	strb r1, [r0]			; pointer was incremented by one after ldrb
							; so it points to the new location
	mov r1, #0x20			; ascii ' ' character
	sub r0, r0, #0x1		; decrement pointer by 1 before storing
	strb r1, [r0]			; replacing previous '*' position
	b return

	; moving left
move_left:

	cmp r2, #0x1			; if character counter is 1
	beq	return				; we cannot move the '*' further left
	sub r0, r0, #0x2		; decrement pointer by two
							; so it points to the new '*' location
	mov r1, #0x2A			; store the ascii '*' in new loacation
	strb r1, [r0]
	mov r1, #0x20			; ascii ' ' character
	strb r1, [r0, #0x1] 	; increment pointer by 1, replace previous '*' position

return:
	ldr r0, ptr_to_output	; reload address to avoid any confusion regarding position
	push {lr}
	bl output_string		; display the updated output
	pop {lr}
	pop {r4-r11}
	bx lr   				; Return

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
