#!/usr/bin/perl -w
use strict;
use Config::IniFiles;
use File::Basename;
use Term::ANSIColor qw(:constants);
use Expect;

# Expect instance
my $exp = new Expect;
#$exp->exp_internal(1);
$exp->raw_pty(0);
$exp->log_stdout(0);
$exp->spawn("qemu-arm", "./uforth") or die "Cannot spawn: $!\n";

# Get the ini file parsed to a hash of hashes
tie my %ini, 'Config::IniFiles', ( -file => @ARGV );

for my $sect ( sort keys %ini ) {
    my $name    = $ini{$sect}{"name"};
    my $input   = $ini{$sect}{"input"};
    my $output  = $ini{$sect}{"output"};
    my $notest  = $ini{$sect}{"notest"};

    printf '%-18s', defined $name ? "$sect: ($name) " : "$sect:";
    if(defined $notest) {
        print "NOTEST: $notest\n";
        next;
    }

    $exp->send("$input\n");
    if(defined $exp->expect(1, -re, "^$output\\s*\$")) {
        print "PASSED\n";
    } else {
        print BOLD, RED, "FAILED\n";
        print RESET, "";

        # Re-spawn the process, as it should be in bad shape.
        # TODO: Move this to a sub to clean up this a bit.
        $exp->send("BYE\n");
        $exp->soft_close();

        $exp = new Expect();
        $exp->spawn("qemu-arm", "./uforth") or die "Cannot spawn: $!\n";
        $exp->raw_pty(0);
        $exp->log_stdout(0);
    }
}

$exp->send("BYE\n");
$exp->soft_close();

