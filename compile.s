@ Copyright (c) 2009, Gerard Lledo Vives <gerard.lledo@gmail.com>
@ This program is open source.  For license terms, see the LICENSE file.

	.include	"assembler.asi"
	.include	"regdefs.asi"
	.include	"syscalls.asi"
	.include	"lib.asi"

	.section	.rodata
	.align	2

.LCTERMIN_IF_ELSE:
	.asciz	"ELSE"
.LCTERMIN_IF_THEN:
	.asciz	"THEN"
	.ascii	"\x00"

.LCTERMIN_DO_LOOP:
	.asciz	"LOOP"
	.asciz	"I"
	.ascii	"\x00"

	.text
	.align	2
	.global	compile
	.global	compile_entry
	.global	compile_exit
	.global	compile_if	@ NAME: "IF"
	.global	compile_do	@ NAME: "DO"

@ This shouldn't be necessary if we would assemble ourselves, but lets allow
@ the system assembler do it for us: we are lazy.
helpers_add_r0_1:
	add	r0, #1
helpers_cmp_r0_r1:
	cmp	r0, r1
helpers_cmp_r0_0:
	cmp	r0, #0
helpers_ldr_r0_vsp:
	ldr	r0, [vsp, #-4]!
helpers_ldr_r1_vsp:
	ldr	r1, [vsp, #-4]!
helpers_str_r0_vsp:
	str	r0, [vsp], #4

@ Compiles a load operation of r1 on r0
@ r0 is moved to next available location
compile_load32:
	mov	r2, r1

	@ Set r0 to zero
	GMOV	I, #0, #0

	@ LSB
	ands	r3, r2, #0xff
	beq	.Lcompile_load32_BYTE_2
	GORR	#0, #0, r3, #0

.Lcompile_load32_BYTE_2:
	ror	r2, #8
	ands	r3, r2, #0xff
	beq	.Lcompile_load32_BYTE_3
	GORR	#0, #0, r3, #0xC

.Lcompile_load32_BYTE_3:
	ror	r2, #8
	ands	r3, r2, #0xff
	beq	.Lcompile_load32_BYTE_4
	GORR	#0, #0, r3, #0x8

.Lcompile_load32_BYTE_4:	@ aka, MSB
	ror	r2, #8
	ands	r3, r2, #0xff
	beq	.Lcompile_load32_end
	GORR	#0, #0, r3, #0x4

.Lcompile_load32_end:
	bx	lr

execmem_get:
	ldr	r0, .Lcompilation_pointer
	ldr	r0, [r0]
	cmp	r0, #0
	bne	.Lexecmem_get_done

	@ TODO: We have no mmap memory management.  That means that after our
	@ page (4K) runs out, well get a SIGSEGV.  Fix that later: if you get
	@ to write 4K of useful code right now, you shouldn't be using this
	@ forth implementation anyway.
	push	{r1, r2, r3, r4, r5}
	mmap2	#0, #4096, #0x7, #0x22, #-1, #0
	pop	{r1, r2, r3, r4, r5}

.Lexecmem_get_done:
	bx	lr

execmem_store:
	ldr	r1, .Lcompilation_pointer
	str	r0, [r1]
	bx	lr

@ This function is the only one that needs to return the entry point of the
@ compiled code.  The rest work trough the execmem iface.
compile_entry:
	push	{lr}

	bl	execmem_get
	GPUSH	#0x40, #0x0
	bl	execmem_store

	@ Our return value
	sub	r0, #4

	pop	{lr}
	bx	lr

compile_exit:
	push	{lr}
	bl	execmem_get

	GPOP	#0x40, #0x0
	GBX	#14

	bl	execmem_store
	pop	{lr}
	bx	lr

@ The meat of the colon opearator.  No other compilation subroutine can be
@ called from outside this.
@ Input:  bfp (global), r0  (compilation terminator)
@ Output: r0  (pointer to termination string)
compile:
	push	{lr}

	@ Move delimiter somewhere else
	mov	r8, r0

	@ Save initial exec point in case we need to backup
	bl	execmem_get
	push	{r0}

	@ There are 4 valid tokens that can be found: interpretable symbols,
	@ compilable symbols, immediates and terminators. Watch out, this is
	@ the meat:
	@ 1. Check if the token is a symbol, if its not, jump to 3.
	@ 2. If it's interpretable jump to 6, if not (compilable) jump to 7.
	@ 3. Is it a delimiter? then *finish gracefuly*. Otherwise, continue.
	@ 4. Parse a number. If it fails, *finish on error*; ow continue.
	@ 5. Emit immediate loading code and go back to 1.
	@ 6. Emit code to jump to subroutine and go back to 1.
	@ 7. Run the code emiting subroutine (comp token) and go back to 1.
.Lcompile_restart:
	strtok	#0x20
	mov	r6, r1		@ Save token length for immediate parsing
	bl	symtable_restart
	bl	symtable_lookup

	beq	.Lcompile_lookup_failed
	@ symtable_lookup found something, is it interpretated or compiled?
	push	{r0}
	bl	symtable_getflag_interp
	pop	{r0}
	bne	.Lcompile_interpretation
	beq	.Lcompile_compilation

.Lcompile_lookup_failed:

	@ We look now for terminators. Note the terminators structure.  It's
	@ a NULL-terminated list of NULL-terminated strings.
	mov	r1, r8

.Lcompile_terminator_restart:
	@ Try terminator
	bl	strcmp
	moveq	r0, r1
	beq	.Lcompile_end

	@ Terminator failed, chomp it
.Lcompile_eating_terminator:
	ldrb	r2, [r1], #1
	cmp	r2, #0
	bne	.Lcompile_eating_terminator

	@ Any other delimiter to test?
	ldrb	r2, [r1]
	cmp	r2, #0
	beq	.Lcompile_terminators_failed
	b	.Lcompile_terminator_restart

.Lcompile_terminators_failed:
	@ Try immediate
	mov	r1, r6
	bl	parse_num
	mov	r1, r0
	beq	.Lcompile_end_fail

	@ Immediate success
	bl	execmem_get
	bl	compile_load32
	ldr	r1, helpers_str_r0_vsp
	str	r1, [r0], #4
	bl	execmem_store
	b	.Lcompile_restart

.Lcompile_interpretation:
	bl	symtable_get_fun
	mov	r1, r0

	bl	execmem_get
	bl	compile_load32

	@ r0 is finally constructed, branch and link
	GMOV	R, #14, #15
	GBX	#0

	bl	execmem_store
	b	.Lcompile_restart

.Lcompile_compilation:
	bl	symtable_get_fun
	push	{r8}
	mov	lr, pc
	bx	r0
	pop	{r8}
	b	.Lcompile_restart

@ If we have failed, we restore the execmem pointer
.Lcompile_end_fail:
	pop	{r0}
	bl	execmem_store
	push	{r0}

.Lcompile_end:
	pop	{lr}		@ We don't care about this value
	pop	{lr}
	bx	lr

compile_if:
	push	{lr}

	bl	execmem_get
	ldr	r1, helpers_ldr_r0_vsp
	str	r1, [r0], #4
	ldr	r1, helpers_cmp_r0_0
	str	r1, [r0], #4

	@ TO FILL: IF-FALSE Entry
	mov	r4, r0
	add	r0, #4			@ Space for branch instruction
	bl	execmem_store

	ldr	r0, .LTERMIN_IF_ELSE
	push	{r4}
	bl	compile
	mov	r6, r0
	pop	{r4}

	bl	execmem_get

	@ TO FILL: IF-TRUE Exit
	mov	r5, r0
	add	r0, #4			@ Space for branch instruction

	@ FILL: IF-FALSE Entry
	GB	EQ, r4, r0

	@ Was it IF .. THEN or IF .. ELSE .. THEN ?
	ldr	r2, .LTERMIN_IF_THEN
	cmp	r2, r6

	@ If it was a THEN, then we dont need to fill a branch to skip the
	@ FALSE part, it doesn't exist at all
	@ Note that we have left a space for a branch instruction that won't be
	@ filled.  That's fine, as the branch that skip the IF .. THEN part
	@ expects it to be there, and 0x0 is just a nop on ARM.
	@ Of course, this should be optimized in the future, but seems minor
	@ right now.
	bleq	execmem_store
	beq	.Lcompile_if_short

	ldr	r0, .LTERMIN_IF_THEN
	push	{r5}
	bl	compile
	pop	{r5}

	bl	execmem_get
	@ FILL: IF-TRUE Exit
	@ Note we don't need to execmem_store, as the space was already alloc
	GB	AL, r5, r0

.Lcompile_if_short:
	pop	{lr}
	bx	lr

.Lcompilation_pointer:
	.local	compilation_pointer
	.word	compilation_pointer
	.lcomm	compilation_pointer, 4

compile_do:
	push	{lr}

	@ $r0 gets the starting point and $r1 the end.  The cmp is not done
	@ until the end though.
	bl	execmem_get
	ldr	r1, helpers_ldr_r0_vsp
	str	r1, [r0], #4
	ldr	r1, helpers_ldr_r1_vsp
	str	r1, [r0], #4
	mov	r2, r0			@ This is where we jump back from LOOP
	GPUSH	#0x0, #0x3
	bl	execmem_store

	push	{r2}

.Lcompile_do_compile:
	ldr	r0, .LTERMIN_DO_LOOP
	bl	compile

	ldr	r1, .LTERMIN_DO_LOOP
	cmp	r1, r0
	beq	.Lcompile_do_done

	@ No other terminator defined other than I
	bl	execmem_get
	ldr	r1, helpers_str_r0_vsp
	str	r1, [r0], #4
	bl	execmem_store
	b	.Lcompile_do_compile

.Lcompile_do_done:
	pop	{r2}

	@ Pop the counters, add 1 to the starting point and compare
	bl	execmem_get

	GPOP	#0x0, #0x3
	ldr	r1, helpers_add_r0_1
	str	r1, [r0], #4
	ldr	r1, helpers_cmp_r0_r1
	str	r1, [r0], #4
	GB	NE, r0, r2

	bl	execmem_store

	pop	{lr}
	bx	lr

	.align	2
.LTERMIN_IF_ELSE:
	.word	.LCTERMIN_IF_ELSE
.LTERMIN_IF_THEN:
	.word	.LCTERMIN_IF_THEN
.LTERMIN_DO_LOOP:
	.word	.LCTERMIN_DO_LOOP
.LTERMIN_DO_I:
