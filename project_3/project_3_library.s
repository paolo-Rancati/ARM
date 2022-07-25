	.text
	.global read_character
	.global output_character
	.global output_string
	.global gpio_init
	.global read_from_push_btn
	.global illuminate_RGB_LED

U0FR:   .equ 0x18       ; UART0 Flag Register offset
DATA:	.equ 0x3FC		; GPIO Data Register offset

read_character:
        PUSH {lr}   			; store link register onto stack

        mov r1, #0xC000
        movt r1, #0x4000        ; register 1 stores UART0 base address

RxFE_check:
        ldrb r0, [r1, #U0FR]    ; load first byte of UART0 Flag register into r0
        mov r2, #0x10           ; and the byte loaded with 0001 0000
        and r2, r2, r0          ; and r2 and UART0FR, store result into r2
        cmp r2, #0x10           ; if RxFE flag = 0, then receive data
        beq RxFE_check          ; else, continue to check
        ldrb r0, [r1]           ; load byte from UART0DR into register 0 ( receive )

		POP {pc}

output_character:
        PUSH {lr}   			; store link register onto stack

        mov r1, #0xC000
        movt r1, #0x4000        ; register 1 stores UART0 base address

TxFF_check:
        ldrb r2, [r1, #U0FR]    ; load first byte of UART0 Flag register into r2
        mov r3, #0x20
        and r3, r2, r3          ; and the byte loaded with 0010 0000
        cmp r3, #0x20           ; if TxFF flag = 0, then transmit data
        beq TxFF_check          ; else, continue to check
        strb r0, [r1]           ; store byte from register 0 into UART0DR

		POP {pc}

output_string:
        PUSH {lr, r4}   		; store registers lr and r4 onto stack

        mov r4, r0              ; move contents of r0 into r4
                                ; so we can store current char in r0
                                ; and pass that to output_character
continue_output:
        ldrb r0, [r4], #1       ; load the first character into register 0
        cmp r0, #0x0    		; check to see if this character is null
        beq done                ; if so, we are done
        bl output_character     ; else, output the character
        b continue_output

done:
        POP {r4, pc}

read_from_push_btn:
	PUSH {lr}   			; store register lr on stack

	mov r1, #0x5000
	movt r1, #0x4002		; r1 stores the GPIO PORT F base address
	ldrb r0, [r1, #DATA]    ; load r0 with GPIODR bits 0-7
	and r0, r0, #0x10
	cmp r0, #0x0			; compare the value with 0
	bne button_not_pressed	; if value is not 0, it was not pressed
	mov r0, #0x1			; else it was pressed, return 1
	b return
button_not_pressed:
	mov r0, #0x0			; not pressed, return 0
	b return

return:
	POP {pc}


illuminate_RGB_LED:
	PUSH {lr}   			; Store register lr on stack

	mov r1, #0x5000			; load the UART0 base address
	movt r1, #0x4002		; into r1
	strb r0, [r1, #DATA]	; store the data in r0 to UART0 DATA Reg bits 0-7

	POP {pc}


gpio_init:

	; Enable Clock for Port F
	mov r0, #0xE000
	movt r0, #0x400F
	ldrb r1, [r0, #0x608]
	orr r1, r1, #0x20
	strb r1, [r0, #0x0608]

	; Set Direction
	mov r0, #0x5000
	movt r0, #0x4002
	ldrb r1, [r0, #0x400]
	orr r1, r1, #0xE
	bic r1,r1, #0x10
	strb r1, [r0, #0x400]

	; Enable Digital
	mov r0, #0x5000
	movt r0, #0x4002
	ldrb r1, [r0, #0x51C]
	orr r1, r1, #0x1E
	strb r1, [r0, #0x051C]

	; Enable Pull-Up Resistor
	mov r0, #0x5000
	movt r0, #0x4002
	ldrb r1, [r0, #0x510]
	orr r1, r1, #0x10
	strb r1, [r0, #0x0510]

	; Return
	mov pc,lr


	.end
