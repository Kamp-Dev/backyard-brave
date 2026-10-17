"""Google Play non-consumable verifier. No card data or game account required.

Production must sit behind HTTPS and an ingress rate limit. Purchase tokens are
bearer secrets: never enable request-body/access-URL logging for this service.
"""
from contextlib import closing
import base64
import hashlib
import json
import os
import sqlite3
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

PACKAGE = "com.xevapps.backyardbrave"
PRODUCTS = {PACKAGE + "." + name for name in
            ("raincoat", "acorn", "moonflower", "strawberry", "supporter")}
MAX_RECEIPTS = len(PRODUCTS)
LEASE_SECONDS = 90 * 24 * 3600


class VerificationUnavailable(Exception):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward authorization credentials or purchase URLs elsewhere.
        return None


HTTP = urllib.request.build_opener(NoRedirect)


def b64(value):
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode()


class PlayAPI:
    def __init__(self, credentials_file):
        self.credentials = json.loads(Path(credentials_file).read_text())
        self.key = serialization.load_pem_private_key(
            self.credentials["private_key"].encode(), password=None)
        self.token = ""
        self.expiry = 0
        self.lock = threading.Lock()

    def access_token(self):
        with self.lock:
            if time.time() < self.expiry - 60:
                return self.token
            now = int(time.time())
            header = b64(b'{"alg":"RS256","typ":"JWT"}')
            claims = b64(json.dumps({"iss": self.credentials["client_email"],
                "scope": "https://www.googleapis.com/auth/androidpublisher",
                "aud": "https://oauth2.googleapis.com/token", "iat": now,
                "exp": now + 3600}).encode())
            message = (header + "." + claims).encode()
            signature = self.key.sign(message, padding.PKCS1v15(), hashes.SHA256())
            assertion = message.decode() + "." + b64(signature)
            body = urllib.parse.urlencode({"grant_type":
                "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion}).encode()
            try:
                with HTTP.open(urllib.request.Request(
                    "https://oauth2.googleapis.com/token", body), timeout=8) as response:
                    data = json.load(response)
                self.token = data["access_token"]
                self.expiry = time.time() + int(data["expires_in"])
            except Exception:
                raise VerificationUnavailable("Google authorization unavailable") from None
            return self.token

    def call(self, product, token, acknowledge=False):
        quote = lambda value: urllib.parse.quote(value, safe="")
        url = ("https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
               + PACKAGE + "/purchases/products/" + quote(product) + "/tokens/" + quote(token))
        if acknowledge:
            url += ":acknowledge"
        req = urllib.request.Request(url, data=b"{}" if acknowledge else None,
            headers={"Authorization": "Bearer " + self.access_token(),
                     "Content-Type": "application/json"})
        try:
            with HTTP.open(req, timeout=8) as response:
                body = response.read()
                return json.loads(body) if body else {}
        except Exception:
            # Never include the URL/token or vendor response in logs/errors.
            raise VerificationUnavailable("Google purchase check unavailable") from None


class Verifier:
    def __init__(self, play, signing_key, database, allow_test=False):
        self.play, self.signing_key, self.database = play, signing_key, database
        self.allow_test = allow_test
        with closing(sqlite3.connect(database)) as db:
            db.execute("CREATE TABLE IF NOT EXISTS purchases (token_hash TEXT PRIMARY KEY, "
                       "product TEXT NOT NULL, state INTEGER NOT NULL, checked INTEGER NOT NULL)")

    def verify(self, receipts):
        if not isinstance(receipts, list) or len(receipts) > MAX_RECEIPTS:
            raise ValueError("Invalid receipt list")
        normalized = {}
        seen_products = set()
        for row in receipts:
            if not isinstance(row, dict) or set(row) != {"product_id", "token"} or row.get("product_id") not in PRODUCTS:
                raise ValueError("Unknown product")
            token = row.get("token")
            if not isinstance(token, str) or not 1 <= len(token) <= 4096:
                raise ValueError("Invalid receipt")
            if token in normalized and normalized[token] != row["product_id"]:
                raise ValueError("Receipt reused for different products")
            if row["product_id"] in seen_products and token not in normalized:
                raise ValueError("Multiple tokens for one product")
            normalized[token] = row["product_id"]
            seen_products.add(row["product_id"])
        with closing(sqlite3.connect(self.database)) as db:
            db.execute("DELETE FROM purchases WHERE checked < ?", (int(time.time()) - LEASE_SECONDS,))
            db.commit()
        active = set()
        for token, product in normalized.items():
            result = self.play.call(product, token)
            # The API endpoint binds this result to our fixed package and product.
            state = result.get("purchaseState")
            if type(state) is not int or state not in (0, 1, 2):
                raise VerificationUnavailable("Unrecognized purchase state")
            if result.get("consumptionState", 0) != 0:
                raise VerificationUnavailable("Unexpected consumed non-consumable")
            if result.get("purchaseType") == 0 and not self.allow_test:
                raise ValueError("Sandbox receipt on production verifier")
            digest = hashlib.sha256(token.encode()).hexdigest()
            with closing(sqlite3.connect(self.database)) as db:
                db.execute("INSERT INTO purchases VALUES (?,?,?,?) ON CONFLICT(token_hash) "
                           "DO UPDATE SET state=excluded.state,checked=excluded.checked",
                           (digest, product, state, int(time.time())))
                db.commit()
            if state == 0:
                # Durable idempotent ledger first, then acknowledgement. Retried
                # requests recheck Google and cannot multiply a cosmetic grant.
                if result.get("acknowledgementState") != 1:
                    self.play.call(product, token, acknowledge=True)
                active.add(product)
        now = int(time.time())
        payload = json.dumps({"package": PACKAGE, "products": sorted(active),
                              "issued_at": now, "expires_at": now + LEASE_SECONDS},
                             separators=(",", ":"), sort_keys=True)
        signature = self.signing_key.sign(payload.encode(), padding.PKCS1v15(), hashes.SHA256())
        return {"payload": payload, "signature": base64.b64encode(signature).decode()}


def application_for(verifier):
    def application(environ, start_response):
        status, result = "200 OK", {}
        try:
            if environ.get("PATH_INFO") == "/health" and environ.get("REQUEST_METHOD") == "GET":
                result = {"status": "ok"}
            elif environ.get("PATH_INFO") != "/verify" or environ.get("REQUEST_METHOD") != "POST":
                status, result = "404 Not Found", {"error": "Not found"}
            else:
                length = int(environ.get("CONTENT_LENGTH", "0"))
                if not 1 <= length <= 65536:
                    raise ValueError("Invalid request size")
                data = json.loads(environ["wsgi.input"].read(length))
                if not isinstance(data, dict) or set(data) != {"receipts"}:
                    raise ValueError("Invalid request")
                result = verifier.verify(data.get("receipts"))
        except (ValueError, TypeError):
            status, result = "400 Bad Request", {"error": "Invalid purchase request"}
        except Exception:
            status, result = "503 Service Unavailable", {"error": "Please try Restore again later"}
        body = json.dumps(result).encode()
        start_response(status, [("Content-Type", "application/json"),
            ("Cache-Control", "no-store"), ("Content-Length", str(len(body)))])
        return [body]
    return application


def create_app():
    # Missing credentials/signing key must fail deployment, never enable fake billing.
    key = serialization.load_pem_private_key(
        Path(os.environ["ENTITLEMENT_SIGNING_KEY_FILE"]).read_bytes(), password=None)
    play = PlayAPI(os.environ["GOOGLE_APPLICATION_CREDENTIALS"])
    return application_for(Verifier(play, key, os.environ["PURCHASE_DATABASE"],
                          allow_test=os.environ.get("ALLOW_TEST_PURCHASES") == "true"))
