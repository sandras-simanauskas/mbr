; mbr.s - Master Boot Record.

; assumptions:
; we are loaded at 0x7C00 physical. that may be 0x7C0:0 or 0:0x7C00.
;
; chorelist
;
; initialise:
;	set up segments
;	set up stack
;	relocate
;	canonicalize cs:ip by jumping to newly relocated code
;
; load vbr:
;	save active drive number
;	scan partition table
;	load active partition's vbr
;	jmp to loaded vbr

; We assume we are loaded at 0x7C00 physical. That may be 0x7C0:0 or 0:0x7C00.
; We preserve dl, the drive number, throughout the MBR.
; We expect exactly one active partition to be set, otherwise we throw an error.
; We do not use calls. Nothing returns. No need to preserve registers.

ORG	0x7A00									; We are actually at 0x7C00 but we will relocate to 0x7A00 before any calls or far jumps.
BITS	16

%define	active		0x80
%define inactive	0x00

%macro	partition	10							; 16 byte structure.
			db	%1						; Boot indicator bit flag (0x80 = active).
			db	%2						; Head.
			db	(%3 & 00111111b) | ((%4 >> 2) & 11000000b)	; Bits 0-5: sector, bits 6-7: upper two bits of cylinder.
			db	%4						; Lower 8 bits of cylinder.
			db	%5						; System ID.
			db	%6						; Ending Head
			db	(%7 & 00111111b) | ((%8 >> 2) & 11000000b)	; Bits 0-5: ending sector, bits 6-7: upper two bits of ending cylinder.
			db	%8						; Lower 8 bits of cylinder.
			dd	%9						; Relative Sector (to start of partition -- also equals the partition's starting LBA value)
			dd	%10						; Total sectors in partition.
%endmacro

	cli									; Disable interrupts. They will be enabled by the bootloader once in Protected/Long Mode.
	xor	cx,	cx							; We will also need cl cleared later.
	mov	ds,	cx
	mov	es,	cx
	mov	ss,	cx
	mov	sp,	0x7A00
	cld									; Ensure direction for string operations.

	; Relocate self to 0x7A00.
	mov	ch,	1							; cl is cleared. Move 0x0100 words.
	mov	si,	0x7C00							; Source.
	mov	di,	sp							; Destination. Bottom of relocation point is top of stack.
rep	movsw									; Move words.
	jmp	0:start								; Canonicalize cs:ip by far-jumping to relocated code.

start:
	xor	bx,	bx							; We will count active partitions in bx as we scan the partition table.
	mov	cl,	4							; Number of partitions to scan.
	mov	si,	partition_table

scan_partition_table:			
	mov	ax,	[si]
	and	ax,	0x80
	jz	next_partition_entry

	mov	di,	si							; Remember last active partition.
	inc	bx								; Number of active partitions.

next_partition_entry:
	add	si,	0x10							; Add offset to next parition.
	dec	cl								; Number of partitions left to scan.
	jcxz	partition_table_scan_done
	jmp	scan_partition_table						; Next partition.

partition_table_scan_done:
	cmp	bx,	1
	jl	no_active_partition
	jg	more_than_one_active_partition

	; Load active partition.
	mov	si,	di							; We memorized last (only) active partition in di.
	inc	si

	; Head.
	mov	dh,	[si]
	inc	si

	; Sector.
	mov	ax,	[si]
	mov	cl,	al
	and	cl,	00111111b

	; Cylinder.
	shl	ax,	2
	mov	ch,	ah

	mov	si,	di							; Active partition table entry address.

	mov	ah,	0x02
	mov	al,	0x01
	mov	bx,	0x7C00
	int	0x13								; Load sector.

	jc	can_not_read_vbr_from_disk

	cmp	word [0x7DFE],	0xAA55						; Check boot signature.
	jne	vbr_has_wrong_boot_signature

	jmp	0:0x7C00							; Jump to loaded code.

can_not_read_vbr_from_disk:
	mov	si,	error_can_not_read_vbr_from_disk
	jmp	print								; We do not return from print.

no_active_partition:
	mov	si,	error_no_active_partition
	jmp	print								; We do not return from print.

more_than_one_active_partition:
	mov	si,	error_more_than_one_active_partition
	jmp	print								; We do not return from print.

vbr_has_wrong_boot_signature:
	mov	si,	error_vbr_has_wrong_boot_signature
										; We do not return from print.
print:
	mov	ah,	0x0E							; Select bios function,
	mov	bh,	0							; page number,
	mov	bl,	0							; and foreground color.
.loop:
	lodsb									; Load byte to print,
	or	al,	al							; if the byte is 0
	jz	hang								; hang,
	int	0x10								; else print the character
	jmp	.loop								; and loop.

hang:
	hlt
	jmp	hang

error_can_not_read_vbr_from_disk:	db	"MBR: Error: Can not read VBR from disk.", 0
error_no_active_partition:		db	"MBR: Error: No active partition.", 0
error_more_than_one_active_partition:	db	"MBR: Error: More than one active partition.", 0
error_vbr_has_wrong_boot_signature:	db	"MBR: Error: VBR has wrong boot signature.", 0

times	0x01B4-($-$$)			db	0				; Fill with zeros up to the start of the data structures.

times	10				db	0				; Optional unique disk ID.

partition_table:
	;		active flag,	starting head,	starting sector,	starting cylinder,	system ID,	ending head,	ending sector,	ending cylinder,	relative sector,	sectors in partition
	partition	active,		0, 		2,			0,			0,		0,		0,		0,			0,			1
	partition	inactive,	0,		3,			0,			0,		0,		0,		0,			0,			1
	partition	inactive,	0,		4,			0,			0,		0,		0,		0,			0,			1
	partition	inactive,	0,		5,			0,			0,		0,		0,		0,			0,			1

					dw	0xAA55				; Boot signature.
