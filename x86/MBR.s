org	0x7A00
bits	16
cpu	8086

%define active 0x80
%define inactive 0

%macro	check 1
	cmp byte [0x7A00+%1], 0x80				; Active flag set?
	jne $+7							; If not jump over this macro.
	inc cl							; Count of active partitions in cl.
	mov si, 0x7A00+%1					; Last (only) active partition in si.
%endmacro

%macro	partition	10							; 16 byte structure.
	db	%1						; Boot indicator bit flag (0x80 = active).
	db	%2						; Head.
	db	(%3 & 00111111b) | ((%4 >> 2) & 11000000b)	; Bits 0-5: sector, bits 6-7: upper two bits of cylinder.
	db	%4						; Lower 8 bits of cylinder.
	db	%5						; System ID.
	db	%6						; Ending Head
	db	(%7 & 00111111b) | ((%8 >> 2) & 11000000b)	; Bits 0-5: ending sector, bits 6-7: upper two bits of ending cylinder.
	db	%8						; Lower 8 bits of cylinder.
	dd	%9						; Relative Sector (to start of partition -- also equals the partition's starting LBA value)
	dd	%10						; Total sectors in partition.
%endmacro

	cli							; Clear interrupts.

; Set segments and stack.

	xor cx, cx						; We will need cl cleared when relocating.
	mov ds, cx						; Data segment.
	mov es, cx						; Extra segment.
	mov ss, cx						; Stack segment.
	mov sp, 0x7A00						; Stack pointer.

; Relocate self to 0x7A00.

	mov ch, 1						; Together with the cleared cl that makes 0x100.
	mov si, 0x7C00						; Source.
	mov di, sp						; Destination. Stack from the start of our code down.
	cld							; Clear direction flag for (future) string operations.
rep	movsw							; Move words.

	jmp 0:$+5						; Canonicalize cs:ip by far-jumping.

; Check for active partition flag.

	check 0x1BE						; Check partition 1 active flag.
	check 0x1CE						; Check partition 2 active flag.
	check 0x1DE						; Check partition 3 active flag.
	check 0x1EE						; Check partition 4 active flag.

	cmp cl, 1						; How many active partitions were there:
	jl error0						; * too few?
	jg error1						; * too many?

; Head.

	mov dh, [si+1]

; Sector.

	mov ax, [si+2]
	mov cl, al
	and cl, 0x3F

; Cylinder.

	shl ax, 1
	shl ax, 1
	mov ch, ah

; Load VBR.

	mov ah, 2						; Select BIOS disk read function.
	mov al, 1						; Number of sectors to read.
	mov bx, 0x7C00						; Destination.
	int 0x13						; Read.

	jc error2						; Read successful?

; Check boot signature.

	cmp word [0x7DFE], 0xAA55
	jne error3

	jmp 0x7C00						; Jump to VBR.

error0:	mov si, message0
	jmp print

error1:	mov si, message1
	jmp print

error2:	mov si, message2
	jmp print

error3:	mov si, message3

; Fallthrough.

print:	mov ah, 0xE						; Select BIOS print function.
	mov bh, 0						; Page number.
	mov bl, 0x7						; Color.
.loop:	lodsb							; Load byte to print.
	or al, al						; If zero.
	jz hang							; Terminate.
	int 0x10						; Else print.
	jmp .loop						; Next byte.

hang:	hlt

message0: db "No active partition!",  0
message1: db "More than one active partition!", 0

times	0xDA-($-$$) dd 0
	dw 0							; Always zero.
	dd 0							; Disk timestamp.

message2: db "Can not read Volume Boot Record from disk!", 0
message3: db "Volume Boot Record has wrong boot signature!", 0

times	0x1B4-($-$$) db 0
times	0xA db 0						; Optional unique disk ID.

	;		active flag,	starting head,	starting sector,	starting cylinder,	system ID,	ending head,	ending sector,	ending cylinder,	relative sector,	sectors in partition
	partition	active,		0, 		2,			0,			0x7F,		0,		11,		0,			2,			9
	partition	inactive,	0,		0,			0,			0,		0,		0,		0,			0,			0
	partition	inactive,	0,		0,			0,			0,		0,		0,		0,			0,			0
	partition	inactive,	0,		0,			0,			0,		0,		0,		0,			0,			0

	dw 0xAA55			; Boot signature.
