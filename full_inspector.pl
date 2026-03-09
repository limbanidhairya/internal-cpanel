#!/usr/local/cpanel/3rdparty/bin/perl
use strict;
use warnings;
use lib '/usr/local/cpanel';
use Cpanel::License;
use Cpanel::License::State;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deepcopy = 1;

print "--- COMPREHENSIVE LICENSE DUMP ---\n";

my %results;

sub dump_package {
    my $pkg = shift;
    print "Inspecting $pkg...\n";
    no strict 'refs';
    foreach my $sym (keys %{"${pkg}::"}) {
        # Scalars
        if (defined ${"${pkg}::$sym"}) {
             $results{$pkg . "::SCALAR_$sym"} = ${"${pkg}::$sym"};
        }
        # Hashes
        if (%{"${pkg}::$sym"}) {
             $results{$pkg . "::HASH_$sym"} = { %{"${pkg}::$sym"} };
        }
    }
}

my @packages = qw(Cpanel::License Cpanel::License::State Cpanel::License::Trial Cpanel::License::Features);
foreach my $p (@packages) {
    eval "use $p;";
    dump_package($p);
}

# Try to get active license object
eval {
    my $lic = Cpanel::License->new();
    $results{'OBJECT_DUMP'} = { %$lic } if $lic;
};

print Dumper(\%results);

open(my $fh, '>', '/mnt/c/Users/Dhairya Limbani/OneDrive/Documents/dcpanel/decoded_license.txt') or die $!;
print $fh Dumper(\%results);
close($fh);

print "--- DUMP COMPLETE ---\n";
