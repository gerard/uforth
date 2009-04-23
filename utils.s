	.include	"regdefs.asi"
	.text
	.align	2
	.global	lookup_symbol

@ Set Z if we didn't find anything
lookup_symbol:
	push	{lr}
.Llookup_symbol_repeat:
	ldr	r1, [stp], #4
	cmp	r1, #0
	beq	.Llookup_symbol_end
	bl	strcmp
	addne	stp, #4
	bne	.Llookup_symbol_repeat
	ldr	r0, [stp]
	movs	r0, r0
.Llookup_symbol_end:
	bic	stp, #0xff
	bic	stp, #0xf00
	pop	{lr}
	bx	lr
