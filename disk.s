org	0x7C00
bits	16

	cli							; Disable interrupts. Re-enbale them once the IDT is set up.
	cld							; Ensure the direction flag points up.

; Disable VGA hardware cursor.

	mov dx, 0x03D4
	mov al, 0x0A
	out dx, al
	inc dx
	mov al, 0x3F
	out dx, al

; Set segments and stack.

	xor eax, eax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov sp, 0x7C00

; For now we use the classic method of enabling A20 gate.

	call 0:wait_8042_empty					; Wait for the 8042 input register to become empty while also canonicalizing cs:ip with a long call.
	mov al, 0xAD						; Command to disable keyboard interfaces.
	out 0x64, al						; Send the command.

	call wait_8042_empty					; Wait for the 8042 input register to become empty.
	mov al, 0xD0						; Command to read from input.
	out 0x64, al						; Send the command

wait_8042_full:							; We wait until the data is ready for us to read. Can also work as "press any key to continue".
	in al, 0x64						; Read 8042 status register.						
	test al, 1						; Bit 0 clear means output register (0x60) does not have data for system.
	jz wait_8042_full					; We wait until it does.

	in al, 0x60						; Get data.
	push ax							; Save data.

	call wait_8042_empty					; We wait until we can send the next command.
	mov al, 0xD1						; Command to write to output port.
	out 0x64, al						; Send the command. Next byte written to port 0x60 is placed in the 8042 output port.

	call wait_8042_empty					; We wait until we can send the next command.
	pop ax							; Restore data.
	or al, 2						; Set A20 enable bit.
	out 0x60, al						; Send data.

	call wait_8042_empty					; We wait until we can send the next command.
	mov al, 0xAE						; Command to enable keyboard interfaces.
	out 0x64, al						; Send the command.

	call wait_8042_empty					; We wait until 8042 has read our command.

; Clear the Paging Structure buffer.

	xor eax, eax
	mov edi, 0x1000
	mov ecx, 0x1000

	push di

rep	stosd

	pop di

; Build the Page Map Level 4.

	mov eax, 0x00002003			; Address of the Page Directory Pointer Table with present and writable flags set.
	mov [0x1000], eax			; Store the value of EAX as the first PML4E.

; Build the Page Directory Pointer Table.

	mov eax, 0x00003003			; Address of the Page Directory with present and writable flags set.
	mov [0x2000], eax			; Store the value of EAX as the first PDPTE.

; Build the Page Directory.

	mov eax, 0x00004003			; Address of the Page Table with present and writable flags set.
	mov [0x3000], eax			; Store to value of EAX as the first PDE.

	push di					; Save DI for the time being.

	mov di, 0x4000				; Point DI to the page table.
	mov eax, 0x00000003			; Move the flags into EAX - and point it to 0x0000.

build_page_table:
	mov [es:di], eax
	add eax, 0x00001000
	add di, 8
	cmp eax, 0x00200000			; If we did all 2MiB, end.
	jb build_page_table
 
	pop di					; Restore DI.

; Enter long mode.

	mov eax, 10100000b			; Set the PAE and PGE bit.
	mov cr4, eax

	mov edx, edi				; Point CR3 at the PML4.
	mov cr3, edx

	mov ecx, 0xC0000080			; Read from the EFER MSR.
	rdmsr

	or eax, 0x00000100			; Set the LME bit.
	wrmsr

	mov eax, cr0
	or eax, 0x80000001			; Activate long mode by enabling paging and protection simultaneously.
	mov cr0, eax

	lgdt [gdt]				; Load GDT.

	jmp 8:long_mode				; Load cs with 64 bit segment and flush the instruction cache.

; 16-bit subroutines.

wait_8042_empty:				; We wait until the 8042 input register is empty.
	in al, 0x64				; Read 8042 status register.
	test al, 2				; Bit 1 set means input register (0x60/0x64) has data for 8042.
	jnz wait_8042_empty			; We wait until it doesn't.
	ret

bits	64

long_mode:
	mov ax, 0x0010
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

; Blank the screen.

	mov edi, 0xB8000
	mov rcx, 500
	mov rax, 0x1F201F201F201F20
rep	stosq
	hlt

; Data.

gdt:	dw 23
	dd gdt
	dw 0

	dq 0x00209A0000000000
	dq 0x0000920000000000

; Pad and add signature.

times	510 - ($ - $$)	db 0
			dw 0xAA55
