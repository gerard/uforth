	.include	"syscalls.asi"
	.include	"regdefs.asi"
	.include	"lib.asi"
	.include	"flags.asi"
	.text
	.align	2
	.global	_start
	.global panic

panic:
	exit	#1

@ r0 => (char *) r1 => length of string
parse_decimal:
	push	{lr}
	mov	r5, r0
	mov	r4, #1
	mov	r3, #10
	mov	r2, #0
.Lparse_decimal_repeat:
	cmp	r1, #0
	beq	.Lparse_decimal_end
	sub	r1, #1
	ldrb	r0, [r5, r1]
	bl	isdigit
	bne	.Lparse_decimal_error
	sub	r0, #0x30
	mla	r2, r4, r0, r2
	mul	r4, r3
	b	.Lparse_decimal_repeat
.Lparse_decimal_end:
	str	r2, [vsp], #4
.Lparse_decimal_error:
	movs	r0, r1
	Z_REVERT
	pop	{lr}
	bx	lr

@ This will return Z set if no symbol was found (via symtable_run)
parse_symbol:
	push	{lr}
	bl	symtable_lookup
	blne	symtable_run
	bl	symtable_restart
	pop	{lr}
	bx	lr

reduce_token:
	push	{lr}
	push	{r0, r1}
	bl	parse_symbol
	pop	{r0, r1}
	bleq	parse_decimal
	pop	{lr}
	bx	lr

@ Entry point
_start:
	@ TODO: We need to be sure that the initial brk point is on a 1KB
	@       boundary
	sbrk	#0x1000
	mov	vsp, r0
	sbrk	#0x1000
	mov	stp, r0
	sbrk	#0x100
	mov	bfp, r0
	bl	init_symbols
.Lreadline:
	bic	bfp, bfp, #0xff
	read	#0, bfp, #0x100
	cmp	r0, #0x100
	beq	.Lerror
.Lrepeat:
	strtok	#0x20
	beq	.Lreadline
	bl	reduce_token
	bne	.Lrepeat
	putchar #0x3f
	putchar #0xa
	b	.Lrepeat
.Lerror:
	fcntl	#0, #4, #00004000	@ sdtin, F_SETFL, O_NONBLOCK
.Lflush_stdin:
	read	#0, bfp, #0x100		@ Flush buffer
	movs	r0, r0
	bpl	.Lflush_stdin
	b	panic
.Lend:
	exit	#0
