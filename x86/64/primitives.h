; rax	top of data stack
; rbx	scratch
; rcx	unused
; rdx	top of data stack double precision extention

; rsi	unused
; rdi	unused
; rbp	data stack pointer
; rsp	code stack pointer

; r8	unused
; r9	unused
; r10	unused
; r11	unused

; r12	unused
; r13	unused
; r14	unused
; r15	unused

%define	CELL	8

%macro	LOCAL	1
	%1:
%endmacro

%macro	GLOBAL	1
global	%1
	%1:
%endmacro

%macro	STRING	2
%1:	dq	.end-.start
.start:	db	%2
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

%macro	LIT	1
	DUP
	mov	rax,	%1
%endmacro

%macro	SHIFTL	0
	shl	rax,	1
%endmacro

%macro	SHIFTR	0
	sar	rax,	1
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

%macro	JNZ	1
	cmp	rax,	0
	jnz	%1
%endmacro

%macro	JS	1
	js	%1
%endmacro
