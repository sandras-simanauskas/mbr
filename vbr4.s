ORG	0x7C00
BITS	16

	mov	si,	message

print:	mov	ah,	0x0E			; Select bios function,
	mov	bh,	0			; page number,
	mov	bl,	0			; and foreground color.
.loop:	lodsb					; Load byte to print,
	or	al,	al			; if the byte is 0
	jz	.hang				; return,
	int	0x10				; else print the character
	jmp	.loop				; and loop.
.hang:	hlt
	jmp	.hang

message:		db	"VBR4", 0

times	510-($-$$)	db	0
			dw	0xAA55		; Boot signature.
