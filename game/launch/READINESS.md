# Backyard Brave — launch review

Prepared October 16, 2026 for **Xevajius**. Support: **xevapps@gmail.com**.

**Status: implementation and browser preview ready for review; NOT ready for a public store release.**
Google Play is the first target. Apple enrollment and an iOS build are separate work.

## Implemented

- Four individual cosmetic outfits: Raincoat Scout, Acorn Trail Scout, Moonflower Poppy, Strawberry Poppy.
- Garden Friends Pack: Honeybee Scout, Honey Blossom Poppy, Honey Garden camp background and supporter portrait trim.
- Two earned Garden Guardian outfits, one for each character's five mastery titles. These are not sold.
- Wardrobe previews, per-character equipment preferences, safe fallback after refunds, restore entry point, disabled checkout on browser/development builds.
- Existing character poses and common animation rig retained. No new combat stats, skills, XP, Acorn benefits or character-unlock shortcuts.
- Poppy remains a Stage 15 clear reward; buying an outfit never unlocks her.
- Official GodotGooglePlayBilling 3.3.0 plugin vendored with its MIT license. Adapter uses its 9.1.0 billing dependency and permanent `buy` purchase options.
- Localized store prices only; draft USD prices never appear as actionable store prices.
- Server verification against the Google Play Developer API, acknowledgement after durable ledger write, signed ownership responses, 90-day offline ownership cache, restore/refund reconciliation on launch/resume.
- Failed verification preserves previously verified ownership. Invalid signatures, wrong package, unknown products and expired claims are rejected.
- Privacy/support pages, product configuration CSV and listing copy prepared. No ads, subscription or analytics SDK introduced.
- Separate Google Play Candidate AAB preset prepared. Existing APK/signing identity preserved; no new APK or AAB produced in this task.

## Must finish before enabling purchases

1. In the existing Play Console account, confirm account verification, merchant/payments setup, package availability and production access. Do not change the account to an organization simply for launch.
2. Create the app and five non-consumable products from `products.csv`. Each must have a permanent purchase option with ID `buy`; do not configure rentals or promotional offers for this integration. Draft prices are $2.99 per individual outfit and $8.99 for the pack; confirm regional prices in Console.
3. Deploy `services/purchases` behind HTTPS with ingress rate limiting, durable storage, request-body logging disabled, secret-managed service-account credentials and a separate RSA entitlement-signing key. Configure Google Play API access. Do not put either private key in the app or repository.
4. Set the verifier URL and PUBLIC entitlement key in `commerce_config.json`; keep `enabled=false` until sandbox certification passes. Use a sandbox verifier accepting license-test purchases, then a production verifier rejecting them.
5. Build the AAB candidate with Gradle and the established signing identity; preserve package `com.kampdev.backyardbrave`. Verify current target-SDK and 16-KB page-size compatibility with the actual exported bundle. Upload to internal testing, not production.
6. On a physical Android device, certify success, canceled purchase, pending/approved payment, network interruption, app kill during payment, duplicate callback, reinstall/restore, refunded purchase, Play-account change, verifier outage, and locked Poppy. Include a purchase cancellation initiated outside the app. Verify no double charge and no gameplay-save changes.
7. Verify outage recovery and receipt persistence with real Google responses. Local tests use deterministic fixtures, not real-money transactions. Native integration has not yet been exercised on-device.

## Game quality and release blockers

- Run sustained device sessions on the Galaxy Z Flip7 and a lower-end Android phone: heat, battery, memory, crashes, boss phases, touch controls and interruption/resume. Existing desktop checks cannot replace this.
- Verify all advertised stages, progression rewards and difficulty on release hardware. Five polished opening stages do not establish launch quality for the entire 30-stage campaign.
- The game still saves progression locally. Purchase restore is not cloud-save restore. The local backup button is not an off-device backup; decide whether that limitation is acceptable for launch or implement portable/cloud progression recovery first.
- Art is AI-assisted and based on the game's existing references. Review licenses/provenance for all existing art, fonts, music, sound effects and intro video before commercial publication. New sources are recorded in `assets/cosmetics/PROVENANCE.json`; those records do not certify older asset rights.
- Confirm intended audience, then complete IARC rating, target-audience, ads declaration, app-access and Data Safety forms against the final SDK/backend behavior. Do not declare “no data collected” for a paid build that transmits purchase tokens.
- Review privacy text after choosing the hosting provider and retention/log configuration. Hosting/IP logs and support email processing must match reality.
- Produce final 512px Play icon, 1024x500 feature graphic and screenshots from the release build; current UI captures are QA evidence, not a completed marketing pack.
- Confirm account-specific closed-testing requirements. New personal accounts created after November 13, 2023 may require at least 12 opted-in testers for 14 continuous days and an application for production access.
- Apple Developer membership, macOS/Xcode export/signing, iOS billing adapter, StoreKit verification and TestFlight certification are not implemented by the Android adapter.

## Verification evidence

- `tests/commerce_checks.gd`: forged/wrong-app/expired/altered entitlements; signed grant/refund; free fallback; mastery ownership; no character bypass; every outfit frame/dimensions.
- `services/purchases/test_service.py`: completed/duplicate/restore, pending/refund, invalid product/token reuse, service outage, request-size rejection.
- Actual Godot wardrobe renders and shared-rig contact sheet: `Wardrobe-0.png`, `Wardrobe-1.png`, `Wardrobe-2.png`, `Outfit-Motion-Check.png` in the task outputs.
- Browser and CI validation results must be checked for the specific commit before calling its deployment ready.

## References checked

- https://docs.godotengine.org/en/stable/tutorials/platform/android/android_in_app_purchases.html
- https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0
- https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products
- https://support.google.com/googleplay/android-developer/answer/14151465
- https://support.google.com/googleplay/android-developer/answer/10787469
