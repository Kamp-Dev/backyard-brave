# Backyard Brave Google Play purchase verification

Not deployed. Checkout remains disabled until provisioning and physical-device tests pass.

Run unit checks with `python -m unittest discover -s . -v`. Production dependencies are in requirements.txt; install into an isolated environment and pin the resolved lockfile after deployment platform selection.

Run with a production WSGI server, for example `gunicorn 'service:create_app()' --bind 0.0.0.0:8080 --workers 2 --timeout 120`. Do not expose the development server directly.

Required environment variables:

- `GOOGLE_APPLICATION_CREDENTIALS`: secret-mounted Google service-account JSON with least-privilege Google Play purchase verification/acknowledgement access.
- `ENTITLEMENT_SIGNING_KEY_FILE`: secret-mounted RSA private key, at least 2048 bits. Embed only its public PEM in the game.
- `PURCHASE_DATABASE`: writable durable SQLite file. Use one host/shared local volume for this deployment model, or migrate the ledger to managed SQL before horizontally scaling.
- `ALLOW_TEST_PURCHASES=true`: sandbox deployment only. Omit for production.

POST `/verify` accepts `{"receipts":[{"product_id":"com.kampdev.backyardbrave.raincoat","token":"STORE_TOKEN"}]}`. Never log that body. GET `/health` returns health without exposing configuration.

The verifier fixes the package and allowlists products. It queries Google for every receipt, grants only completed non-consumed purchases, writes an idempotent hashed ledger, acknowledges, then signs the complete supplied ownership snapshot. A Google error fails the entire response; the client retains its previous verified cache. Cancellation/refund states remove the relevant entitlement on the next successful reconciliation. There is no RTDN push integration yet; offline refund propagation is bounded by the 90-day signed cache lifetime. This is cosmetic-only client enforcement, not tamper-proof DRM.

Deploy behind TLS, request-size limits and per-IP rate limiting at ingress. Do not place a shared API secret in the game. Purchase-token possession supplies the proof, Google verifies it, and responses contain no personal account details. Strip URL/query/body data from upstream error logs. Ledger entries are pruned 90 days after last verification; schedule cleanup when the service is idle if strict wall-clock deletion is required. Configure the hosting provider's IP-log retention before finalizing the privacy policy.

Use separate sandbox/production keys and databases. Test acknowledgement retry, concurrent duplicate requests, expired service credentials, Google 429/5xx, signing key rotation, disk failure and refunds on the actual deployed service. Back up the ledger and monitor aggregate availability/error counts without receipt bodies. No endpoint should return a signed positive entitlement when Google cannot be reached.

Local tests do not establish store approval or production certification. See `game/launch/READINESS.md` for the release gate.

Families audit hardening (2026-10-16): the verifier rejects extra request/receipt fields and multiple tokens for one product, accepts at most five receipt rows, and refuses HTTP redirects. No raw receipt bodies should reach access or error logs.

Operator maintenance (not deployed or scheduled yet):
- Schedule `python maintenance.py /durable/ledger.db prune` at least daily on the same durable volume as the service. Alert if the job fails. Test cleanup on an idle service as well as with traffic.
- After verifying a parent/requester's authority and identifying the relevant record through authorized internal tools, use `delete-verified-hash`; pass the SHA-256 digest on stdin, never a raw token or command-line argument. This is an operator tool, not a public unauthenticated deletion endpoint.
- This removes only the service ledger row. It does not refund/revoke a Google purchase, wipe a device, delete Gmail messages, delete Google-held data or clean infrastructure backups/logs. A later valid restore can create a new minimal verification record. Explain this accurately in parent responses.
- Set and document provider logs, backups and support-mail retention; process those systems separately. Do not solicit a child's identity documents or receipt tokens by email. Do not mark parent access/deletion complete until requester verification, record lookup, and all provider cleanup have been exercised.
- A Families/COPPA review of the actual billing SDK and processing purposes remains necessary. Neither Google checkout nor these technical tests establish parental consent or a lawful exception.
