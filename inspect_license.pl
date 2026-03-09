#!/usr/local/cpanel/3rdparty/bin/perl
use strict;
use warnings;
use lib '/usr/local/cpanel';
use Cpanel::License;

print "Listing Cpanel::License functions:\n";
no strict 'refs';
foreach my $sym (sort keys %{"Cpanel::License::"}) {
    next if $sym =~ /::$/;
    if (defined &{"Cpanel::License::$sym"}) {
        print "  - $sym\n";
    }
}
