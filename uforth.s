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
	bleq	parse_num
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
	mov	r0, #10
	bl	set_base
.Lreadline:
	bic	bfp, bfp, #0xff
	read	#0, bfp, #0x100
	cmp	r0, #0x100
	beq	.Lerror
	cmp	r0, #0
	beq	.Lend
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
