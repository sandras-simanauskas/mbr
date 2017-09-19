; rax	top of data stack
; rbx	scratch
; rcx
; rdx	top of stack extention for double precision

; rsi
; rdi
; rbp	data stack
; rsp	code stack

; r8
; r9
; r10
; r11

; r12
; r13
; r14
; r15

%define	CELL		8
%define	PAGE		0x1000

%macro	BUFFER	1
	DQ	%1
	times	%1	DB	0
%endmacro

%macro	LOCAL	1
	%1:
%endmacro

%macro	GLOBAL	1
global	%1
	%1:
%endmacro

%macro	RESERVE	1
	times	%1	DB	0
%endmacro

%macro	ASCII	1
	DQ	.end-.start
.start:	DB	%1
.end:
%endmacro

%macro	DROP	0
	mov	rax,	[rbp]
	lea	rbp,	[rbp-CELL]
%endmacro

%macro	DUP	0
	lea	rbp,	[rbp+CELL]
	mov	[rbp],	rax
%endmacro

%macro	LIT	1
	DUP
	mov	rax,	%1
%endmacro

%macro	NIP	0
	lea	rbp,	[rbp-CELL]
%endmacro

%macro	OVER	0
	DUP
	mov	rax,	[rbp-CELL]
%endmacro	

%macro	PUSH	0
	push	rax
	DROP
%endmacro

%macro	PULL	0
	DUP
	pop	rax
%endmacro

%macro	SHIFTL	0
	shl	rax,	1
%endmacro

%macro	SHIFTR	0
	shr	rax,	1
%endmacro

%macro	ROTATEL	0
	rol	rax,	1
%endmacro

%macro	ROTATER	0
	ror	rax,	1
%endmacro

%macro	NOT	0
	not	rax
%endmacro

%macro	AND	0
	and	rax,	[rbp]
	NIP
%endmacro

%macro	OR	0
	or	rax,	[rbp]
	NIP
%endmacro

%macro	XOR	0
	xor	rax,	[rbp]
	NIP
%endmacro

%macro	ADD	0
	add	rax,	[rbp]
	NIP
%endmacro

%macro	SUB	0
	sub	[rbp],	rax
	DROP
%endmacro

%macro	MUL	0
	mov	rbx,	rax
	DROP
	mul	rbx
%endmacro

%macro	DIV	0
	xor	rdx,	rdx
	mov	rbx,	rax
	DROP
	div	rbx
%endmacro

%macro	DOUBLE	0
	LIT	rdx
	xor	rdx,	rdx
%endmacro

%macro	RATIO	0
	mov	rbx,	rax
	DROP
	mul	qword [rbp]
	NIP
	div	rbx
%endmacro

%macro	FETCH	0
	mov	rax,	[rax]
%endmacro

%macro	STORE	0
	mov	rbx,	[rbp]
	mov	[rax],	rbx
	mov	rax,	[rbp-CELL]
	lea	rbp,	[rbp-CELL-CELL]
%endmacro

%macro	IF	1
	cmp	rax,	0
	jnz	%1
%endmacro
