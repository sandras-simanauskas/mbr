org	0x7C00
bits	16

	cli
	cld

; Disable cursor.

	mov	dx,		0x03D4
	mov	al,		0x0A
	out	dx,		al 
	inc	dx
	mov	al,		0x3F
	out	dx,		al

; Set segments and stack.

	xor	eax,		eax
	mov	ds,		ax
	mov	es,		ax
	mov	fs,		ax
	mov	gs,		ax
	mov	ss,		ax
	mov	sp,		0x7C00

	jmp	0:start
start:

; Enable A20.
; Disable keyboard.

	call	empty_8042
	mov	al,		0xAD
	out	0x64,		al

; Read from input.

	call	empty_8042
	mov	al,		0xD0
	out	0x64,		al

; Get data.

full_8042:
	in	al,	0x64
	test	al,	1
	jz	full_8042

	in	al,		0x60
	push	eax

; Write to output.

	call	empty_8042
	mov	al,		0xD1
	out	0x64,		al

; Set A20 enable bit.

	call	empty_8042
	pop	eax
	or	al,		2
	out	0x60,		al

; Enable keyboard.

	call	empty_8042
	mov	al,		0xAE
	out	0x64,		al

	call	empty_8042


; Clear the Paging Structure buffer.

	xor	eax,		eax
	mov	edi,		0x1000
	push	di
	mov	ecx,		0x1000
	rep	stosd
	pop	di

; Build the Page Map Level 4.
; es:di points to the Page Map Level 4 table.

	mov	eax,		0x00002003			; Address of the Page Directory Pointer Table with present and writable flags set.
	mov	[0x1000],	eax				; Store the value of EAX as the first PML4E.

; Build the Page Directory Pointer Table.

	mov	eax,		0x00003003			; Address of the Page Directory with present and writable flags set.
	mov	[0x2000],	eax				; Store the value of EAX as the first PDPTE.

; Build the Page Directory.

	mov	eax,		0x00004003			; Address of the Page Table with present and writable flags set.
	mov	[0x3000],	eax				; Store to value of EAX as the first PDE.

	push	di						; Save DI for the time being.

	mov	di,		0x4000				; Point DI to the page table.
	mov	eax,		0x00000003			; Move the flags into EAX - and point it to 0x0000.

build_page_table:
	mov	[es:di],	eax
	add	eax,		0x1000
	add	di,		8
	cmp	eax,		0x200000			; If we did all 2MiB, end.
	jb	build_page_table
 
	pop	di						; Restore DI.

; Enter long mode.

	mov	eax,		10100000b			; Set the PAE and PGE bit.
	mov	cr4,		eax

	mov	edx,		edi				; Point CR3 at the PML4.
	mov	cr3,		edx

	mov	ecx,		0xC0000080			; Read from the EFER MSR.
	rdmsr

	or	eax,		0x00000100			; Set the LME bit.
	wrmsr

	mov	ebx,		cr0				; Activate long mode -
	or	ebx,		0x80000001			; - by enabling paging and protection simultaneously.
	mov	cr0,		ebx

	lgdt	[gdt]					; Load GDT.Pointer defined below.

	jmp	8:long_mode				; Load CS with 64 bit segment and flush the instruction cache 

; Helper functions.

empty_8042:
        in      al,0x64
        test    al,2
        jnz     empty_8042
        ret

bits	64

long_mode:
	mov	ax,		0x0010
	mov	ds,		ax
	mov	es,		ax
	mov	fs,		ax
	mov	gs,		ax
	mov	ss,		ax

; Blank the screen.

	mov	edi,		0xB8000
	mov	rcx,		500
	mov	rax,		0x1F201F201F201F20
rep	stosq
	hlt

gdt:			dw	23
			dd	gdt
			dw	0x0000

			dq	0x00209A0000000000
			dq	0x0000920000000000

times	510 - ($ - $$)	db	0
			dw	0xAA55
