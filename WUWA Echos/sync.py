# sync.py v0.1.2a1-14

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
BASE_LANG = "SC"
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


def merge_master_node(base, target, source_loc, source_url):
    if source_url:
        if target["url"] and target["url"] != source_url:
            raise ValueError(
                f"Conflict [URL]: '{base}' -> '{target['url']}' vs '{source_url}'"
            )
        target["url"] = source_url

    for lang in LANGS:
        val = source_loc.get(lang, "")
        if not val:
            continue
        if target["loc"][lang] and target["loc"][lang] != val:
            raise ValueError(
                f"Conflict [{lang}]: '{base}' -> '{target['loc'][lang]}' vs '{val}'"
            )
        target["loc"][lang] = val


def build_master_map(loc, ast):
    m_map = {}
    for k, v in loc.items():
        base_val = v.get(BASE_LANG)
        if not base_val:
            continue
        if base_val not in m_map:
            m_map[base_val] = {"loc": dict.fromkeys(LANGS, ""), "url": ""}
        merge_master_node(base_val, m_map[base_val], v, ast.get(k, ""))
    return m_map


def fill_entry(entry_loc, master_loc):
    for lang in LANGS:
        if not entry_loc[lang] and master_loc[lang]:
            entry_loc[lang] = master_loc[lang]


def propagate_master(loc, ast, m_map):
    for k in ast:
        base_val = loc.get(k, {}).get(BASE_LANG)
        if base_val not in m_map:
            continue
        master = m_map[base_val]
        if not ast[k]:
            ast[k] = master["url"]
        if k not in loc:
            loc[k] = master["loc"].copy()
        else:
            fill_entry(loc[k], master["loc"])


def ingest_data(pre, path, loc, ast):
    raw = json.loads(path.read_text("utf-8")).get("data", {})
    recs = raw.get("results", {}).get("records", [])
    print(f">> Syncing {pre}: {len(recs)} records")
    for item in recs:
        rid = item.get("id")
        if rid is None:
            continue
        tags = [str(t) for t in item.get("content", {}).get("relateTagIds", [])]
        if pre == "1107" and (SKIP_TAG in tags or SKIP_TAG.zfill(5) in tags):
            continue
        update_entry(
            loc, ast, rid, item.get("name"), item.get("content", {}).get("contentUrl")
        )
    parse_tree(raw.get("tagTree"), loc, ast)


def main():
    try:
        src, out = BASE / INP, BASE / OUP
        out.mkdir(parents=True, exist_ok=True)
        if not src.exists():
            return

        loc, ast = load_j(out / LOC_NAME), load_j(out / AST_NAME)
        targets = get_targets(src)

        for pre, path in targets.items():
            ingest_data(pre, path, loc, ast)

        print(">> Validating data integrity...")
        m_map = build_master_map(loc, ast)
        propagate_master(loc, ast, m_map)

        save_j(out / LOC_NAME, loc)
        save_j(out / AST_NAME, ast)
        print(f">> Done. Results in {OUP}/")

    except Exception as e:
        print(f"!! Error (Atomic Abort): {e}")
        exit(1)


if __name__ == "__main__":
    main()
