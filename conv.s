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
	push	{r1}
	mov	r1, r4
	bl	div
	mov	r2, r1
	pop	{r1}
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

.Lbuffer_word:
	.word	buffer_8b
	.comm	buffer_8b, 32, 4

.Lbase:
	.word	buffer_1b
	.comm	buffer_1b, 1, 1
