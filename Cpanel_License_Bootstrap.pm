package Cpanel::License;
use strict;
use warnings;

# Basic stub to allow services to start and request real license
sub new { return bless {}, shift; }
sub is_licensed { return 0; }
sub check_and_fix_license { return 1; }
sub valid_license { return 0; }
sub license_type { return 'Unknown'; }
sub expiration_time { return time() - 3600; }

1;
