package License_Extractor;
use strict;
use warnings;
use Data::Dumper;

sub import {
    print "License Extractor Active...\n";
    eval 'use Cpanel::License;';
    if ($@) {
        warn "Could not load Cpanel::License: $@";
        return;
    }

    # Attempt to dump info from various possible sources
    my $info = {};
    eval {
        # Try getting instance if it exists
        my $lic = Cpanel::License->new();
        if ($lic) {
            foreach my $key (keys %$lic) {
                $info->{$key} = $lic->{$key};
            }
        }
    };

    # Direct hash inspection of the package if possible
    no strict 'refs';
    foreach my $sym (keys %{"Cpanel::License::"}) {
        if ($sym =~ /^[A-Z_]+$/) { # Likely constants or config
            $info->{"CONST_$sym"} = ${"Cpanel::License::$sym"};
        }
    }

    print "--- START LICENSE DUMP ---\n";
    print Dumper($info);
    print "--- END LICENSE DUMP ---\n";

    # External file capture
    open(my $fh, '>', '/tmp/raw_license_dump.txt');
    print $fh Dumper($info);
    close($fh);
}

1;
