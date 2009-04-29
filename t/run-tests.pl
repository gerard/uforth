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

    printf '%-18s', "$sect: ($name) ";
    $exp->send("$input\n");
    defined $exp->expect(1, "$output") ? print "PASSED" : print BOLD, RED, "FAILED";
    print RESET, "\n";
}

$exp->send("BYE\n");
$exp->soft_close();

