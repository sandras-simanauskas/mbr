; VBR.s - Volume Boot Record.

org	0x7C00
bits	16

; Head.

	mov dh, [si+1]

; Sector.

	mov ax, [si+2]
	add ax, 1
	mov cl, al
	and cl, 0x3F

; Cylinder.

	shl ax, 1
	shl ax, 1
	mov ch, ah

; Load VBR.

	mov ah, 2			; Select BIOS disk read function.
	mov al, 2			; Number of sectors to read.
	mov bx, 0x7E00			; Destination.
	int 0x13			; Read.

	jc error			; Read successful?

	jmp 0x7E00			; Jump to kernel.

error:	mov si, message

; Fallthrough.

print:	sti
	mov ah, 0xE			; Select BIOS print function.
	mov bh, 0			; Page number.
	mov bl, 0x7			; Color.
.loop:	lodsb				; Load byte to print.
	or al, al			; If zero.
	jz hang				; Terminate.
	int 0x10			; Else print.
	jmp .loop			; Next byte.

hang:	hlt

message: db "Can not read Kernel from disk!", 0

times	510-($-$$) db 0

dw 0xAA55				; VBR boot signature.
