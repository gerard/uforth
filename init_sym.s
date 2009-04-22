	.include	"regdefs.asi"
	.section	.rodata
	.align	2
.LCOP_DOT:
	.asciz	"."
.LCOP_ADD:
	.asciz	"+"
.LCOP_DOTS:
	.asciz	".s"
	.text
	.align	2
	.global init_symbols

init_sym:
	push	{lr}
	str	r1, [stp], #4
	str	r2, [stp], #4
	pop	{lr}
	bx	lr

init_symbols:
	push	{lr}
	ldr	r1, .LOP_DOT_ID
	ldr	r2, .LOP_DOT_OP
	bl	init_sym
	ldr	r1, .LOP_ADD_ID
	ldr	r2, .LOP_ADD_OP
	bl	init_sym
	ldr	r1, .LOP_DOTS_ID
	ldr	r2, .LOP_DOTS_OP
	bl	init_sym
	mov	r0, #0
	str	r0, [stp], #4
	str	r0, [stp], #4
	bic	stp, stp, #0xff
	bic	stp, stp, #0xf00
	pop	{lr}
	bx	lr

	.align	2
.LOP_DOT_ID:
	.word	.LCOP_DOT
.LOP_ADD_ID:
	.word	.LCOP_ADD
.LOP_DOTS_ID:
	.word	.LCOP_DOTS

.LOP_DOT_OP:
	.word	op_dot
.LOP_ADD_OP:
	.word	op_add
.LOP_DOTS_OP:
	.word	op_dots
