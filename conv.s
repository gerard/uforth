@ Copyright (c) 2009, Gerard Lledo Vives <gerard.lledo@gmail.com>
@ This program is open source.  For license terms, see the LICENSE file.

	.include	"regdefs.asi"
	.include	"flags.asi"
	.include	"syscalls.asi"
	.include	"lib.asi"
	.align	2
	.text
	.global	parse_num
	.global	print_num
	.global	get_base
	.global	set_base

@ r0 => (char *) r1 => length of string
@ Returns the number in r0.
@ Z is set if no valid number can be parsed
parse_num:
	push	{lr}
	mov	r5, r0
	push	{r1}
	bl	get_base
	mov	r3, r0
	pop	{r1}
	mov	r2, #0

	@ Positive or negative number?
	ldrb	r0, [r5]
	cmp	r0, #0x2D		@ '-'
	addeq	r5, #1
	subeq	r1, #1
	moveq	r4, #-1
	movne	r4, #1

.Lparse_num_repeat:
	cmp	r1, #0
	beq	.Lparse_num_end
	sub	r1, #1
	ldrb	r0, [r5, r1]
	push	{r1}
	mov	r1, r3
	bl	isdigit
	pop	{r1}
	bne	.Lparse_num_error
	sub	r0, #0x30
	cmp	r0, #10
	subpl	r0, #0x7
	mla	r2, r4, r0, r2
	mul	r4, r3
	b	.Lparse_num_repeat
.Lparse_num_error:
	Z_CLEAR
.Lparse_num_end:
	Z_REVERT
	mov	r0, r2
	pop	{lr}
	bx	lr

@ In:
@	* r0 (uint32_t)	=> Number to convert
@ Out:
@	* r0 (char *)	=> Addres to a 16 bytes buffer
@	* r1 (uint32_t) => Length of r0
print_num:
	push	{lr}
	ldr	r1, .Lbuffer_word
	ldr	r2, .Lbase
	ldrb	r4, [r2]
	mov	r3, #14

	@ Handle negative numbers
	tst	r0, #0x80000000
	beq	.Lrestart
	push	{r0, r1}
	putchar	#0x2D
	pop	{r0, r1}
	bic	r0, #0x80000000
	eor	r0, #0x7F000000
	eor	r0, #0x00FF0000
	eor	r0, #0x0000FF00
	eor	r0, #0x000000FF
	add	r0, #1

.Lrestart:
	push	{r1, r3, r4}
	mov	r1, r4
	cmp	r1, #16
	bleq	div16
	beq	.Lprint_num_div_done
	cmp	r1, #10
	bleq	div10
	beq	.Lprint_num_div_done
	exit	#2
.Lprint_num_div_done:
	mov	r2, r1
	pop	{r1, r3, r4}
	cmp	r2, #10
	addlt	r2, #48			@ r0 + '0'
	addge	r2, #55			@ r0 + ('A' - 10)
	sub	r3, #1
	strb	r2, [r1, r3]
	cmp	r0, #0
	bne	.Lrestart

	ldr	r0, .Lbuffer_word
	add	r0, r0, r3
	rsb	r1, r3, #14
	pop	{lr}
	bx	lr

get_base:
	ldr	r1, .Lbase
	ldrb	r0, [r1]
	bx	lr

set_base:
	ldr	r1, .Lbase
	strb	r0, [r1]
	bx	lr

@ Based on formula: R0 = ((R0 - (R0 >> 30)) * 429496730) >> 32
@ http://www.sciencezero.org/index.php?title=ARM:_Division_by_10
div10:
	mov	r3, r0
	mov	r4, #10
	ldr	r1, =429496730
	sub	r0, r0, r0, lsr #30
	umull	r2, r0, r1, r0
	umull	r1, r2, r4, r0
	sub	r1, r3, r1
	bx	lr

div16:
	and	r1, r0, #0xf
	lsr	r0, #4
	bx	lr

@ Input:  r0 (numerator)
@	  r1 (denominator)
@ Output: r0 (quotient)
@	  r1 (remainder)
div:
	mov	r2, #0
.Ldiv_restart:
	subs	r0, r1
	addpl	r2, #1
	bpl	.Ldiv_restart
.Ldiv_end:
	add	r0, r1
	mov	r1, r0
	mov	r0, r2
	bx	lr

.Lbuffer_word:
	.local	buffer_8b
	.word	buffer_8b
	.comm	buffer_8b, 32, 4

.Lbase:
	.local	buffer_1b
	.word	buffer_1b
	.comm	buffer_1b, 1, 1
