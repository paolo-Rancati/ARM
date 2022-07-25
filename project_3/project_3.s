	.data

	.global prompt

prompt0:	.string "Press q to quit or choose from the following:", 10, 13, 0
prompt1:	.string	 "r - illuminate RGB LED red", 10,13,0
prompt2:	.string  "b – Illuminate the RGB LED blue", 10, 13, 0
prompt3:	.string  "g – Illuminate the RGB LED green",10, 13, 0
prompt4:	.string  "p – Illuminate the RGB LED purple", 10, 13, 0
prompt5:	.string  "y – Illuminate the RGB LED yellow", 10, 13, 0
prompt6:	.string  "w – Illuminate the RGB LED white", 10, 13, 0
prompt7:	.string  "o – Turn the RGB LED off", 10, 13, 0
prompt8:	.string  "s - read from SW1", 10, 13, 0
pressed:	.string  10, 13, "SW1 was pressed", 10, 13, 10, 13, 0
no_press:	.string  10, 13, "SW1 was NOT pressed", 10, 13, 10,13,0
error:		.string  10, 13, "You entered an incorrect command", 10, 13, 10, 13, 0

	.text

	.global project3
	.global gpio_init
	.global read_character
	.global output_character
	.global output_string
	.global read_from_push_btn
	.global illuminate_RGB_LED


ptr_to_prompt0:		.word prompt0
ptr_to_prompt1:		.word prompt1
ptr_to_prompt2:		.word prompt2
ptr_to_prompt3:		.word prompt3
ptr_to_prompt4:		.word prompt4
ptr_to_prompt5:		.word prompt5
ptr_to_prompt6:		.word prompt6
ptr_to_prompt7:		.word prompt7
ptr_to_prompt8:		.word prompt8
ptr_to_pressed:		.word pressed
ptr_to_no_press:	.word no_press
ptr_to_error:		.word error


project3:
	PUSH {lr, r4}   ; Store lr to stack

program:
	; initially load and output each line of user instructions
    ldr r0, ptr_to_prompt0
    bl output_string
    ldr r0, ptr_to_prompt1
    bl output_string
    ldr r0, ptr_to_prompt2
    bl output_string
    ldr r0, ptr_to_prompt3
    bl output_string
    ldr r0, ptr_to_prompt4
    bl output_string
    ldr r0, ptr_to_prompt5
    bl output_string
    ldr r0, ptr_to_prompt6
    bl output_string
    ldr r0, ptr_to_prompt7
    bl output_string
    ldr r0, ptr_to_prompt8
    bl output_string
    ; instructions output
    ; no terminal output is for
    ; when a result does not output anything to the terminal
    ; such as illuminating an RGB
    ; otherwise program will output results of read_from_push_btn
    ; and then output the instructions again for the user
no_terminal_output:
	bl read_character			; collect user input
	mov r4, r0					; copy user input into register 4
	cmp r4, #0x73				; compare with 's'
	bne next					; if not, move on to test for other input values
	bl read_from_push_btn		; read from the push button
	cmp r0, #0x1				; compare push_btn results with 1
	ite eq
	ldreq r0, ptr_to_pressed	; if r0 is 1, button was pressed
	ldrne r0, ptr_to_no_press	; else button not pressed
	bl output_string			; output the results message
	b program					; top of program, display new instructions
next:
	cmp r4, #0x71				; compare input with 'q'
	it eq						; if input is 'q'
	popeq {r4, PC}				; end program, restore r4
	; below the program compares the user input
	; with r, b, g, p, y, w, and o
	; and then illuminates the RGB LED
	; by setting the correct pins to 1
	; and then branch to no_terminal_output
	; because there was no output displayed
	; to the terminal and therefore
	; we do not need to display
	; the instructions again
	cmp r4, #0x72
	ittt eq
	moveq r0, #0x2
	bleq illuminate_RGB_LED
	beq no_terminal_output
	cmp r4, #0x62
	ittt eq
	moveq r0, #0x4
	bleq illuminate_RGB_LED
	beq no_terminal_output
	cmp r4, #0x67
	ittt eq
	moveq r0, #0x8
	bleq illuminate_RGB_LED
	beq no_terminal_output
	cmp r4, #0x70
	ittt eq
	moveq r0, #0x6
	bleq illuminate_RGB_LED
	beq no_terminal_output
	cmp r4, #0x79
	ittt eq
	moveq r0, #0xA
	bleq illuminate_RGB_LED
	beq no_terminal_output
	cmp r4, #0x77
	ittt eq
	moveq r0, #0xE
	bleq illuminate_RGB_LED
	beq no_terminal_output
	cmp r4, #0x6F
	ittt eq
	moveq r0, #0x0
	bleq illuminate_RGB_LED
	beq no_terminal_output
	; if the user input did not match
	; r, g, b, p, y, w, or o
	; then the user input is invalid
	; alert the user the input was invalid
	; and then display the instructions
	ldr r0, ptr_to_error
	bl output_string
    b program

	.end
