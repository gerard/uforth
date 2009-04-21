	.include	"syscalls.asi"
	.include	"regdefs.asi"

	.macro vtest reg bits
		tst	\reg, #0xff
		tsteq	\reg, #0xf00
		beq	panic
	.endm

	.text
	.align	2
	.global op_add
	.global	op_dot

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
	bl	print_num_lf
	write	#1, r0, #16
	pop	{lr}
	bx	lr
