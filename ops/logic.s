@ Copyright (c) 2009, Gerard Lledo Vives <gerard.lledo@gmail.com>
@ This program is open source.  For license terms, see the LICENSE file.

	.include	"common.asi"
	.include	"regdefs.asi"

	@ All operators here take 2 parameters
	.macro	GET_P p0, p1
		VPOP	\p0
		VPOP	\p1
	.endm

	.text
	.align	2
	.global	op_equals	@ NAME: "="

op_equals:
	GET_P	r0, r1
	cmp	r0, r1
	moveq	r0, #0		@ All bits CLEAR
	movne	r0, #-1		@ All bits SET
	VPUSH	r0
	bx	lr
