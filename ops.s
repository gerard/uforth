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
	.global	op_mult		@ NAME: "*"
	.global	op_dot		@ NAME: "."
	.global op_colon	@ NAME: ":"
	.global op_dup		@ NAME: "DUP"
	.global	op_dots		@ NAME: ".s"

@ All these ops have just one parameter, which is global: the stack top (vsp)
op_add:
	vtest	vsp
	ldr	r0, [vsp, #-4]!
	vtest	vsp
	ldr	r1, [vsp, #-4]!
	add	r0, r0, r1
	str	r0, [vsp], #4
	bx	lr

op_mult:
	vtest	vsp
	ldr	r1, [vsp, #-4]!
	vtest	vsp
	ldr	r2, [vsp, #-4]!
	mul	r0, r1, r2
	str	r0, [vsp], #4
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

op_colon_helpers_push_lr:
	push	{lr}
op_colon_helpers_pop_lr:
	pop	{lr}
op_colon_helpers_bx_lr:
	bx	lr

op_colon:
	push	{lr}
	strtok	#0x20
	push	{r0, r1}
	bl	symtable_restart
	bl	symtable_lookup
	mov	r4, stp
	pop	{r0, r1}
	bne	.Lop_colon_no_allocate_name
	push	{r0, r1, r4}
	sbrk	#8
	mov	r3, r0
	pop	{r0, r1, r4}
	push	{r4}
	strncpy	r3, r0, r1
	pop	{r4}
	str	r0, [r4]
.Lop_colon_no_allocate_name:
	add	r4, #4
	push	{r1, r2, r4}
	mmap2	#0, #4096, #0x7, #0x22, #-1, #0
	pop	{r1, r2, r4}
	str	r0, [r4]
	ldr	r1, op_colon_helpers_push_lr
	str	r1, [r0], #4
	ldr	r1, op_colon_helpers_pop_lr
	str	r1, [r0], #4
	ldr	r1, op_colon_helpers_bx_lr
	str	r1, [r0], #4
	pop	{lr}
	bx	lr

op_dup:
	vtest	vsp
	ldr	r0, [vsp, #-4]
	str	r0, [vsp], #4
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
