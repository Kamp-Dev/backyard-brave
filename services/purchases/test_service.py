import io
import json
import tempfile
import unittest
import hashlib
import sqlite3
from contextlib import closing
from maintenance import prune, delete_hash
from service import LEASE_SECONDS, NoRedirect
from pathlib import Path
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from service import Verifier, PACKAGE, application_for, VerificationUnavailable


class FakePlay:
    def __init__(self):
        self.state = 0
        self.calls = []
        self.failed = False
    def call(self, product, token, acknowledge=False):
        if self.failed:
            raise VerificationUnavailable()
        self.calls.append(acknowledge)
        return {"purchaseState": self.state, "acknowledgementState": 1 if self.calls.count(True) else 0}


class Purchases(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(dir=Path(__file__).parent)
        self.key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        self.play = FakePlay()
        self.verifier = Verifier(self.play, self.key, str(Path(self.tmp.name)/"ledger.db"))
        self.receipts = [{"product_id": PACKAGE+".raincoat", "token": "fixture-token"}]
    def tearDown(self):
        self.tmp.cleanup()
    def claims(self):
        import base64
        envelope = self.verifier.verify(self.receipts)
        self.key.public_key().verify(base64.b64decode(envelope["signature"]),
            envelope["payload"].encode(), padding.PKCS1v15(), hashes.SHA256())
        return json.loads(envelope["payload"])
    def test_purchase_restore_duplicate(self):
        self.assertEqual(len(self.claims()["products"]), 1)
        self.receipts *= 2
        self.assertEqual(len(self.claims()["products"]), 1)
        self.assertEqual(self.play.calls.count(True), 1)
    def test_pending_and_refund(self):
        self.play.state = 2
        self.assertEqual(self.claims()["products"], [])
        self.assertNotIn(True, self.play.calls)
        self.play.state = 0
        self.assertEqual(len(self.claims()["products"]), 1)
        self.play.state = 1
        self.assertEqual(self.claims()["products"], [])
    def test_invalid_product_and_replay(self):
        self.receipts.append({"product_id": PACKAGE+".acorn", "token": "fixture-token"})
        with self.assertRaises(ValueError): self.claims()
        self.receipts = [{"product_id": "fake.power", "token": "x"}]
        with self.assertRaises(ValueError): self.claims()
        self.assertEqual(self.play.calls, [])
    def test_outage_fails_closed(self):
        self.play.failed = True
        with self.assertRaises(VerificationUnavailable): self.claims()
    def test_no_raw_token_and_retention(self):
        self.claims()
        path=self.verifier.database
        self.assertNotIn(b"fixture-token", Path(path).read_bytes())
        with closing(sqlite3.connect(path)) as db:
            db.execute("UPDATE purchases SET checked=1")
            db.commit()
        self.assertEqual(prune(path, LEASE_SECONDS+2), 1)
        self.assertEqual(prune(path, LEASE_SECONDS+2), 0)

    def test_verified_deletion(self):
        self.claims()
        with self.assertRaises(ValueError): delete_hash(self.verifier.database, "fixture-token")
        digest=hashlib.sha256(b"fixture-token").hexdigest()
        self.assertEqual(delete_hash(self.verifier.database, digest), 1)
        self.assertEqual(delete_hash(self.verifier.database, digest), 0)

    def test_extra_personal_fields_rejected(self):
        self.receipts[0]["child_name"]="unneeded"
        with self.assertRaises(ValueError): self.claims()
        self.assertEqual(self.play.calls, [])

    def test_no_redirect(self):
        self.assertIsNone(NoRedirect().redirect_request(None,None,302,"",{},"https://other.example"))

    def test_ack_failure_does_not_grant(self):
        original=self.play.call
        def fail_ack(product, token, acknowledge=False):
            if acknowledge: raise VerificationUnavailable()
            return original(product,token,acknowledge)
        self.play.call=fail_ack
        with self.assertRaises(VerificationUnavailable): self.claims()

    def test_http_rejects_oversized_request(self):
        statuses = []
        response = application_for(self.verifier)({"PATH_INFO":"/verify",
            "REQUEST_METHOD":"POST", "CONTENT_LENGTH":"999999", "wsgi.input":io.BytesIO(b"")},
            lambda status,headers: statuses.append(status))
        self.assertEqual(statuses, ["400 Bad Request"])
        self.assertNotIn(b"fixture-token", b"".join(response))


if __name__ == "__main__":
    unittest.main()
