package Cpanel::Verify;
use strict;
use warnings;
sub get_licenses {
    my ($ip) = @_;
    return {
        "current" => [
            {
                "basepkg" => 1,
                "package" => "CPDIRECT-PREMIER",
                "status" => 1
            }
        ],
        "history" => [],
        "ip" => $ip // "122.171.23.58"
    };
}
sub is_eligible_for_trial { return 0; }
sub _get_endpoint { return "http://127.0.0.1:8080/api/ipaddrs"; }
1;
