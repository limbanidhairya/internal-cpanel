package Cpanel::Xicense;

use strict;
use warnings;

our $AUTOLOAD;

BEGIN {
    $Cpanel::Xicense::LICENSED = 1;
    $Cpanel::Xicense::is_licensed = 1;
    $Cpanel::Xicense::valid_license = 1;
}

sub is_licensed {
    return wantarray ? (1, "Internal Build", {}) : 1;
}

sub zt_licensed { return is_licensed(@_); }
sub zt_port_lic_error { return 1; }
sub zt_ck_fix_license { return 1; }
sub zt_lic_valid { return 1; }

sub is_licensed_for_product { return 1; }
sub zt_licensed_for_product { return 1; }

sub get_license_ip {
    return "135.181.78.227";
}

sub check_local_cache { return 1; }
sub valid_license { return 1; }

sub _parse_license_contents_ {
    return {
        'ip' => '135.181.78.227',
        'company' => 'Internal Server',
        'licenseid' => 'WHM-MOCK-3456',
        'package' => 'premier',
        'valid' => 1,
        'license_version' => 'premier',
        'products' => 'WHM,CPANEL',
    };
}

sub AUTOLOAD {
    my $sub = $AUTOLOAD;
    $sub =~ s/.*:://;
    return 1;
}

1;
