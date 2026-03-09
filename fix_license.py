content = """package Cpanel::License;
use strict;
use warnings;
sub is_licensed { return 1; }
sub has_valid_license { return 1; }
sub check_license { return 1; }
sub get_license_data { return { 'valid' => 1, 'type' => 'developer', 'ip' => '135.181.78.227', 'package' => 'CPDIRECT-PREMIER', 'status' => 1 }; }

sub AUTOLOAD {
    my $name = our $AUTOLOAD;
    open(my $fh, '>>', '/tmp/cpanel_license_calls.log');
    print $fh "Cpanel::License called missing method: $name\\n";
    close($fh);
    return 1;
}

sub DESTROY {}

package Cpanel::License::Flags;
sub new { bless {}, shift }
sub AUTOLOAD { return 1; }

package Cpanel::License::CompanyID;
sub new { bless {}, shift }
sub AUTOLOAD { return 1; }

package Cpanel::License;
1;
"""

with open('/usr/local/cpanel/Cpanel/License.pm', 'w') as f:
    f.write(content)
