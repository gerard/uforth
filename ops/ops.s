@ Copyright (c) 2009, Gerard Lledo Vives <gerard.lledo@gmail.com>
@ This program is open source.  For license terms, see the LICENSE file.

	.include	"syscalls.asi"
	.include	"regdefs.asi"
	.include	"lib.asi"
	.include	"common.asi"

	.section	.rodata
	.align	2

.LCDELIM_COLON:
	@ The assembler chokes if we use ";"
	.asciz	"\x3B"
	.ascii	"\x00"

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
	.global	op_allot	@ NAME: "ALLOT"
	.global	op_store	@ NAME: "!"
	.global op_fetch	@ NAME: "@"
	.global	op_swap		@ NAME: "SWAP"
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

op_colon:
	push	{lr}
	strtok	#0x20
	push	{r0, r1}
	bl	symtable_restart
	bl	symtable_lookup
	pop	{r0, r1}

	@ We just copy the name if none was found
	bleq	symtable_set_name

	push	{stp}
	bl	compile_entry
	push	{r0}
	ldr	r0, .LDELIM_COLON
	bl	compile
	bl	compile_exit
	pop	{r0}
	pop	{stp}
	bl	symtable_set_fun
	bl	symtable_setflag_interp

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

	.align	2
.LDELIM_COLON:
	.word	.LCDELIM_COLON

