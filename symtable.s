@ Copyright (c) 2009, Gerard Lledo Vives <gerard.lledo@gmail.com>
@ This program is open source.  For license terms, see the LICENSE file.

	.include	"regdefs.asi"
	.include	"flags.asi"
	.include	"lib.asi"
	.macro	GETFL flag
		ldr	r0, [stp, #32]
		tst	r0, \flag
	.endm
	.macro	SETFL flag
		ldr	r0, [stp, #32]
		orr	r0, \flag
		str	r0, [stp, #32]
	.endm

	.text
	.align	2
	.global	symtable_init
	.global	symtable_lookup
	.global	symtable_next
	.global	symtable_run
	.global	symtable_get_fun
	.global	symtable_set_fun
	.global symtable_get_name
	.global	symtable_set_name
	.global	symtable_getflag_interp
	.global	symtable_setflag_interp
	.global	symtable_set_null
	.global	symtable_restart

@ This module should, ideally, hide any implementation specifics of the
@ symbol table.  The format of a register is as follows:
@
@                32B                  4B   4B
@ +---------------------------------+----+----+
@ |          Symbol name            | FL | PT |
@ +---------------------------------+----+----+
@ FL => Flags field.
@ PT => Pointer to the subroutine.
@ The symbol name is 32B long as this is the standard symbol name size.

symtable_init:
	push	{lr}
	sbrk	#0x1000
	mov	stp, r0
	pop	{lr}
	bx	lr

@ Leave $stp pointing to the record matching $r0
symtable_lookup:
	push	{lr}
.Llookup_repeat:
	ldr	r1, [stp]
	cmp	r1, #0
	beq	.Llookup_end
	mov	r1, stp
	bl	strcmp
	blne	symtable_next
	bne	.Llookup_repeat
	Z_CLEAR
.Llookup_end:
	pop	{lr}
	bx	lr

symtable_next:
	add	stp, #40
	bx	lr

@ Runs the symtable record if valid
@ If not valid, set Z
symtable_run:
	push	{stp, lr}

	bl	symtable_getflag_interp
	beq	.Lrun_end		@ No interpretation semantics
	bl	symtable_get_fun
	beq	.Lrun_end		@ No such word

	mov	lr, pc
	bx	r0
	Z_CLEAR
.Lrun_end:
	pop	{stp, lr}
	bx	lr

@ Get the function pointer of the current record
@ Return in $r0, set Z accordingly
symtable_get_fun:
	ldr	r0, [stp, #36]
	cmp	r0, #0
	bx	lr

symtable_set_fun:
	str	r0, [stp, #36]
	bx	lr

symtable_get_name:
	mov	r0, stp
	bx	lr

symtable_set_name:
	push	{lr}
	cmp	r1, #36
	movhi	r1, #36
	strncpy	stp, r0, r1
	pop	{lr}
	bx	lr

symtable_getflag_interp:
	GETFL	#0x1
	bx	lr

symtable_setflag_interp:
	SETFL	#0x1
	bx	lr

symtable_set_null:
	mov	r1, #0
	mov	r0, #40
.Lset_null_restart:
	sub	r0, #4
	str	r1, [stp, r0]
	cmp	r0, #0
	beq	.Lset_null_restart
	bx	lr

symtable_restart:
	bic	stp, #0xff
	bic	stp, #0xf00
	bx	lr
