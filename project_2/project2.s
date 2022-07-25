	.data

	.global prompt

prompt:		.string "Please enter two lowercase letters: ", 0
input:		.string "__", 0
result_msg:	.string "Your alphabetized result is: ", 0
quit_msg:	.string "press 'q' to quit, or any other key to run program again", 0

	.text

	.global project2

U0FR: 	.equ 0x18	; UART0 Flag Register

ptr_to_prompt:		.word prompt
ptr_to_input:		.word input
ptr_to_result_msg:	.word result_msg
ptr_to_quit_msg:	.word quit_msg


project2:
	PUSH {lr}   ; Store lr to stack
	ldr r0, ptr_to_prompt	; register 0 stores pointer to prompt
	ldr r6, ptr_to_input	; r6 will store a pointer to the user input

	mov r1, #0xC000
	movt r1, #0x4000	; register 1 stores UART0 base address

	bl output_string	; display the prompt

	mov r4, #0x0		; counter for collecting user input

get_user_input:
	bl read_character	; get the chracter entered
	strb r0, [r6], #1	; store this character to input pointer address
	bl output_character	; output this character
	add r4, r4, #0x1	; increment counter
	cmp r4, #0x2		; when we have read and output two characters
	blt get_user_input	; we are finished collecting the input

	mov r0, #0x0A		; new line character
	bl output_character	; print a new line
	mov r0, #0x0D		; carriage return
	bl output_character	; print a carriage return

	ldr r0, ptr_to_result_msg	; register 0 stores pointer to result message

	bl output_string	; display the result message

	sub r6, r6, #0x2	; move r2 back two bytes
	ldrb r4, [r6], #0x1	; load the first character into r4, increment pointer
	ldrb r5, [r6]		; load second character into r5
	cmp r4, r5			; first char entered ( hex value ) - 2nd char entered ( hex value )
	blt r4_first		; if first char is less than, it goes first
						; this also will be okay if value is equal
	mov r0, r5			; store into r0 the 2nd char entered
	bl output_character	; output the 2nd char entered
	mov r0, r4			; store into r0 the 1st char entered
	bl output_character	; output the 1st char entered
	b quit_message		; give user option to quit or continue

r4_first:
	mov r0, r4			; store into r0 the 1st char entered
	bl output_character	; output the 1st char entered
	mov r0, r5			; store into r0 the 2nd char entered
	bl output_character	; output the 2nd char entered

quit_message:
	mov r0, #0x0A		; new line character
	bl output_character	; print a new line
	mov r0, #0x0D		; carriage return
	bl output_character	; print a carriage return
	ldr r0, ptr_to_quit_msg	; load into r0 the pointer to quit message
	bl output_string
	; we do this here because if the user selects to continue the program
	; it gives the program a new line to start with
	mov r0, #0x0A		; new line character
	bl output_character	; print a new line
	mov r0, #0x0D		; carriage return
	bl output_character	; print a carriage return
	bl read_character	; collect user input
	cmp r0, #0x71		; compare with ascii 'q'
	beq stop			; stop program if 'q' was entered
	cmp r0, #0x51		; compare with ascii 'Q'
	beq stop			; stop program if 'Q' was entered
	b project2			; if 'q' or 'Q' wasn't entered, restart program

stop:
	POP {lr}	  ; Restore lr from stack
	mov pc, lr


output_string:
	PUSH {lr, r4}   ; Store register lr on stack

	mov r4, r0		; move contents of r0 into r4
					; so we can store current char in r0
					; and pass that to output_character
continue_output:
	ldrb r0, [r4], #1	; load the first character into register 0
	cmp r0, #0x0	; check to see if this character is null
	beq done		; if so, we are done
	bl output_character	; else, output the character
	b continue_output

done:
	POP {lr, r4}
	mov pc, lr


read_character:
	PUSH {lr, r2}   ; Store registers lr and r2 onto stack

RxFE_check:
	ldrb r0, [r1, #U0FR]	; load first byte of UART0 Flag register into r0
	mov r2, #0x10		; and the byte loaded with 0001 0000
	and r2, r2, r0		; and r2 and UART0FR, store result into r2
	cmp r2, #0x10		; if RxFE flag = 0, then receive data
	beq RxFE_check		; else, continue to check
	ldrb r0, [r1]		; load byte from UART0DR into register 0 ( receive )

	POP {lr, r2}
	mov pc, lr


output_character:
	PUSH {lr, r2, r3}   ; Store registers lr, r2, and r3 onto stack

TxFF_check:
	ldrb r2, [r1, #U0FR]	; load first byte of UART0 Flag register into r2
	mov r3, #0x20
	and r3, r2, r3		; and the byte loaded with 0010 0000
	cmp r3, #0x20		; if TxFF flag = 0, then transmit data
	beq TxFF_check		; else, continue to check
	strb r0, [r1]		; store byte from register 0 into UART0DR

	POP {lr, r2, r3}
	mov pc, lr


	.end
