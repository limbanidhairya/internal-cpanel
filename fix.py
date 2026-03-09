content = """<!DOCTYPE html>
<html>
<head>
<title>Bypassing...</title>
<style>
body { background: #f4f6f9; display: flex; justify-content: center; align-items: center; height: 100vh; font-family: sans-serif; color: #333; }
</style>
</head>
<body>
<h2>Development Mode Bypass...</h2>
<script>
setTimeout(function() {
    window.location.href = window.location.pathname.replace(/(\\/cpsess[^\\/]+).*/, "$1/scripts/command");
}, 100);
</script>
</body>
</html>
"""

with open('/usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl', 'w') as f:
    f.write(content)

with open('/usr/local/cpanel/whostmgr/docroot/templates/gsw/initial_setup/license_purchase_intro.tmpl', 'w') as f:
    f.write(content)
