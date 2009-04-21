	.align	2
	.text
	.global	print_num_lf

@ In:
@	* r0 (uint32_t)	=> Number to convert
@ Out:
@	* r0 (char *)	=> Addres to a 16 bytes buffer
print_num_lf:
	push	{lr}
	ldr	r1, .Lbuffer_word
	mov	r3, #0xa
	strb	r3, [r1, #15]
	mov	r3, #14
.Lrestart:
	and	r2, r0, #0xf
	cmp	r2, #10
	addlt	r2, #48			@ r0 + '0'
	addge	r2, #55			@ r0 + ('A' - 10)
	subs	r3, #1
	strb	r2, [r1, r3]
	lsrs	r0, #4
	bne	.Lrestart

	ldr	r0, .Lbuffer_word
	add	r0, r0, r3
	pop	{lr}
	bx	lr

.Lbuffer_word:
	.word	buffer_8b
	.comm	buffer_8b, 32, 4
