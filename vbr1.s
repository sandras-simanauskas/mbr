ORG	0x7C00
BITS	16

	mov	eax,	0x80000001
	cpuid
	test	edx,	0x020000000
	jnz	print.hang

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

message:		db	"Long Mode not availabe!", 0

times	510-($-$$)	db	0
			dw	0xAA55		; Boot signature.
