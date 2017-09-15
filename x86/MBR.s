; MBR.S - Master Boot Record in Assembly.

%MACRO	check 1
	cmp byte [7A00h+%1], 80h
	jne $+7

	inc cl
	mov si, 7A00h+%1
%endmacro

org	7A00h
bits	16
cpu	8086

	cli						; Clear interrupts. Re-enable them once the IDT is set up.

; Set segments and stack.

	xor cx, cx					; We will need cl cleared later.
	mov ds, cx
	mov es, cx
	mov ss, cx
	mov sp, 7A00h

; Relocate self to 7A00h.

	mov ch, 1					; Move 0x0100 words, cl is cleared.
	mov si, 7C00h					; Source.
	mov di, sp					; Destination. Bottom of relocation point is top of stack.
	cld						; Ensure the Direction Flag points up for (future) string operations.
rep	movsw						; Move words.
	jmp 0:$+5					; Canonicalize cs:ip by far-jumping to relocated code.

; We will count active partitions in cx as we scan the partition table. cx = 0 from the last MOVSW.
; Unrolled loop for simplicity.

	check 01BEh
	check 01CEh
	check 01DEh
	check 01EEh

	cmp cx, 1					; How many active partitions were there -
	jl error0					; - too few?
	jg error1					; - too many?

; Head.

	mov dh, [si+1]

; Sector.

	mov ax, [si+2]
	mov cl, al
	and cl, 3Fh

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

message0: db "No active partition!",  0
message1: db "More than one active partition!", 0

times	220-($-$$) dd 0					; Disk timestamp.

message2: db "Can not read Volume Boot Record from disk!", 0
message3: db "Volume Boot Record has wrong boot signature!", 0

times	0x01B4-($-$$) db 0				; Fill with zeros up to the start of the data structures.

times	10 db 0						; Optional unique disk ID.

times	8 dq 0						; Partition table.

dw 0xAA55						; MBR boot signature.
