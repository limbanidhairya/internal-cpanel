#!/usr/local/cpanel/3rdparty/bin/perl
use strict;
use warnings;
use lib '/usr/local/cpanel';
use Cpanel::License;
use Data::Dumper;

print "--- START LICENSE EXTRACTION ---\n";

my $lic_obj = {};
eval {
    # Attempt to instantiate or get the singleton
    my $lic = Cpanel::License->new();
    if ($lic) {
        $lic_obj->{'data'} = { %$lic };
        $lic_obj->{'key'} = $lic->license_key() if $lic->can('license_key');
        $lic_obj->{'type'} = $lic->license_type() if $lic->can('license_type');
    }
};

# Inspect the package globals directly
no strict 'refs';
foreach my $sym (keys %{"Cpanel::License::"}) {
    if ($sym =~ /^[A-Z_]+$/) {
        $lic_obj->{"GLOBAL_$sym"} = ${"Cpanel::License::$sym"};
    }
}

print Dumper($lic_obj);

# Save to file
open(my $fh, '>', '/mnt/c/Users/Dhairya Limbani/OneDrive/Documents/dcpanel/decoded_license.txt') or die $!;
print $fh "--- cPanel Decoded License Info ---\n";
print $fh Dumper($lic_obj);
close($fh);

print "--- EXTRACTION COMPLETE ---\n";
