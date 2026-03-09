#!/usr/local/cpanel/3rdparty/bin/perl
use strict;
use warnings;
use lib '/usr/local/cpanel';
use Cpanel::License;
use Data::Dumper;

$Data::Dumper::Maxdepth = 2;

print "--- STARTING GLOBAL MEMORY SCAN ---\n";

my $search_term = "cprapid.com";
my %found_vars;

sub scan_pkg {
    my $pkg = shift;
    no strict 'refs';
    foreach my $sym (keys %{"${pkg}::"}) {
        my $full_name = "${pkg}::$sym";
        
        # Check Scalars
        if (defined ${$full_name} && ${$full_name} =~ /$search_term/) {
            $found_vars{$full_name} = ${$full_name};
        }
        
        # Sub-packages
        if ($sym =~ /::$/) {
            # Recursion
            scan_pkg("${pkg}::$sym");
        }
    }
}

# Scan core license packages
foreach my $main_pkg (qw(Cpanel::License Cpanel::License::State Cpanel::License::Trial Whostmgr)) {
    eval "use $main_pkg;";
    scan_pkg($main_pkg);
}

print Dumper(\%found_vars);

# Save results
open(my $fh, '>', '/mnt/c/Users/Dhairya Limbani/OneDrive/Documents/dcpanel/decoded_license.txt') or die $!;
print $fh "--- Decoded Memory Scan ---\n";
print $fh Dumper(\%found_vars);
close($fh);

print "--- SCAN COMPLETE ---\n";
