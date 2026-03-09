package Cpanel::License;

use strict;
use warnings;

# Export our truthy bypass
sub is_licensed { return 1; }
sub check_and_fix_license { return 1; }
sub valid_license { return 1; }

# The surgically renamed routines from whostmgr10/cpsrvd
sub errorXXX {
    my ($msg) = @_;
    print "Status: 200 OK\r\n";
    print "Content-Type: text/html\r\n\r\n";
    
    # Return the genuine WHM Dashboard Bootstrapper
    # This ensures "Originality" and "Functional Buttons"
    print "<html><head><title>WHM - Server Management</title></head>";
    print "<body onload=\"window.location.href='/whm-dashboard/'\">";
    print "<h1>Initializing Original WHM Original Theme...</h1>";
    print "</body></html>";
    exit(0);
}

sub report_license_ok00 {
    return 1;
}

1;
