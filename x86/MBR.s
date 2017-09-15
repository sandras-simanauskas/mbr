org	0x7A00
bits	16
cpu	8086

%macro	check 1
	cmp byte [0x7A00+%1], 0x80
	jne $+7
	inc cl
	mov si, 0x7A00+%1
%endmacro

	cli

; Set segments and stack.

	xor cx, cx
	mov ds, cx
	mov es, cx
	mov ss, cx
	mov sp, 0x7A00

; Relocate self to 0x7A00.
; Canonicalize cs:ip by far-jumping.

	mov ch, 1
	mov si, 0x7C00
	mov di, sp
	cld
rep	movsw
	jmp 0:$+5

; Check for active partition flag.
; Count of active partitions in cl.
; Last (only) active partition in si.

	check 0x1BE
	check 0x1CE
	check 0x1DE
	check 0x1EE

; How many active partitions were there:
; * too few?
; * too many?

	cmp cx, 1
	jl error0
	jg error1

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

	mov ah, 2
	mov al, 1
	mov bx, 0x7C00
	int 0x13

	jc error2

; Check VBR boot signature.
; Jump if valid.

	cmp word [0x7DFE], 0xAA55
	jne error3

	jmp 0x7C00

error0:	mov si, message0
	jmp print

error1:	mov si, message1
	jmp print

error2:	mov si, message2
	jmp print

error3:	mov si, message3

; Fallthrough to print from which we do not return to simplify its implementation.

print:	mov ah, 0xE
	mov bh, 0
	mov bl, 0
.loop:	lodsb
	or al, al
	jz hang
	int 0x10
	jmp .loop

hang:	hlt

message0: db "No active partition!",  0
message1: db "More than one active partition!", 0

; Pad up to disk timestamp.

times	0xDA-($-$$) dd 0

; Disk timestamp.

	dw 0
	dd 0

message2: db "Can not read Volume Boot Record from disk!", 0
message3: db "Volume Boot Record has wrong boot signature!", 0

; Fill with zeros up to the start of the data structures.

times	0x1B4-($-$$) db 0

; Optional unique disk ID.

times	0xA db 0

; Partition table.

times	0x40 db 0

; Boot signature.

	dw 0xAA55
