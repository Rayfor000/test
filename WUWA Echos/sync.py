# sync.py v0.1.2a1-6

import json
import re
from pathlib import Path
from opencc import OpenCC

# CONFIG
INP = "inputs"
OUP = ""
LOC_NAME = "localization.json"
AST_NAME = "asset.json"
PREFIXES = ["1105", "1106", "1107", "1219"]
LANGS = ["SC", "TC", "EN"]
SKIP_TAG = "699"
CC_TYPE = "s2t"

# LOGIC
BASE = Path(__file__).parent
CC = OpenCC(CC_TYPE)


def load_j(path):
    if path.exists():
        try:
            return json.loads(path.read_text("utf-8"))
        except Exception:
            return {}
    return {}


def save_j(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    sorted_d = dict(sorted(data.items()))
    path.write_text(
        json.dumps(sorted_d, ensure_ascii=False, separators=(",", ":")), "utf-8"
    )


def fid(val):
    s = str(val)
    return s.zfill(5) if len(s) < 5 else s


def update_entry(loc, ast, rid, name, url=None):
    key = fid(rid)
    if key not in loc:
        loc[key] = dict.fromkeys(LANGS, "")

    node = loc[key]
    if "SC" in node and not node["SC"] and name:
        node["SC"] = name
    if "TC" in node and not node["TC"] and name:
        node["TC"] = CC.convert(name)

    if url:
        ast[key] = url
    elif key not in ast:
        ast[key] = ""


def parse_tree(node, loc, ast):
    if not node:
        return
    kids = node.get("children", [])
    if not kids:
        tid = node.get("id") or node.get("key")
        name = node.get("name")
        if tid is not None and name:
            update_entry(loc, ast, tid, name)
    else:
        for k in kids:
            parse_tree(k, loc, ast)


def get_targets(src):
    found = {p: [] for p in PREFIXES}
    for f in src.glob("*.json"):
        m = re.match(r"^(\d{4})_(\d{10})\.json$", f.name)
        if m and m.group(1) in PREFIXES:
            found[m.group(1)].append((int(m.group(2)), f))
    return {p: sorted(f, reverse=True)[0][1] for p, f in found.items() if f}


def process_records(pre, path, loc, ast):
    raw = json.loads(path.read_text("utf-8")).get("data", {})
    recs = raw.get("results", {}).get("records", [])
    total = len(recs)
    print(f">> Syncing {pre}: {total} records")

    for idx, item in enumerate(recs, 1):
        rid = item.get("id")
        if rid is None:
            continue

        tags = [str(t) for t in item.get("content", {}).get("relateTagIds", [])]
        if pre == "1107" and SKIP_TAG in tags:
            continue

        print(f"\r   [{idx}/{total}] Last: {fid(rid)}", end="", flush=True)
        update_entry(
            loc, ast, rid, item.get("name"), item.get("content", {}).get("contentUrl")
        )

    print(f"\n   Processing tag tree for {pre}...")
    parse_tree(raw.get("tagTree"), loc, ast)


def patch_missing(loc, ast):
    print(">> Patching missing assets...")
    mapping = {v["SC"]: ast[k] for k, v in loc.items() if v.get("SC") and ast.get(k)}
    for k, url in ast.items():
        if not url:
            name = loc.get(k, {}).get("SC")
            if name in mapping:
                ast[k] = mapping[name]


def main():
    try:
        # 1. Environment Init
        src = BASE / INP
        out = BASE / OUP
        out.mkdir(parents=True, exist_ok=True)

        if not src.exists():
            print(f"!! Source directory {INP} missing.")
            return

        # 2. Resource Acquisition
        loc = load_j(out / LOC_NAME)
        ast = load_j(out / AST_NAME)
        targets = get_targets(src)

        # 3. Flow Orchestration
        for pre, path in targets.items():
            process_records(pre, path, loc, ast)

        patch_missing(loc, ast)

        # 4. Save & Exit
        save_j(out / LOC_NAME, loc)
        save_j(out / AST_NAME, ast)
        print(f">> Done. Results in {OUP}/")

    except Exception as e:
        print(f"!! Error: {e}")
        exit(1)


if __name__ == "__main__":
    main()
