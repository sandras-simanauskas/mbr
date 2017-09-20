; VBR.s - Volume Boot Record.

org	0x7C00
bits	16

; Head.

	mov dh, [si+1]

; Sector.

	mov ax, [si+2]
	inc ax				; The sector after loader.
	mov cl, al
	and cl, 0x3F

; Cylinder.

	shl ax, 1
	shl ax, 1
	mov ch, ah

; Load kernel.

	mov ah, 2			; Select BIOS disk read function.
	mov al, 8			; Number of sectors to read.
	mov bx, 0x8000			; Destination.
	int 0x13			; Read.

	jc error			; Read successful?

; Disable VGA hardware cursor.

	mov dx, 0x03D4			; VGA index register.
	mov al, 0x0A			; Low cursor shape.
	out dx, al			; Send.

	inc dx				; VGA data register.
	mov al, 000100000b		; Bit 5 set means the cursor is disabled.
	out dx, al			; Send.

; For now we use the classical method of enabling the A20 gate.

	call wait_8042_empty		; Wait for the 8042 input register to become empty.
	mov al, 0xAD			; Command to disable keyboard interfaces.
	out 0x64, al			; Send the command.

	call wait_8042_empty		; Wait for the 8042 input register to become empty.
	mov al, 0xD0			; Command to read from input.
	out 0x64, al			; Send the command

wait_8042_full:				; We wait until the data is ready for us to read. Can also work as "press any key to continue".
	in al, 0x64			; Read 8042 status register.						
	test al, 1			; Bit 0 clear means output register (0x60) does not have data for system.
	jz wait_8042_full		; We wait until it does.

	in al, 0x60			; Get data.
	push ax				; Save data.

	call wait_8042_empty		; We wait until we can send the next command.
	mov al, 0xD1			; Command to write to output port.
	out 0x64, al			; Send the command. Next byte written to port 0x60 is placed in the 8042 output port.

	call wait_8042_empty		; We wait until we can send the next command.
	pop ax				; Restore data.
	or al, 2			; Set A20 enable bit.
	out 0x60, al			; Send data.

	call wait_8042_empty		; We wait until we can send the next command.
	mov al, 0xAE			; Command to enable keyboard interfaces.
	out 0x64, al			; Send the command.

	call wait_8042_empty		; We wait until 8042 has read our command and continue.

; Build Paging Structures.

	xor eax, eax			; Clear the Paging Structure buffer.
	mov edi, 0x00001000		; Buffer address.
	mov ecx, 0x00001000		; 0x00001000 dwords.
rep	stosd				; Store.

	mov dword [0x1000], 0x00002003	; Store the address of the Page Directory Pointer Table with present and writable flags set as the first Page Map Level 4 entry.

	mov dword [0x2000], 0x00003003	; Store the address of the Page Directory with present and writable flags set as the first Page Directory Pointer Table entry.

	mov dword [0x3000], 0x00004003	; Store to address of the Page Table with present and writable flags set as the first Page Directory entry.

; Build the Page Table.

	mov di, 0x4000			; Point di to the Page Table.
	mov eax, 0x00000003		; Point eax to 0 with present and writable flags set.

build_page_table:
	mov [es:di], eax
	add eax, 0x00001000
	add di, 8
	cmp eax, 0x00200000		; If we did all 2MiB, end.
	jb build_page_table

; Enter long mode.

	mov eax, cr4
	or eax, 10100000b		; Set the PAE and PGE bit.	
	mov cr4, eax

	mov edi, 0x00001000
	mov cr3, edi			; Point CR3 at the PML4.

	mov ecx, 0xC0000080		; Read from the EFER MSR.
	rdmsr

	or eax, 0x00000100		; Set the LME bit.
	wrmsr

	mov eax, cr0
	or eax, 0x80000001		; Activate long mode by enabling paging and protection simultaneously.
	mov cr0, eax

	lgdt [gdt]			; Load GDT.

	jmp 8:0x8000				; Load cs with 64 bit segment and flush the instruction cache by long jumping to the kernel.

error:	mov si, message

; Fallthrough.

print:	mov ah, 0xE			; Select BIOS print function.
	mov bh, 0			; Page number.
	mov bl, 0x7			; Color.
.loop:	lodsb				; Load byte to print.
	or al, al			; If zero.
	jz hang				; Terminate.
	int 0x10			; Else print.
	jmp .loop			; Next byte.

hang:	hlt

wait_8042_empty:			; We wait until the 8042 input register is empty.
	in al, 0x64			; Read 8042 status register.
	test al, 2			; Bit 1 set means input register (0x60/0x64) has data for 8042.
	jnz wait_8042_empty		; We wait until it doesn't.
	ret

message: db "Can not read kernel from disk!", 0

gdt:	dw 23
	dd gdt
	dw 0

	dq 0x00209A0000000000
	dq 0x0000920000000000

times	510-($-$$) db 0

dw 0xAA55				; VBR boot signature.
