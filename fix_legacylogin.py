#!/usr/bin/env python3
"""Fix LegacyLogin.pm to revert the bypass changes in error503"""
f = '/usr/local/cpanel/Cpanel/LegacyLogin.pm'
with open(f, 'r') as fh:
    c = fh.read()
c = c.replace('Bypassing License...', '503 Service Unavailable')
c = c.replace("<script>alert('Bypass 200 OK');</script>", '<p>The system is currently unavailable.</p>')
c = c.replace('HTTP/1.0 200 OK', 'HTTP/1.0 503 Service Unavailable')
c = c.replace('<title>200 OK</title>', '<title>503 Service Unavailable</title>')
with open(f, 'w') as fh:
    fh.write(c)
print('LegacyLogin.pm reverted successfully')
