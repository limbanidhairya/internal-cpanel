package Cpanel::License;

use strict;
use warnings;
use Cpanel::Xicense;

# Proxy everything to Xicense
sub is_licensed { return Cpanel::Xicense::is_licensed(@_); }
sub zt_licensed { return Cpanel::Xicense::zt_licensed(@_); }
sub is_licensed_for_product { return Cpanel::Xicense::is_licensed_for_product(@_); }
sub get_license_ip { return Cpanel::Xicense::get_license_ip(@_); }
sub _parse_license_contents_ { return Cpanel::Xicense::_parse_license_contents_(@_); }

sub AUTOLOAD {
    return 1;
}

1;
