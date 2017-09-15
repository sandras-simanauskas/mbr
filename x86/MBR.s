org	0x7A00
bits	16
cpu	8086

%macro	check 1
	cmp byte [0x7A00+%1], 0x80
	jne $+7
	inc cl			; Count of active partitions in cl.
	mov si, 0x7A00+%1	; Last (only) active partition in si.
%endmacro

	cli

; Set segments and stack.

	xor cx, cx
	mov ds, cx
	mov es, cx
	mov ss, cx
	mov sp, 0x7A00

; Relocate self to 0x7A00.

	mov ch, 1
	mov si, 0x7C00
	mov di, sp
	cld
rep	movsw

	jmp 0:$+5		; Canonicalize cs:ip by far-jumping.

; Check for active partition flag.

	check 0x1BE
	check 0x1CE
	check 0x1DE
	check 0x1EE

	cmp cl, 1		; How many active partitions were there:
	jl error0		; * too few?
	jg error1		; * too many?

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

	jc error2		; Load successful?

; Check boot signature.

	cmp word [0x7DFE], 0xAA55
	jne error3

	jmp 0x7C00		; Jump to VBR.

error0:	mov si, message0
	jmp print

error1:	mov si, message1
	jmp print

error2:	mov si, message2
	jmp print

error3:	mov si, message3

; Fallthrough.

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

times	0xDA-($-$$) dd 0
	dw 0			; Always zero.
	dd 0			; Disk timestamp.

message2: db "Can not read Volume Boot Record from disk!", 0
message3: db "Volume Boot Record has wrong boot signature!", 0

times	0x1B4-($-$$) db 0
times	0xA db 0		; Optional unique disk ID.
times	0x40 db 0		; Partition table.

	dw 0xAA55		; Boot signature.
