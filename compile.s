	.include	"regdefs.asi"
	.include	"syscalls.asi"
	.include	"lib.asi"
	.text
	.align	2
	.global	compile
	.global	compile_entry
	.global	compile_exit

@ This shouldn't be necessary if we would assemble ourselves, but lets allow
@ the system assembler do it for us: we are lazy.
helpers_push_lr:
	push	{lr}
helpers_pop_lr:
	pop	{lr}
helpers_bx_lr:
	bx	lr
helpers_mov_r0_0:
	mov	r0, #0
helpers_orr_r0_imm:
	orr	r0, #0
helpers_bx_r0:
	bx	r0
helpers_mov_lr_pc:
	mov	lr, pc
helpers_str_r0_vsp:
	str	r0, [vsp], #4

@ Compiles a load operation of r1 on r0
@ r0 is moved to next available location
compile_load32:
	# Set r0 to zero
	ldr	r2, helpers_mov_r0_0
	str	r2, [r0], #4

	# LSB
	ands	r3, r1, #0xff
	beq	.Lcompile_load32_BYTE_2
	ldr	r2, helpers_orr_r0_imm
	orr	r2, r3
	str	r2, [r0], #4

.Lcompile_load32_BYTE_2:
	ror	r1, #8
	ands	r3, r1, #0xff
	beq	.Lcompile_load32_BYTE_3
	ldr	r2, helpers_orr_r0_imm
	orr	r2, r3
	orr	r2, #0xc00
	str	r2, [r0], #4

.Lcompile_load32_BYTE_3:
	ror	r1, #8
	ands	r3, r1, #0xff
	beq	.Lcompile_load32_BYTE_4
	ldr	r2, helpers_orr_r0_imm
	orr	r2, r3
	orr	r2, #0x800
	str	r2, [r0], #4

.Lcompile_load32_BYTE_4:	# aka, MSB
	ror	r1, #8
	ands	r3, r1, #0xff
	beq	.Lcompile_load32_end
	ldr	r2, helpers_orr_r0_imm
	orr	r2, r3
	orr	r2, #0x400
	str	r2, [r0], #4

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
	ldr	r1, helpers_push_lr
	str	r1, [r0], #4
	bl	execmem_store

	@ Our return value
	sub	r0, #4

	pop	{lr}
	bx	lr

compile_exit:
	push	{lr}
	bl	execmem_get

	ldr	r1, helpers_pop_lr
	str	r1, [r0], #4
	ldr	r1, helpers_bx_lr
	str	r1, [r0], #4

	bl	execmem_store
	pop	{lr}
	bx	lr

@ The meat of the colon opearator.  No other compilation subroutine can be
@ called from outside this.
@ Input:  bfp (global), r0  (compilation delimiter)
@ Output: r0  (compilation entry point)
compile:
	push	{lr}

	# Move delimiter somewhere else
	mov	r8, r0

	# Save initial exec point in case we need to backup
	bl	execmem_get
	push	{r0}

	@ The tricky part, we look for the symbol, we load its address and then
	@ we would need to generate the code to load it.  The only way I come
	@ up is byte by byte.  We mask the stuff we need and then we modify an
	@ orr instruction which gets emitted.
	@ This can be done in a cleaner way, but lets not overdoit in the first
	@ try.
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
	beq	panic

.Lcompile_lookup_failed:
	@ Try delimiter
	mov	r1, r8
	bl	strcmp
	beq	.Lcompile_end

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

	# r0 is finally constructed, branch and link
	ldr	r1, helpers_mov_lr_pc
	str	r1, [r0], #4
	ldr	r1, helpers_bx_r0
	str	r1, [r0], #4

	bl	execmem_store
	b	.Lcompile_restart

@ If we have failed, we restore the execmem pointer
.Lcompile_end_fail:
	pop	{r0}
	bl	execmem_store
	push	{r0}

.Lcompile_end:
	pop	{r0}
	pop	{lr}
	bx	lr

.Lcompilation_pointer:
	.local	compilation_pointer
	.word	compilation_pointer
	.lcomm	compilation_pointer, 4
