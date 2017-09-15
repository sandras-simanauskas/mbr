; MBR.s - Master Boot Record.

%macro	check 1
	cmp byte [0x7A00+%1], 0x80
	jne $+7

	inc cl
	mov si, 0x7A00+%1
%endmacro

%macro	partition 10					; 16 byte structure.
	db %1						; Boot indicator bit flag (0x80 = active).
	db %2						; Head.
	db (%3 & 00111111b) | ((%4 >> 2) & 11000000b)	; Bits 0-5: sector, bits 6-7: upper two bits of cylinder.
	db %4						; Lower 8 bits of cylinder.
	db %5						; System ID.
	db %6						; Ending Head
	db (%7 & 00111111b) | ((%8 >> 2) & 11000000b)	; Bits 0-5: ending sector, bits 6-7: upper two bits of ending cylinder.
	db %8						; Lower 8 bits of cylinder.
	dd %9						; Relative Sector (to start of partition -- also equals the partition's starting LBA value)
	dd %10						; Total sectors in partition.
%endmacro

org	0x7A00
bits	16
cpu	8086

	cli						; Disable interrupts. Re-enable them once the IDT is set up.

; Set segments and stack.

	xor cx, cx					; We will need CL cleared later.
	mov ds, cx
	mov es, cx
	mov ss, cx
	mov sp, 0x7A00

; Relocate self to 0x7A00.

	mov ch, 1					; CL is cleared. Move 0x0100 words.
	mov si, 0x7C00					; Source.
	mov di, sp					; Destination. Bottom of relocation point is top of stack.
	cld						; Ensure the Direction Flag points up for (future) string operations.
rep	movsw						; Move words.
	jmp 0:$+5					; Canonicalize CS:IP by far-jumping to relocated code.

; We will count active partitions in CX as we scan the partition table. CX = 0 from the last MOVSW.
; Unrolled loop for simplicity.

	check 0x01BE
	check 0x01CE
	check 0x01DE
	check 0x01EE

	cmp cx, 1					; How many active partitions were there -
	jl error0					; - too few?
	jg error1					; - too many?

; Head.

	mov dh, [si+1]

; Sector.

	mov ax, [si+2]
	mov cl, al
	and cl, 00111111b

; Cylinder.

	shl ax, 1
	shl ax, 1
	mov ch, ah

	mov ah, 0x02
	mov al, 0x01
	mov bx, 0x7C00					; Destination.
	int 0x13					; Load sector.

	jc error2					; Success?

	cmp word [0x7DFE], 0xAA55			; Check boot signature.
	jne error3

	jmp 0x7C00

; At this point we should be at the start of VBR with DL set to the boot drive number and DS:SI pointing to the active partition entry.

error0:	mov si, message0
	jmp print

error1:	mov si, message1
	jmp print

error2:	mov si, message2
	jmp print

error3:	mov si, message3

; Fallthrough to print from which we do not return to simplify its implementation.

print:	mov ah, 0x0E					; Select bios function.
	mov bh, 0					; Page number.
	mov bl, 0					; Foreground color.
.loop:	lodsb						; Load byte to print.
	or al, al					; If the byte is 0
	jz hang						; hang
	int 0x10					; else print the character
	jmp .loop					; and loop.

hang:	hlt

message0: db "MBR: Error: No active partition.",  0
message1: db "MBR: Error: More than one active partition.", 0
message2: db "MBR: Error: Can not read Volume Boot Record from disk.", 0
message3: db "MBR: Error: Volume Boot Record has wrong boot signature.", 0

times	0x01B4-($-$$) db 0				; Fill with zeros up to the start of the data structures.

times	10 db 0						; Optional unique disk ID.

;		active flag,	starting head,	starting sector,	starting cylinder,	system ID,	ending head,	ending sector,	ending cylinder,	relative sector,	sectors in partition
partition	0x80,		0,		2,			0,			0,		0,		0,		0,			0,			1
partition	0,		0, 		0,			0,			0,		0,		0,		0,			0,			0
partition	0,		0, 		0,			0,			0,		0,		0,		0,			0,			0
partition	0,		0,		0,			0,			0,		0,		0,		0,			0,			0

dw 0xAA55						; MBR boot signature.
