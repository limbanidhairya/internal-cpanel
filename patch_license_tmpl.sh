#!/bin/bash
echo "<script>window.location.href='/cpsess' + window.location.pathname.split('/cpsess')[1].split('/')[0] + '/scripts/command';</script>" > /usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl
echo "Done"
