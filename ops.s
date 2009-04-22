	.include	"syscalls.asi"
	.include	"regdefs.asi"
	.include	"lib.asi"

	.macro vtest reg
		tst	\reg, #0xff
		tsteq	\reg, #0xf00
		beq	panic
	.endm

	.text
	.align	2
	.global	op_add		@ NAME: "+"
	.global	op_dot		@ NAME: "."
	.global	op_dots		@ NAME: ".s"

@ All these ops have just one parameter, which is global: the stack top (vsp)
op_add:
	push	{lr}
	vtest	vsp
	ldr	r0, [vsp, #-4]!
	vtest	vsp
	ldr	r1, [vsp, #-4]!
	add	r0, r0, r1
	str	r0, [vsp], #4
	pop	{lr}
	bx	lr

op_dot:
	push	{lr}
	vtest	vsp
	ldr	r0, [vsp, #-4]!
	bl	print_num
	write	#1, r0, #16
	putchar	#0xa
	pop	{lr}
	bx	lr

op_dots:
	push	{lr}
	vtest	vsp
	bic	r1, vsp, #0xff
	bic	r1, r1, #0xf00
.Ldots_repeat:
	cmp	r1, vsp
	beq	.Ldots_end
	ldr	r0, [r1], #4
	push	{r1}
	bl	print_num
	write	#1, r0, #16
	putchar #0x20
	pop	{r1}
	b	.Ldots_repeat
.Ldots_end:
	putchar #0xa
	pop	{lr}
	bx	lr
