ORG	0x7C00
BITS	16

	; Disable NMI.
	mov	dx,	0x0070
	in	ax,	dx
	or	ax,	0x0080
	out	dx,	ax	
 
	; Check A20.
	xor	ax,	ax
	mov	es,	ax

	not	ax
	mov	ds,	ax

	mov	di,	0x0500
	mov	si,	0x0510

	mov	al,	byte [es:di]
	push	ax

	mov	al,	byte [ds:si]
	push	ax

	mov	byte [es:di],	0x00
	mov	byte [ds:si],	0xFF

	cmp	byte [es:di],	0xFF

	pop	ax
	mov	byte [ds:si],	al

	pop	ax
	mov	byte [es:di],	al

	jne	a20continue

	; Enable A20.
	call	a20wait
	mov	al,	0xAD
	out	0x64,	al

	call	a20wait
	mov	al,	0xD0
	out	0x64,	al

	call	a20wait2
	in	al,	0x60
	push	eax

	call	a20wait
	mov	al,	0xD1
	out	0x64,	al

	call	a20wait
	pop	eax
	or	al,	2
	out	0x60,	al

	call	a20wait
	mov	al,	0xAE
	out	0x64,	al

	call	a20wait

a20continue:

	; cpuid
	mov	eax,	0x80000001
	cpuid
	test	edx,	0x20000000
	jnz	hang

	mov	si,	message

print:	xor	ax,	ax
	mov	ds,	ax
	mov	ah,	0x0E			; Select bios function,
	mov	bh,	0			; page number,
	mov	bl,	0			; and foreground color.
.loop:	lodsb					; Load byte to print,
	or	al,	al			; if the byte is 0
	jz	hang				; return,
	int	0x10				; else print the character
	jmp	.loop				; and loop.
hang:	hlt
	jmp	hang

 
a20wait:
	in	al,	0x64
	test	al,	2
	jnz	a20wait
	ret 

a20wait2:
	in	al,	0x64
	test	al,	1
	jz	a20wait2
	ret

enabled:		db	"Enabled", 0
disabled:		db	"Disabled", 0
message:		db	"Long Mode not available!", 0
cpuid:			db	"cpuid", 0
hi:			db	"hi",0


times	510-($-$$)	db	0
			dw	0xAA55		; Boot signature.
