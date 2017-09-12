org	0x7C00
bits	16

	cli
	cld
	xor	ax,	ax
	mov	ds,	cx
	mov	es,	cx
	mov	ss,	cx
	jmp	$

times	510-($-$$)	db	0
			dw	0xAA55
