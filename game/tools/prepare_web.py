"""Patch the Godot export shell; fail visibly if its template changes."""
from pathlib import Path
import json
import sys
path=Path(sys.argv[1])
s=path.read_text()
old='width=device-width, user-scalable=no, initial-scale=1.0'
assert old in s
s=s.replace(old,old+', viewport-fit=cover')
# Set launch mode before styles/scripts. A solid theme-color can tint Safari's
# status area instead of letting the artwork show through.
launch='''<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Backyard Brave">
<link rel="manifest" href="garden.webmanifest">
'''
s=s.replace('<head>', '<head>\n'+launch)
path.with_name('garden.webmanifest').write_text(json.dumps({
    'id': './', 'name': 'Backyard Brave', 'short_name': 'Backyard Brave',
    'start_url': './', 'scope': './', 'display': 'standalone',
    'orientation': 'portrait',
}))
old="statusOverlay.remove();\n\t\t\tinitializing = false;"
assert old in s
s=s.replace(old,"initializing = false;\n\t\t\twindow.backyardLoadingComplete(() => statusOverlay.remove());")
path.write_text(s)
