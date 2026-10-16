"""Inspect a built AAB. Static evidence only, never a Families certification."""
import hashlib, json, struct, sys, zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
bundle, manifest, config = map(Path, sys.argv[1:4])
android = "{http://schemas.android.com/apk/res/android}"
root = ET.parse(manifest).getroot()
permissions = sorted(e.attrib[android+"name"] for e in root.findall("uses-permission"))
allowed = {"android.permission.INTERNET", "android.permission.VIBRATE", "android.permission.ACCESS_NETWORK_STATE", "com.android.vending.BILLING"}
errors = []
# AndroidX uses an app-specific signature permission to protect receivers on
# older Android versions. Only allow our exact name with signature protection.
receiver_permission = root.attrib.get("package", "") + ".DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
for declaration in root.findall("permission"):
    if declaration.attrib.get(android+"name") == receiver_permission and declaration.attrib.get(android+"protectionLevel") in ("signature", "0x00000002", "2"):
        allowed.add(receiver_permission)
if set(permissions)-allowed: errors.append("Unexpected permissions: " + str(set(permissions)-allowed))
if not {"android.permission.INTERNET", "com.android.vending.BILLING"} <= set(permissions): errors.append("Required verifier/billing permission absent")
sdk = root.find("uses-sdk")
target = int(sdk.attrib.get(android+"targetSdkVersion", "0"))
if target < 36: errors.append("Target SDK below 36")
app = root.find("application")
if app.attrib.get(android+"debuggable", "false") != "false": errors.append("Debuggable release")
if app.attrib.get(android+"allowBackup", "true") != "false": errors.append("Backup allowed: local data/receipt disclosure must be reviewed")
if app.attrib.get(android+"usesCleartextTraffic", "false") != "false": errors.append("Cleartext traffic enabled")
if not any(e.attrib.get(android+"name", "").endswith("GodotGooglePlayBilling") for e in app.findall("meta-data")): errors.append("Billing plugin metadata missing")
libs = []
with zipfile.ZipFile(bundle) as z:
    for name in z.namelist():
        if not name.endswith(".so"): continue
        data = z.read(name)
        if data[:4] != b"\x7fELF" or data[4:6] != bytes([2,1]):
            errors.append("Unexpected native format: " + name); continue
        phoff = struct.unpack_from("<Q", data, 32)[0]
        entsize, count = struct.unpack_from("<HH", data, 54)
        alignments = []
        for i in range(count):
            offset = phoff + i*entsize
            if struct.unpack_from("<I", data, offset)[0] == 1:
                alignments.append(struct.unpack_from("<Q", data, offset+48)[0])
        if not alignments or min(alignments)<16384: errors.append("Native LOAD alignment below 16KB: " + name)
        libs.append({"path":name,"load_alignments":alignments})
    config_text = config.read_text()
    if "PAGE_ALIGNMENT_16K" not in config_text: errors.append("AAB does not request 16KB ZIP alignment")
    dex = b"".join(z.read(n) for n in z.namelist() if n.endswith(".dex"))
    # Inventory indicators, not a proof of runtime behavior or all dependencies.
    indicators = {x: x.encode() in dex for x in ["AdvertisingIdClient", "firebase/analytics", "appsflyer", "facebook/ads", "GodotGooglePlayBilling"]}
    for x, found in indicators.items():
        if found and x != "GodotGooglePlayBilling": errors.append("Review SDK indicator: " + x)
result={"sha256":hashlib.sha256(bundle.read_bytes()).hexdigest(),"package":root.attrib.get("package"),"target_sdk":target,"permissions":permissions,"application_flags":{k.removeprefix(android):v for k,v in app.attrib.items()},"native_libraries":libs,"sdk_indicators":indicators,"errors":errors,"scope":"Static unsigned release-bundle audit. No runtime, supervised purchase, vendor-contract or legal certification."}
print(json.dumps(result,indent=2))
sys.exit(bool(errors))
