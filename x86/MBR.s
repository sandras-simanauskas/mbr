; MBR.S - master boot record.

org	0x7A00				; We are actually loaded at 0x7C00 but we will relocate to 0x7A00 before any position dependent code.
bits	16
cpu	8086				; We want to be compatible with the oldest of PCs.

%macro	check 1
	cmp byte [0x7A00+%1], 0x80	; Check for active partition flag.
	jne $+7				; If active.
	inc cl				; Count of active partitions.
	mov si, 0x7A00+%1		; Memorize this partition in case it's the only one marked active.
%endmacro

	cli				; Clear interrupts. Re-enable them once the IDT is set up.

; Set segments and stack.

	xor cx, cx			; We will need cl cleared later.
	mov ds, cx
	mov es, cx
	mov ss, cx
	mov sp, 0x7A00

; Relocate self to 0x7A00.

	mov ch, 1			; Move 0x100 words, cl is cleared.
	mov si, 0x7C00			; Source.
	mov di, sp			; Destination. Bottom of relocation point is top of stack.
	cld				; Ensure the Direction Flag points up for (future) string operations.
rep	movsw				; Move words.
	jmp 0:$+5			; Canonicalize cs:ip by far-jumping to relocated code.

; We will count active partitions in cx as we scan the partition table. cx is clear from the last movsw. Unrolled loop for simplicity.

	check 0x1BE
	check 0x1CE
	check 0x1DE
	check 0x1EE

	cmp cx, 1			; How many active partitions were there:
	jl error0			; * too few?
	jg error1			; * too many?

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

	mov ah, 2
	mov al, 1
	mov bx, 0x7C00			; Destination.
	int 0x13			; Load sector.

	jc error2			; Success?

	cmp word [0x7DFE], 0xAA55	; Check VBR boot signature.
	jne error3

	jmp 0x7C00

; At this point we should be at the start of Volume Boot Record with dl set to the Boot Drive number and ds:si pointing to the Active Partition entry.

error0:	mov si, message0
	jmp print

error1:	mov si, message1
	jmp print

error2:	mov si, message2
	jmp print

error3:	mov si, message3

; Fallthrough to print from which we do not return to simplify its implementation.

print:	mov ah, 0xE			; Select bios function.
	mov bh, 0			; Page number.
	mov bl, 0			; Foreground color.
.loop:	lodsb				; Load byte to print.
	or al, al			; If the byte is 0
	jz hang				; hang
	int 0x10			; else print the character
	jmp .loop			; and loop.

hang:	hlt

message0: db "No active partition!",  0
message1: db "More than one active partition!", 0

times	0xDA-($-$$) dd 0		; Pad up to Disk Timestamp.
	dw 0				; Has to be zero as part of the Disk Timestamp.
	dd 0				; Disk timestamp.

message2: db "Can not read Volume Boot Record from disk!", 0
message3: db "Volume Boot Record has wrong boot signature!", 0

times	0x1B4-($-$$) db 0		; Fill with zeros up to the start of the data structures.
times	0xA db 0			; Optional unique disk ID.
times	0x40 db 0			; Partition table.

	dw 0xAA55			; MBR boot signature.
