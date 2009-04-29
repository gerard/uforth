	.include	"regdefs.asi"
	.include	"flags.asi"
	.text
	.align	2
	.global	symtable_lookup
	.global	symtable_run
	.global	symtable_restart

@ Leave $stp pointing to the record matching $r0
symtable_lookup:
	push	{lr}
.Llookup_symbol_repeat:
	ldr	r1, [stp]
	cmp	r1, #0
	beq	.Llookup_symbol_end
	mov	r1, stp
	bl	strcmp
	addne	stp, #36
	bne	.Llookup_symbol_repeat
	Z_CLEAR
.Llookup_symbol_end:
	pop	{lr}
	bx	lr

@ Runs the symtable record if valid
@ If not valid, set Z
symtable_run:
	push	{stp, lr}
	ldr	r0, [stp, #32]
	cmp	r0, #0
	beq	.Lsymtable_run_end
	mov	lr, pc
	bx	r0
	Z_CLEAR
.Lsymtable_run_end:
	pop	{stp, lr}
	bx	lr

symtable_restart:
	bic	stp, #0xff
	bic	stp, #0xf00
	bx	lr
