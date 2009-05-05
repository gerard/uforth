	.include	"syscalls.asi"
	.include	"regdefs.asi"
	.include	"lib.asi"

	.macro vtest reg
		tst	\reg, #0xff
		tsteq	\reg, #0xf00
		beq	panic
	.endm
	.macro VPOP reg
		vtest	vsp
		ldr	\reg, [vsp, #-4]!
	.endm
	.macro VPUSH reg
		str	\reg, [vsp], #4
	.endm

	.text
	.align	2
	.global	op_hex		@ NAME: "HEX"
	.global	op_decimal	@ NAME: "DECIMAL"
	.global	op_add		@ NAME: "+"
	.global	op_mult		@ NAME: "*"
	.global	op_dot		@ NAME: "."
	.global op_colon	@ NAME: ":"
	.global op_drop		@ NAME: "DROP"
	.global op_dup		@ NAME: "DUP"
	.global	op_dots		@ NAME: ".s"
	.global	op_semicolon	@ NAME: ";"
	.global	op_allot	@ NAME: "ALLOT"
	.global	op_store	@ NAME: "!"
	.global op_fetch	@ NAME: "@"
	.global	op_swap		@ NAME: "SWAP"
	.global	op_equals	@ NAME: "="
	.global	op_type		@ NAME: "TYPE"
	.global	op_bye		@ NAME: "BYE"

op_type:
	push	{lr}
	VPOP	r0
	VPOP	r1
	mov	r3, #0
.Lop_type_restart:
	cmp	r3, r0
	beq	.Lop_type_end
	ldrb	r2, [r1, r3]
	add	r3, #1
	push	{r0, r1}
	putchar r2
	pop	{r0, r1}
	b	.Lop_type_restart
.Lop_type_end:
	putchar	#0xa
	pop	{lr}
	bx	lr

op_equals:
	VPOP	r0
	VPOP	r1
	cmp	r0, r1
	moveq	r0, #0		@ All bits CLEAR
	movne	r0, #-1		@ All bits SET
	VPUSH	r0
	bx	lr

op_allot:
	push	{lr}
	VPOP	r0
	sbrk	r0
	VPUSH	r0
	pop	{lr}
	bx	lr

op_store:
	VPOP	r0
	VPOP	r1
	str	r1, [r0]
	bx	lr

op_swap:
	VPOP	r0
	VPOP	r1
	VPUSH	r0
	VPUSH	r1
	bx	lr

op_hex:
	push	{lr}
	mov	r0, #16
	bl	set_base
	pop	{lr}
	bx	lr

op_decimal:
	push	{lr}
	mov	r0, #10
	bl	set_base
	pop	{lr}
	bx	lr

op_add:
	VPOP	r0
	VPOP	r1
	add	r0, r0, r1
	VPUSH	r0
	bx	lr

op_mult:
	VPOP	r1
	VPOP	r2
	mul	r0, r1, r2
	VPUSH	r0
	bx	lr

op_drop:
	VPOP	r0
	bx	lr

op_dot:
	push	{lr}
	VPOP	r0
	bl	print_num
	write	#1, r0, r1
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
op_colon_helpers_str_r0_vsp:
	str	r0, [vsp], #4

op_semicolon:
	bx	lr

@ Compiles a load operation of r1 on r0
@ r0 is moved to next available location
op_colon_compile_load32:
	# Set r0 to zero
	ldr	r2, op_colon_helpers_mov_r0_0
	str	r2, [r0], #4

	# LSB
	ands	r3, r1, #0xff
	beq	.Lop_colon_compile_load32_BYTE_2
	ldr	r2, op_colon_helpers_orr_r0_imm
	orr	r2, r3
	str	r2, [r0], #4

.Lop_colon_compile_load32_BYTE_2:
	ror	r1, #8
	ands	r3, r1, #0xff
	beq	.Lop_colon_compile_load32_BYTE_3
	ldr	r2, op_colon_helpers_orr_r0_imm
	orr	r2, r3
	orr	r2, #0xc00
	str	r2, [r0], #4

.Lop_colon_compile_load32_BYTE_3:
	ror	r1, #8
	ands	r3, r1, #0xff
	beq	.Lop_colon_compile_load32_BYTE_4
	ldr	r2, op_colon_helpers_orr_r0_imm
	orr	r2, r3
	orr	r2, #0x800
	str	r2, [r0], #4

.Lop_colon_compile_load32_BYTE_4:	# aka, MSB
	ror	r1, #8
	ands	r3, r1, #0xff
	beq	.Lop_colon_compile_load32_end
	ldr	r2, op_colon_helpers_orr_r0_imm
	orr	r2, r3
	orr	r2, #0x400
	str	r2, [r0], #4

.Lop_colon_compile_load32_end:
	bx	lr

op_colon:
	push	{lr}
	strtok	#0x20
	push	{r0, r1}
	bl	symtable_restart
	bl	symtable_lookup
	pop	{r0, r1}
	bne	.Lop_colon_no_allocate_name
	strncpy	stp, r0, r1
	mov	r4, stp
.Lop_colon_no_allocate_name:
	add	r4, #32
	push	{r1, r2, r4}
	mmap2	#0, #4096, #0x7, #0x22, #-1, #0
	pop	{r1, r2, r4}
	str	r0, [r4]
	ldr	r2, op_colon_helpers_push_lr
	str	r2, [r0], #4

	@ The tricky part, we look for the symbol, we load its address and then
	@ we would need to generate the code to load it.  The only way I come
	@ up is byte by byte.  We mask the stuff we need and then we modify an
	@ orr instruction which gets emitted.
	@ This can be done in a cleaner way, but lets not overdoit in the first
	@ try.
.Lop_colon_restart:
	push	{r0}		@ PUSH
	strtok	#0x20
	mov	r6, r1		@ Save token length for immediate parsing
	bl	symtable_restart
	bl	symtable_lookup

	ldrb	r2, [stp]
	cmp	r2, #0
	beq	.Lop_colon_try_immediate	@ Is it a number?
	pop	{r0}				@ POP@SYM

	cmp	r2, #0x3b	@ ';'
	beq	.Lop_colon_end
	ldr	r2, [stp, #32]

	mov	r1, r2
	bl	op_colon_compile_load32

	# r0 is finally constructed, branch and link
	ldr	r1, op_colon_helpers_mov_lr_pc
	str	r1, [r0], #4
	ldr	r1, op_colon_helpers_bx_r0
	str	r1, [r0], #4
	b	.Lop_colon_restart

.Lop_colon_try_immediate:
	mov	r1, r6
	bl	parse_num
	mov	r1, r0

	pop	{r0}				@ POP@IMM
	beq	.Lop_colon_end			@ No luck
	bl	op_colon_compile_load32
	ldr	r1, op_colon_helpers_str_r0_vsp
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
	VPOP	r0
	VPUSH	r0
	VPUSH	r0
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
	write	#1, r0, r1
	putchar #0x20
	pop	{r1}
	b	.Ldots_repeat
.Ldots_end:
	putchar #0xa
	pop	{lr}
	bx	lr

op_fetch:
	VPOP	r0
	ldr	r1, [r0]
	VPUSH	r1
	bx	lr

op_bye:
	exit	#0
