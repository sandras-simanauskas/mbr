ORG	0x7C00
BITS	32

	jmp	$

times	510-($-$$)	db	0
			dw	0xAA55		; Boot signature.
