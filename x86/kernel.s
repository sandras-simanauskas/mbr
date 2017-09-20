%include	"macro.h"

%macro ISR_NOERRCODE 1
isr%1:	iretq
%endmacro

%macro ISR_ERRCODE 1
isr%1:	pop rax
	iretq
%endmacro

%macro IRQ 1
isr%1:	iretq
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
bits	16

; Disable VGA hardware cursor.

	mov dx, 0x03D4
	mov al, 0x0A
	out dx, al
	inc dx
	mov al, 0x3F
	out dx, al

; For now we use the classical method of enabling the A20 gate.

	call wait_8042_empty		; Wait for the 8042 input register to become empty.
	mov al, 0xAD			; Command to disable keyboard interfaces.
	out 0x64, al			; Send the command.

	call wait_8042_empty		; Wait for the 8042 input register to become empty.
	mov al, 0xD0			; Command to read from input.
	out 0x64, al			; Send the command

wait_8042_full:				; We wait until the data is ready for us to read. Can also work as "press any key to continue".
	in al, 0x64			; Read 8042 status register.						
	test al, 1			; Bit 0 clear means output register (0x60) does not have data for system.
	jz wait_8042_full		; We wait until it does.

	in al, 0x60			; Get data.
	push ax				; Save data.

	call wait_8042_empty		; We wait until we can send the next command.
	mov al, 0xD1			; Command to write to output port.
	out 0x64, al			; Send the command. Next byte written to port 0x60 is placed in the 8042 output port.

	call wait_8042_empty		; We wait until we can send the next command.
	pop ax				; Restore data.
	or al, 2			; Set A20 enable bit.
	out 0x60, al			; Send data.

	call wait_8042_empty		; We wait until we can send the next command.
	mov al, 0xAE			; Command to enable keyboard interfaces.
	out 0x64, al			; Send the command.

	call wait_8042_empty		; We wait until 8042 has read our command and continue.

; Build Paging Structures.

	xor eax, eax			; Clear the Paging Structure buffer.
	mov edi, 0x00001000		; Buffer address.
	mov ecx, 0x00001000		; 0x00001000 dwords.
rep	stosd				; Store.

	mov dword [0x1000], 0x00002003	; Store the address of the Page Directory Pointer Table with present and writable flags set as the first Page Map Level 4 entry.

	mov dword [0x2000], 0x00003003	; Store the address of the Page Directory with present and writable flags set as the first Page Directory Pointer Table entry.

	mov dword [0x3000], 0x00004003	; Store to address of the Page Table with present and writable flags set as the first Page Directory entry.

; Build the Page Table.

	mov di, 0x4000			; Point di to the Page Table.
	mov eax, 0x00000003		; Point eax to 0 with present and writable flags set.

build_page_table:
	mov [es:di], eax
	add eax, 0x00001000
	add di, 8
	cmp eax, 0x00200000		; If we did all 2MiB, end.
	jb build_page_table

; Enter long mode.

	mov eax, cr4
	or eax, 10100000b		; Set the PAE and PGE bit.	
	mov cr4, eax

	mov edi, 0x00001000
	mov cr3, edi			; Point CR3 at the PML4.

	mov ecx, 0xC0000080		; Read from the EFER MSR.
	rdmsr

	or eax, 0x00000100		; Set the LME bit.
	wrmsr

	mov eax, cr0
	or eax, 0x80000001		; Activate long mode by enabling paging and protection simultaneously.
	mov cr0, eax

	lgdt [gdt]			; Load GDT.

	jmp 8:long_mode			; Load cs with 64 bit segment and flush the instruction cache by long jumping.

wait_8042_empty:			; We wait until the 8042 input register is empty.
	in al, 0x64			; Read 8042 status register.
	test al, 2			; Bit 1 set means input register (0x60/0x64) has data for 8042.
	jnz wait_8042_empty		; We wait until it doesn't.
	ret

bits	64

long_mode:
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

hang:	hlt
	jmp hang

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
CALL	CLEAR_LINE
	RET

LOCAL	NEW_PAGE
LIT	0
LIT	Y
	STORE
CALL	CLEAR_LINE
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
	PUSH
	OVER
	OVER
	STORE
LIT	8
	ADD
	PULL
LIT	1
	SUB
JNZ	BLANK
	RET

X:	dq 0				; Not more than 80.
Y:	dq 0				; Not more than 25.

LOCAL	BYTE_FETCH
	FETCH
LIT	0xFF
	AND
	RET

io_wait:
	out 0x80, al
	ret

align	8

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
	ISR_NOERRCODE 0x11
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
	ISR_NOERRCODE 0x1E
	ISR_NOERRCODE 0x1F
	IRQ 0x20
	IRQ 0x21
	IRQ 0x22
	IRQ 0x23
	IRQ 0x24
	IRQ 0x25
	IRQ 0x26
	IRQ 0x27
	IRQ 0x28
	IRQ 0x29
	IRQ 0x2A
	IRQ 0x2B
	IRQ 0x2C
	IRQ 0x2D
	IRQ 0x2E
	IRQ 0x2F
	
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

idtd:	dw (16*48)-1
	dq idt

gdt:	dw 23
	dd gdt
	dw 0

	dq 0x00209A0000000000
	dq 0x0000920000000000

stack:	times 8 dq 0

times	4096-($-$$) db 0
