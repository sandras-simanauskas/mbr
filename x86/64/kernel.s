%include	"x86/64/primitives.h"

%macro ISR_NOERRCODE 1
isr%1:
LIT	MESSAGE_INTERRUPT
CALL	STRING_PRINT
	iretq
%endmacro

%macro ISR_ERRCODE 1
isr%1:	pop rax
LIT	MESSAGE_INTERRUPT
CALL	STRING_PRINT
	iretq
%endmacro

%macro	IDT_ENTRY 1
	dw (((isr%1-$$)+0x8000)&0xFFFF)
	dw 0x08   
	db 0
	db 10001110b
	dw (((isr%1-$$)+0x8000)>>16)
	dd (((isr%1-$$)+0x8000)>>32)
	dd 0
%endmacro

org	0x8000
bits	64

	mov ax, 0x0010
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov rbp, stack

; Remap IRQs.

	in al, 0x21
	push ax

	in al, 0xA1
	push ax

	mov al, 0x11
	out 0x20, al
 
	out 0x80, al			; IO wait.

	mov al, 0x11
	out 0x20, al

	out 0x80, al			; IO wait.

	mov al, 0x11
	out 0xA0, al

	out 0x80, al			; IO wait.

	mov al, 0x20
	out 0x21, al

	out 0x80, al			; IO wait.

	mov al, 0x28
	out 0xA1, al

	out 0x80, al			; IO wait.

	mov al, 4
	out 0x21, al

	out 0x80, al			; IO wait.

	mov al, 2
	out 0xA1, al

	out 0x80, al			; IO wait.

	mov al, 0x01
	out 0x21, al

	out 0x80, al			; IO wait.

	mov al, 0x01
	out 0xA1, al

	out 0x80, al			; IO wait.
 
	pop ax
	out 0xA1, al

	pop ax
	out 0x21, al

	lidt [idtd]			; Load IDT.
	sti				; Set interrupts.

; Blank the screen.

CALL	BLANK

LIT	MESSAGE
CALL	STRING_PRINT

hang:	hlt
	jmp	hang

LOCAL	BYTE_STORE
	DUP
	PUSH
	FETCH
LIT	0xFFFFFFFFFFFFFF00
	AND	
	OR
	PULL
	STORE
	RET

LOCAL	CHARACTER
LIT	0x00000000000B8000
LIT	X
	FETCH
LIT	Y
	FETCH
LIT	160
	MUL
	ADD
	ADD
CALL	BYTE_STORE
LIT	X
	FETCH
LIT	158
	SUB
	DROP
JNS	NEW_LINE
LIT	X
	FETCH
LIT	2
	ADD
LIT	X
	STORE
	RET

LOCAL	NEW_LINE
LIT	0
LIT	X
	STORE
LIT	Y
	FETCH
LIT	24
	SUB
	DROP
JNS	NEW_PAGE
LIT	Y
	FETCH
LIT	1
	ADD
LIT	Y
	STORE
CALL	NEW_LINE
	RET

LOCAL	NEW_PAGE
LIT	0
LIT	Y
	STORE
CALL	CLEAR_LINE
	RET

LOCAL	STRING_PRINT
	DUP
	PUSH
LIT	8
	ADD
	PULL
	FETCH
LOCAL	.LOOP
	PUSH
	DUP
CALL	BYTE_FETCH
CALL	CHARACTER
LIT	1
	ADD
	PULL
LIT	1
	SUB
JNZ	.LOOP
	RET

LOCAL	CLEAR_LINE
LIT	0x7020702070207020
LIT	Y
	FETCH
LIT	160
	MUL
LIT	0x00000000000B8000
	ADD
LIT	20
LOCAL	.LOOP
	PUSH
	OVER
	OVER
	STORE
LIT	8
	ADD
	PULL
LIT	1
	SUB
JNZ	.LOOP
	RET

LOCAL	BLANK
LIT	0x7020702070207020
LIT	0x00000000000B8000
LIT	500
LOCAL	.LOOP
	PUSH
	OVER
	OVER
	STORE
LIT	8
	ADD
	PULL
LIT	1
	SUB
JNZ	.LOOP
	RET

LOCAL	BYTE_FETCH
	FETCH
LIT	0xFF
	AND
	RET

