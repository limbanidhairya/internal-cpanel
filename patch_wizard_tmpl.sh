#!/bin/bash
TARGET="/usr/local/cpanel/whostmgr/docroot/templates/gsw/initial_setup/license_purchase_intro.tmpl"
echo "<script>window.location.href='/cpsess' + window.location.pathname.split('/cpsess')[1].split('/')[0] + '/scripts/command';</script>" > "$TARGET"
echo "Done"
