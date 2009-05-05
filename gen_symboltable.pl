#!/usr/bin/perl -w
# vim: set noexpandtab:ts=8:sw=8
use 5.010;
use strict;

my %symbols;
open IN, "ops.s" or die "Can't open ops.s: $!\n";
while(<IN>) {
	next if !/\.global\s+(\S+).+\"(.*)\"/;
	# Maps symbols to symbol names
	$symbols{$1} = $2;
}

open OUT, ">/dev/stdout" or die "$!\n";

say OUT "	.include	\"regdefs.asi\"";
say OUT "	.section	.rodata";
say OUT "	.align		2";

for my $sym ( keys %symbols ) {
	(my $SYM = $sym) =~ tr/a-z/A-Z/;
	say OUT ".LC$SYM:";
	say OUT "	.asciz	\"$symbols{$sym}\"";
}

say OUT "	.text";
say OUT "	.align	2";
say OUT "	.global	init_symbols";
say OUT "";

say OUT "init_sym:";
say OUT "	push    {lr}";
say OUT "	mov	r0, r2";
say OUT "	bl	symtable_set_fun";
say OUT "	mov	r0, r1";
say OUT "	mov r1, #32";
say OUT "	bl	symtable_set_name";
say OUT "	pop {lr}";
say OUT "	bx  lr";
say OUT "";

say OUT "init_symbols:";
say OUT "	push	{lr}";

for my $sym ( keys %symbols ) {
	(my $SYM = $sym) =~ tr/a-z/A-Z/;
	say OUT "	ldr	r1, .L$SYM"."_ID";
	say OUT "	ldr	r2, .L$SYM"."_OP";
	say	OUT "	bl	init_sym";
	say OUT "	bl	symtable_next";
}

say OUT "	bl	symtable_set_null";
say OUT "	bl	symtable_restart";
say OUT "	pop	{lr}";
say OUT "	bx	lr";
say OUT "";

say OUT "	.align	2";

for my $sym ( keys %symbols ) {
	(my $SYM = $sym) =~ tr/a-z/A-Z/;
	say OUT ".L$SYM"."_ID:";
	say OUT "	.word	.LC$SYM";
	say OUT ".L$SYM"."_OP:";
	say OUT "	.word	$sym";
}