X:	dq 0				; Not more than 80.
Y:	dq 0				; Not more than 25.

	ISR_NOERRCODE 0x00
	ISR_NOERRCODE 0x01
	ISR_NOERRCODE 0x02
	ISR_NOERRCODE 0x03
	ISR_NOERRCODE 0x04
	ISR_NOERRCODE 0x05
	ISR_NOERRCODE 0x06
	ISR_NOERRCODE 0x07
	ISR_ERRCODE   0x08
	ISR_NOERRCODE 0x09
	ISR_ERRCODE   0x0A
	ISR_ERRCODE   0x0B
	ISR_ERRCODE   0x0C
	ISR_ERRCODE   0x0D
	ISR_ERRCODE   0x0E
	ISR_NOERRCODE 0x0F
	ISR_NOERRCODE 0x10
	ISR_ERRCODE   0x11
	ISR_NOERRCODE 0x12
	ISR_NOERRCODE 0x13
	ISR_NOERRCODE 0x14
	ISR_NOERRCODE 0x15
	ISR_NOERRCODE 0x16
	ISR_NOERRCODE 0x17
	ISR_NOERRCODE 0x18
	ISR_NOERRCODE 0x19
	ISR_NOERRCODE 0x1A
	ISR_NOERRCODE 0x1B
	ISR_NOERRCODE 0x1C
	ISR_NOERRCODE 0x1D
	ISR_ERRCODE   0x1E
	ISR_NOERRCODE 0x1F
	ISR_NOERRCODE 0x20
	ISR_NOERRCODE 0x21
	ISR_NOERRCODE 0x22
	ISR_NOERRCODE 0x23
	ISR_NOERRCODE 0x24
	ISR_NOERRCODE 0x25
	ISR_NOERRCODE 0x26
	ISR_NOERRCODE 0x27
	ISR_NOERRCODE 0x28
	ISR_NOERRCODE 0x29
	ISR_NOERRCODE 0x2A
	ISR_NOERRCODE 0x2B
	ISR_NOERRCODE 0x2C
	ISR_NOERRCODE 0x2D
	ISR_NOERRCODE 0x2E
	ISR_NOERRCODE 0x2F
	
idt:	IDT_ENTRY 0x00
	IDT_ENTRY 0x01
	IDT_ENTRY 0x02
	IDT_ENTRY 0x03
	IDT_ENTRY 0x04
	IDT_ENTRY 0x05
	IDT_ENTRY 0x06
	IDT_ENTRY 0x07
	IDT_ENTRY 0x08
	IDT_ENTRY 0x09
	IDT_ENTRY 0x0A
	IDT_ENTRY 0x0B
	IDT_ENTRY 0x0C
	IDT_ENTRY 0x0D
	IDT_ENTRY 0x0E
	IDT_ENTRY 0x0F
	IDT_ENTRY 0x10
	IDT_ENTRY 0x11
	IDT_ENTRY 0x12
	IDT_ENTRY 0x13
	IDT_ENTRY 0x14
	IDT_ENTRY 0x15
	IDT_ENTRY 0x16
	IDT_ENTRY 0x17
	IDT_ENTRY 0x18
	IDT_ENTRY 0x19
	IDT_ENTRY 0x1A
	IDT_ENTRY 0x1B
	IDT_ENTRY 0x1C
	IDT_ENTRY 0x1D
	IDT_ENTRY 0x1E
	IDT_ENTRY 0x1F
	IDT_ENTRY 0x20
	IDT_ENTRY 0x21
	IDT_ENTRY 0x22
	IDT_ENTRY 0x23
	IDT_ENTRY 0x24
	IDT_ENTRY 0x25
	IDT_ENTRY 0x26
	IDT_ENTRY 0x27
	IDT_ENTRY 0x28
	IDT_ENTRY 0x29
	IDT_ENTRY 0x2A
	IDT_ENTRY 0x2B
	IDT_ENTRY 0x2C
	IDT_ENTRY 0x2D
	IDT_ENTRY 0x2E
	IDT_ENTRY 0x2F

MESSAGE:
	dq	.end-.start
.start:	db	"Hello, World! "
.end:

MESSAGE_INTERRUPT:
	dq	.end-.start
.start:	db	"Interrupt! "
.end:

idtd:	dw (16*48)-1
	dq idt

gdt:	dw 23
	dd gdt
	dw 0

	dq 0x00209A0000000000
	dq 0x0000920000000000

stack:	times 8 dq 0

times	4096	-($-$$) db 0