# fetcher.py v0.1.0-4

import json
import requests
import time
import random
import string
from pathlib import Path
from typing import Any, List, Optional
from fake_useragent import UserAgent

# CONFIG
OUP = "inputs"
URL = "https://api.kurobbs.com/wiki/core/catalogue/item/getPage"
PAYLOADS: List[dict[str, Any]] = [
    {"catalogueId": 1105, "page": 1, "limit": 1000},
    {"catalogueId": 1106, "page": 1, "limit": 1000},
    {"catalogueId": 1107, "page": 1, "limit": 1000},
    {"catalogueId": 1219, "page": 1, "limit": 1000},
]

# INIT
UA = UserAgent()
BASE = Path(__file__).parent


def gen_code(length: int = 32) -> str:
    return "".join(
        random.choice(string.ascii_letters + string.digits) for _ in range(length)
    )


def save(data: Any, cid: Any) -> None:
    dp = BASE / OUP
    dp.mkdir(parents=True, exist_ok=True)
    ts = int(time.time())
    fp = dp / f"{cid}_{ts}.json"
    fp.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), "utf-8")
    print(f">> Saved: {fp.name}")


def fetch(payload: dict[str, Any]) -> Optional[dict[str, Any]]:
    headers = {
        "Accept": "*/*",
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": UA.random,
        "devcode": gen_code(),
        "source": "h5",
        "wiki_type": "9",
    }
    try:
        cid = payload.get("catalogueId")
        print(f">> Fetching [ID: {cid}]...")
        res = requests.post(URL, headers=headers, data=payload, timeout=10)
        res.raise_for_status()
        return res.json()
    except Exception as e:
        print(f"!! Error {payload.get('catalogueId')}: {e}")
        return None


def main():
    try:
        total = len(PAYLOADS)
        for i, payload in enumerate(PAYLOADS):
            res = fetch(payload)
            if res:
                save(res, payload.get("catalogueId"))

            if i < total - 1:
                wait = random.uniform(1, 3)
                print(f".. Cooldown {wait:.2f}s")
                time.sleep(wait)
        print(">> All tasks completed.")
    except KeyboardInterrupt:
        print("\n!! Aborted.")
        exit(0)


if __name__ == "__main__":
    main()
