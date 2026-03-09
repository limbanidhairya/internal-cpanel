use strict;
use lib '/usr/local/cpanel';
use Cpanel::DIp::LicensedIP;
use Data::Dumper;
eval {
    print "Fetching IP...\n";
    my $ip = Cpanel::DIp::LicensedIP::get_license_ip();
    print "IP detected: $ip\n";
};
if ($@) {
    print "FAILED: $@\n";
}
1;
