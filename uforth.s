	.include	"syscalls.asi"
	.include	"regdefs.asi"
	.section	.rodata
	.align 2
.LCnewline:
	.ascii	"\012"
	.text
	.align	2
	.global	_start
	.global panic

panic:
	exit	#1

@ Input:  bfp! (global)
@ Output: r0 (*token)
@	   Z (valid)
get_token:
	mov	r1, #0
	ldrb	r0, [bfp]
	movs	r0, r0
	beq	.Lget_token_end
	cmp	r0, #0x20		@ ' '
	addeq	bfp, #1
	beq	get_token
.Lget_token_getchar:
	ldrb	r0, [bfp, r1]
	movs	r0, r0
	beq	.Lget_token_end
	cmp	r0, #0x20
	beq	.Lget_token_end
	cmp	r0, #0xA
	beq	.Lget_token_end
	add	r1, #1
	cmp	r1, #8
	beq	.Lget_token_end
	b	.Lget_token_getchar
.Lget_token_end:
	cmp	r1, #0
	mov	r0, bfp
	add	bfp, bfp, r1
	bx	lr

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
	pop	{lr}
	bx	lr

parse_symbol:
	push	{lr}
.Lparse_symbol_repeat:
	@ Check operator ID
	ldr	r1, [stp], #4
	cmp	r1, #0
	beq	.Lparse_symbol_end
	bl	strcmp
	@ If succeded, run the associated method (eq), otherwise repeat (ne)
	ldreq	r1, [stp], #4
	moveq	lr, pc
	bxeq	r1
	bne	.Lparse_symbol_repeat
.Lparse_symbol_end:
	bic	stp, #0xff
	bic	stp, #0xf00
	pop	{lr}
	bx	lr

reduce_token:
	push	{lr}
	mov	r2, r0
	ldrb	r0, [r2]
	bl	isdigit
	mov	r0, r2
	bleq	parse_decimal
	blne	parse_symbol
	pop	{lr}
	bx	lr

parse_error:
	bx	lr

@ Entry point
_start:
	@ TODO: We need to be sure that the initial brk point is on a 1KB
	@       boundary
	brk	#0
	mov	vsp, r0
	add	r0, #0x1000
	brk	r0
	mov	stp, r0
	add	r0, #0x1000
	brk	r0
	mov	bfp, r0
	add	r0, #0x100
	brk	r0
	bl	init_symbols
.Lreadline:
	bic	bfp, bfp, #0xff
	read	#0, bfp, #0x100
	cmp	r0, #0x100
	beq	.Lerror
.Lrepeat:
	bl	get_token
	beq	.Lreadline
	bl	reduce_token
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

	.align	2
.Lnewline:
	.word	.LCnewline
