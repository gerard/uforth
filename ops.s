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
	.global	op_semicolon	@ NAME: ";"

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
op_colon_helpers_mov_r0_0:
	mov	r0, #0
op_colon_helpers_orr_r0_imm:
	orr	r0, #0
op_colon_helpers_bx_r0:
	bx	r0
op_colon_helpers_mov_lr_pc:
	mov	lr, pc

op_semicolon:
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

	@ The tricky part, we look for the symbol, we load its address and then
	@ we would need to generate the code to load it.  The only way I come
	@ up is byte by byte.  We mask the stuff we need and then we modify an
	@ orr instruction which gets emitted.
	@ This can be done in a cleaner way, but lets not overdoit in the first
	@ try.
.Lop_colon_restart:
	push	{r0}
	strtok	#0x20
	bl	symtable_restart
	bl	symtable_lookup
	pop	{r0}

	ldr	r2, [stp]
	cmp	r2, #0
	beq	.Lop_colon_restart	@ Unrecognized symbol, skip for now

	ldrb	r3, [r2]
	ldrb	r4, [r2, #4]
	cmp	r3, #0x3b	@ ':'
	cmpeq	r4, #0x0
	beq	.Lop_colon_end
	ldr	r2, [stp, #4]

	# Set r0 to zero
	ldr	r1, op_colon_helpers_mov_r0_0
	str	r1, [r0], #4

	# LSB
	and	r3, r2, #0xff
	ldr	r1, op_colon_helpers_orr_r0_imm
	orr	r1, r3
	str	r1, [r0], #4

	ror	r2, #8
	and	r3, r2, #0xff
	ldr	r1, op_colon_helpers_orr_r0_imm
	orr	r1, r3
	orr	r1, #0xc00
	str	r1, [r0], #4

	ror	r2, #8
	and	r3, r2, #0xff
	ldr	r1, op_colon_helpers_orr_r0_imm
	orr	r1, r3
	orr	r1, #0x800
	str	r1, [r0], #4

	# MSB
	ror	r2, #8
	and	r3, r2, #0xff
	ldr	r1, op_colon_helpers_orr_r0_imm
	orr	r1, r3
	orr	r1, #0x400
	str	r1, [r0], #4

	# r0 is finally constructed, branch and link
	ldr	r1, op_colon_helpers_mov_lr_pc
	str	r1, [r0], #4
	ldr	r1, op_colon_helpers_bx_r0
	str	r1, [r0], #4
	b	.Lop_colon_restart

.Lop_colon_end:
	@ We are done, close the subroutine with pop lr + bx lr
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
