	.include	"syscalls.asi"
	.macro cmpchar lower upper
		cmp	r0, \lower
		bmi	.Lcmp_chars_end
		cmp	r0, \upper
		cmpls	r0, r0
	.Lcmp_chars_end:
	.endm

	.text
	.align	2
	.global	isdigit
	.global	strcmp
	.global strncpy
	.global putchar

isdigit:
	cmpchar	#0x30, #0x39
	bx	lr

@ r0(*dest) r1(*src) r2(int n)
strncpy:
	mov	r4, r2
	ldrb	r3, [r1], #1
	strb	r3, [r0], #1
	subs	r2, #1
	bne	strncpy
	sub	r1, r4
	sub	r0, r4
	mov	r2, r4
	bx	lr

strcmp:
	mov	r2, r0
	mov	r3, r1
.Lstrcmp_repeat:
	ldrb	r4, [r2], #1
	ldrb	r5, [r3], #1
	cmp	r4, #0
	cmpne	r5, #0
	beq	.Lstrcmp_null
	cmp	r4, r5
	bne	.Lstrcmp_end
	b	.Lstrcmp_repeat
.Lstrcmp_null:
	cmp	r4, #0x20
	cmpne	r4, #0xA
	cmpne	r5, #0x20
	cmpne	r4, #0xA
.Lstrcmp_end:
	bx	lr

putchar:
	ldr	r1, .Lbuffer_byte
	str	r0, [r1]
	write	#1, r1, #1
	bx	lr
	
.Lbuffer_byte:
	.word	buffer_1b
	.comm	buffer_1b, 1, 1
