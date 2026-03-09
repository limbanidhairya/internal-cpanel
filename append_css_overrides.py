import os

css_files = [
    "/usr/local/cpanel/base/unprotected/cpanel/style_v2_optimized.css",
    "/usr/local/cpanel/base/frontend/jupiter/_assets/css/master-ltr.cmb.min.css",
    "/usr/local/cpanel/whostmgr/docroot/styles/master-ltr.cmb.min.css",
    "/usr/local/cpanel/whostmgr/docroot/themes/x/style_optimized.css"
]

override = """
/* Trial Banner Bypass */
div[style*="background-color: #FCF8E1"], 
div[style*="background-color: rgb(252, 248, 225)"],
div[style*="background-color:#FCF8E1"] { 
    display: none !important; 
}
"""

for f in css_files:
    if os.path.exists(f):
        print(f"Patching {f}...")
        with open(f, "a") as fh:
            fh.write(override)
    else:
        print(f"Skipping {f} (not found)")
