"""Check preview packaging; --production deliberately blocks unconfigured release."""
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / "cosmetic_catalog.json").read_text(encoding="utf-8"))
config = json.loads((root / "commerce_config.json").read_text(encoding="utf-8"))
errors = []
ids = {p["id"] for p in catalog["products"]}
if len(ids) != 5:
    errors.append("Expected five unique non-consumable products")
for entry in catalog["skins"]:
    if not (root / entry["atlas"].removeprefix("res://")).exists():
        errors.append("Missing outfit: " + entry["id"])
    if entry["product"] and entry["product"] not in ids:
        errors.append("Unknown product: " + entry["id"])
    if entry["earned_mastery"] and entry["product"]:
        errors.append("Earned mastery outfit must not be sold")
if len(catalog["skins"]) != 10:
    errors.append("Expected two original, six paid and two earned outfits")
for page in ("privacy.html", "support.html"):
    text = (root / "launch" / page).read_text(encoding="utf-8")
    if "Xevajius" not in text or "xevapps@gmail.com" not in text:
        errors.append("Missing developer contact in " + page)
if "--production" in sys.argv:
    if not config["enabled"]:
        errors.append("Real checkout is disabled pending certification")
    if not config["verification_url"].startswith("https://") or not config["public_key_pem"]:
        errors.append("HTTPS verifier and public verification key not provisioned")
    # Certification evidence is deliberately external; do not turn this into a
    # self-approving checklist by setting booleans merely to make CI green.
    errors.append("Human release review required: Play setup, device/store tests, asset rights, ratings and privacy disclosures; see launch/READINESS.md")
for error in errors:
    print("BLOCKED:", error)
if not errors:
    print("LAUNCH PREVIEW CHECKS PASSED — purchases remain gated")
sys.exit(bool(errors))
