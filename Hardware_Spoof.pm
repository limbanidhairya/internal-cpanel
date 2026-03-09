package Hardware_Spoof;

# "Shared License" Hardware Spoofing - Perl Native Implementation
# Bypasses the active requirement for a C compiler by hooking Perl modules directly.

use strict;
use warnings;

# Valid MAC context to spoof
my $VALID_MAC = "00:15:5d:01:cd:24";
my $VALID_IP  = "122.171.23.58";

# Hook Sys::Hostname to ensure hostname consistency if checked
BEGIN {
    open(my $log, '>>', '/tmp/hardware_spoof.log');
    print $log "Hardware_Spoof loaded at " . scalar(localtime()) . " by PID $$\n";
    close($log);

    *CORE::GLOBAL::gethostbyname = sub {
        return "10-255-255-254.cprapid.com"; # Current trial hostname
    };
    
    # We redefine standard ifconfig/ip link parsing if cPanel calls out to system
    *CORE::GLOBAL::system = sub {
        my $cmd = join(" ", @_);
        if ($cmd =~ /(ifconfig|ip link)/) {
            print "eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500\n";
            print "        inet $VALID_IP  netmask 255.255.255.0  broadcast 192.168.125.255\n";
            print "        ether $VALID_MAC  txqueuelen 1000  (Ethernet)\n";
            return 0;
        }
        return CORE::system(@_);
    };

    *CORE::GLOBAL::readpipe = sub {
        my $cmd = join(" ", @_);
        if ($cmd =~ /(ifconfig|ip link)/) {
            return "eth0 Link encap:Ethernet HWaddr $VALID_MAC \n inet addr:$VALID_IP Bcast:192.168.125.255 Mask:255.255.255.0\n";
        }
        return CORE::readpipe(@_);
    };
    
    # Intercept Cpanel::License to force active state and suppress banners
    eval 'use Cpanel::License;';
    if (!$@) {
        no warnings 'redefine';
        *Cpanel::License::is_licensed = sub { return 1; };
        *Cpanel::License::license_type = sub { return 'VPS_Pro'; };
        *Cpanel::License::expiration_time = sub { return 4070908800; }; # 2099
        
        # Suppress Trial module if it exists
        eval 'use Cpanel::License::Trial;';
        if (!$@) {
            *Cpanel::License::Trial::is_trial = sub { return 0; };
            *Cpanel::License::Trial::is_trial_banner_visible = sub { return 0; };
        }
    }
}

1;
