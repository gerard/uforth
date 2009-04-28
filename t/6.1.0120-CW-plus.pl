#!/usr/bin/perl -w
use strict;
use Expect;

my $exp = new Expect;

$exp->raw_pty(0);
$exp->log_stdout(0);
$exp->spawn("qemu-arm", "./uforth") or die "Cannot spawn: $!\n";

$exp->send("2 2 +\n");
$exp->send("5 12 +\n");
$exp->send("  1234   123443    +  \n");
$exp->send(".s\n");
defined $exp->expect(2, "4 17 124677") ? print "PASSED\n" : print "FAILED\n";

$exp->send("BYE\n");
$exp->soft_close();
