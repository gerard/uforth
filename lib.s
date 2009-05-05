	.include	"syscalls.asi"
	.include	"regdefs.asi"
	.include	"flags.asi"
	.macro cmpchar reg lower upper
		cmp	\reg, \lower
		bmi	.Lcmpchar_end\@
		cmp	\reg, \upper
		bpl	.Lcmpchar_fail\@
		Z_SET
		b	.Lcmpchar_end\@
	.Lcmpchar_fail\@:
		Z_CLEAR
	.Lcmpchar_end\@:
	.endm

	.text
	.align	2
	.global	isdigit
	.global	strcmp
	.global strncpy
	.global strtok
	.global putchar
	.global	sbrk
	.global	div

@ r0 => Digit candidate
@ r1 => Base
isdigit:
	add	r1, #0x30
	cmpchar	r0, #0x30, r1
	beq	.Lisdigit_end
	adds	r1, #0x7
	cmpchar r0, #0x41, r1
.Lisdigit_end:
	bx	lr

@ r0(*dest) r1(*src) r2(int n)
strncpy:
	cmp     r2, #0
	bxeq    lr

	mov	r4, #0

.Lstrncpy_repeat:
	ldrb	r3, [r1, r4]
	strb	r3, [r0, r4]
	add	r4, #1
	cmp	r4, r2
	cmpne	r3, #0
	bne	.Lstrncpy_repeat

	mov	r3, #0
.Lstrncpy_fill_zeros:
	cmp	r4, r2
	strneb	r3, [r0, r4]
	add	r4, #1
	bne	.Lstrncpy_fill_zeros

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

@ Input:  bfp! (global)
@ Input:  r0 (delim)
@ Output: r0 (*token)
@	   Z (valid)
strtok:
	mov	r1, #0
	ldrb	r2, [bfp]
	movs	r2, r2
	beq	.Lstrtok_end
	cmp	r2, r0
	addeq	bfp, #1
	beq	strtok
.Lstrtok_getchar:
	ldrb	r2, [bfp, r1]
	movs	r2, r2
	beq	.Lstrtok_end
	cmp	r2, r0
	beq	.Lstrtok_end
	cmp	r2, #0xA
	beq	.Lstrtok_end
	add	r1, #1
	beq	.Lstrtok_end
	b	.Lstrtok_getchar
.Lstrtok_end:
	cmp	r1, #0
	mov	r0, bfp
	add	bfp, bfp, r1
	bx	lr

putchar:
	ldr	r1, .Lbuffer_byte
	str	r0, [r1]
	write	#1, r1, #1
	bx	lr
	
sbrk:
	mov	r1, r0
	brk	#0
	mov	r2, r0
	add	r0, r1
	brk	r0
	mov	r0, r2
	bx	lr

.Lbuffer_byte:
	.local	buffer_1b
	.word	buffer_1b
	.comm	buffer_1b, 1, 1
