@ Copyright (c) 2009, Gerard Lledo Vives <gerard.lledo@gmail.com>
@ This program is open source.  For license terms, see the LICENSE file.

	.include	"common.asi"
	.include	"regdefs.asi"

	@ All operators here take 2 parameters and do a compare
	.macro	STK_CMP p0, p1
		VPOP	\p0
		VPOP	\p1
		cmp	\p1, \p0
	.endm

	.text
	.align	2
	.global	op_equals	@ NAME: "="
	.global op_greater_than	@ NAME: ">"
	.global op_less_than	@ NAME: "<"

op_equals:
	STK_CMP	r0, r1
	moveq	r0, #-1		@ All bits SET
	movne	r0, #0		@ All bits CLEAR
	VPUSH	r0
	bx	lr

op_greater_than:
	STK_CMP	r0, r1
	movgt	r0, #-1
	movle	r0, #0
	VPUSH	r0
	bx	lr

op_less_than:
	STK_CMP	r0, r1
	movlt	r0, #-1
	movpl	r0, #0
	VPUSH	r0
	bx	lr
