#!/bin/bash

# CpConfGuard Bypass (Fixes UID 0/0 lock issue)
sed -i 's/$self->{use_lock} = !!$self->{use_lock};/$self->{use_lock} = 0;/g' /usr/local/cpanel/Cpanel/Config/CpConfGuard.pm

# Whostmgr Wizard Bypass (Fixes Initial Setup Wizard)
sed -i 's/has_accepted_legal_agreements => Whostmgr::Setup::EULA::is_accepted(),/has_accepted_legal_agreements => 1,/g' /usr/local/cpanel/Cpanel/Template/Plugin/Whostmgr.pm
sed -i 's/has_completed_initial_setup   => Whostmgr::Setup::Completed::is_complete(),/has_completed_initial_setup   => 1,/g' /usr/local/cpanel/Cpanel/Template/Plugin/Whostmgr.pm

# Tweaksetting Bypass (Fixes API errors for license logic)
sed -i 's/if ( !_get_tweaksetting( $args->{module}, $args->{key}, \$value ) ) {/if ( 0 ) {/g' /usr/local/cpanel/Whostmgr/API/1/Cpanel.pm

echo "Patches applied successfully."
