"""Operator-only ledger maintenance. No HTTP admin endpoint or raw receipt input."""
import argparse
from contextlib import closing
import re
import sqlite3
import sys
import time
from service import LEASE_SECONDS


def prune(database, now=None):
    with closing(sqlite3.connect(database)) as db:
        db.execute("PRAGMA secure_delete=ON")
        count=db.execute("DELETE FROM purchases WHERE checked < ?", (int(time.time() if now is None else now)-LEASE_SECONDS,)).rowcount
        db.commit()
    return count


def delete_hash(database, digest):
    if not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise ValueError("Expected a SHA-256 digest, never a raw purchase token")
    with closing(sqlite3.connect(database)) as db:
        db.execute("PRAGMA secure_delete=ON")
        count=db.execute("DELETE FROM purchases WHERE token_hash = ?", (digest,)).rowcount
        db.commit()
    return count


if __name__ == "__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("database")
    parser.add_argument("action", choices=["prune", "delete-verified-hash"])
    args=parser.parse_args()
    # Read a pre-verified subject's digest via stdin, keeping it out of argv/logs.
    if args.action == "prune": count=prune(args.database)
    else: count=delete_hash(args.database, sys.stdin.readline().strip())
    print("Ledger maintenance complete; rows removed:", count)
