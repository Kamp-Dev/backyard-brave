"""Patch the Godot export shell; fail visibly if its template changes."""
from pathlib import Path
import sys
path=Path(sys.argv[1])
s=path.read_text()
old='width=device-width, user-scalable=no, initial-scale=1.0'
assert old in s
s=s.replace(old,old+', viewport-fit=cover')
s=s.replace('</head>','<meta name="apple-mobile-web-app-capable" content="yes">\n<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">\n<meta name="theme-color" content="#c2d187">\n</head>')
old="statusOverlay.remove();\n\t\t\tinitializing = false;"
assert old in s
s=s.replace(old,"initializing = false;\n\t\t\twindow.backyardLoadingComplete(() => statusOverlay.remove());")
path.write_text(s)
