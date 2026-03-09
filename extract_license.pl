#!/usr/local/cpanel/3rdparty/bin/perl
use strict;
use warnings;
use lib '/usr/local/cpanel';
use Cpanel::License;

print "Attempting to extract decoded license key...\n";

my $lic = Cpanel::License->new();
if (!$lic) {
    die "Error: Could not instantiate Cpanel::License object.\n";
}

# The key is often stored in internal attributes after handshake
# We'll try common accessors or direct hash inspection if needed.
my $key = $lic->license_key() || "Unknown/Encoded";
my $type = $lic->license_type() || "Unknown";
my $exp = $lic->expiration_time() || 0;

print "License Type: $type\n";
print "Decoded Key: $key\n";
print "Expires (TS): $exp\n";

open(my $fh, '>', '/mnt/c/Users/Dhairya Limbani/OneDrive/Documents/dcpanel/decoded_license.txt') or die "Can't open file: $!";
print $fh "--- cPanel Decoded License Info ---\n";
print $fh "Type: $type\n";
print $fh "Key: $key\n";
print $fh "Expiration Timestamp: $exp\n";
close($fh);

print "\nSuccess: Decoded info saved to decoded_license.txt\n";
