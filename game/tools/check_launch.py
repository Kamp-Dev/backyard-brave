"""Check preview packaging; --production deliberately blocks unconfigured release."""
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / "cosmetic_catalog.json").read_text(encoding="utf-8"))
config = json.loads((root / "commerce_config.json").read_text(encoding="utf-8"))
errors = []
expected_package = "com.xevapps.backyardbrave"
if config.get("package") != expected_package:
    errors.append("Unexpected commerce package identity")
if any(not p["id"].startswith(expected_package + ".") for p in catalog["products"]):
    errors.append("Product IDs do not match the Google Play package namespace")
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
    audience = json.loads((root / "launch" / "audience-review.json").read_text(encoding="utf-8"))
    if audience["includes_children_under_13"]:
        for item in ("families_review_status", "purchase_data_review_status", "sdk_binary_review_status", "parent_notice_and_deletion_status", "content_age_suitability_status"):
            if audience.get(item) != "reviewed":
                errors.append("Children/families release evidence pending: " + item)
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
    print("LAUNCH PREVIEW CHECKS PASSED - purchases remain gated")
sys.exit(bool(errors))
