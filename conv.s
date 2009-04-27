	.include	"syscalls.asi"
	.align	2
	.text
	.global	print_num
	.global	set_base

@ In:
@	* r0 (uint32_t)	=> Number to convert
@ Out:
@	* r0 (char *)	=> Addres to a 16 bytes buffer
print_num:
	push	{lr}
	ldr	r1, .Lbuffer_word
	ldr	r2, .Lbase
	ldrb	r4, [r2]
	mov	r3, #14

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
	pop	{lr}
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
