	.text
	.global read_character
	.global output_character
	.global output_string

	; Add read_character, output_character, output_string from your prevous projects
   	; Be sure to modify read_character so that it just reads from the UART0 DAta Register
    	; and does not poll since we are now using interrupts

U0FR:   .equ 0x18       ; UART0 Flag Register offset
DATA:	.equ 0x3FC		; GPIO Data Register offset




read_character:
        PUSH {lr}   			; store link register onto stack

        mov r1, #0xC000
        movt r1, #0x4000        ; register 1 stores UART0 base address

        ldrb r0, [r1]    ; load first byte of UART0 Flag register into r0

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
        PUSH {r4, lr}   		; store registers lr and r4 onto stack

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

	.end
