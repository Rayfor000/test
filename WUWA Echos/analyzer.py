# analyzer.py v0.1.2a1-15

import json
import re
import uuid
import base64
import requests
from pathlib import Path
from typing import List, Dict, Any

# CONFIG
MODE = "LOCAL"
INP = "inputs"
OUP = "outputs"
IMG = "img"
LOC_FILE = "localization.json"
LANGS = ["SC", "TC", "EN"]
TYPES = {"1105": "resonators", "1106": "weapons", "1107": "echoes", "1219": "sonatas"}
SKIP_TAG = "699"
TIMEOUT = 10

# LOGIC
BASE = Path(__file__).parent
CACHE: Dict[str, str] = {}
TAGS: Dict[str, str] = {}
URLS: Dict[str, str] = {}


def fetch(url: str, ukey: str) -> str:
    if MODE == "URL" or not url:
        return url
    if url in CACHE:
        return CACHE[url]

    name = f"{ukey}.png"
    dp = BASE / IMG
    fp = dp / name
    # ? User requested format: img/{uuid}.png
    rel_path = f"{IMG}/{name}"

    if fp.exists():
        CACHE[url] = rel_path
        return rel_path

    try:
        res = requests.get(url, timeout=TIMEOUT)
        if res.status_code != 200:
            return url

        if MODE == "BASE64":
            ext = url.split(".")[-1].split("?")[0] or "png"
            raw = base64.b64encode(res.content).decode()
            CACHE[url] = f"data:image/{ext};base64,{raw}"
        else:
            dp.mkdir(parents=True, exist_ok=True)
            fp.write_bytes(res.content)
            CACHE[url] = rel_path

        return CACHE[url]
    except Exception:
        return url


def get_text(data: Dict[str, Any], rid: Any, lang: str, fallback: str = "") -> str:
    if rid is None:
        return fallback
    # ? localization.json keys are 5-digit padded
    sid = str(rid).zfill(5)
    val = data.get(sid, {}).get(lang, "")
    return val if val else fallback


def parse_tree(node: Dict[str, Any], cat: str = ""):
    if not node:
        return
    kids = node.get("children")
    if not kids:
        # ? Map raw and padded ID for metadata tag lookup
        tid = str(node.get("id") or node.get("key"))
        TAGS[tid] = cat
        TAGS[tid.zfill(5)] = cat
    else:
        name = node.get("name") or cat
        # ? Level 1 nodes are categories
        lvl = str(name) if node.get("level") == 1 else cat
        for k in kids:
            parse_tree(k, lvl)


def map_res(tids: List[str], loc: Dict[str, Any], lang: str) -> Dict[str, Any]:
    styles: List[str] = []
    res = {
        "Attribute": "",
        "WeaponType": "",
        "Rarity": "",
        "Version": "",
        "Styles": styles,
    }
    for t in tids:
        c, v = TAGS.get(t), get_text(loc, t, lang)
        if not v:
            continue
        if c == "属性":
            res["Attribute"] = v
        elif c == "武器":
            res["WeaponType"] = v
        elif c == "稀有度":
            res["Rarity"] = v
        elif c == "实装版本":
            res["Version"] = v
        elif c == "风格定位":
            styles.append(v)
    return res


def map_weap(tids: List[str], loc: Dict[str, Any], lang: str) -> Dict[str, Any]:
    res = {"Type": "", "Rarity": ""}
    for t in tids:
        c, v = TAGS.get(t), get_text(loc, t, lang)
        if not v:
            continue
        if c == "类型":
            res["Type"] = v
        elif c == "武器星级":
            res["Rarity"] = v
    return res


def map_echo(tids: List[str], loc: Dict[str, Any], lang: str) -> Dict[str, Any]:
    sonatas: List[str] = []
    res = {"Class": "", "Cost": "", "SonataGroup": sonatas}
    for t in tids:
        c, v = TAGS.get(t), get_text(loc, t, lang)
        if not v:
            continue
        if c == "级别":
            res["Class"] = v
        elif c == "COST":
            res["Cost"] = v
        elif c == "套装":
            sonatas.append(v)
    return res


def build_item(
    kind: str, rec: Dict[str, Any], loc: Dict[str, Any], lang: str
) -> Dict[str, Any]:
    rid = rec.get("id")
    raw_name = rec.get("name", "")
    tids = [str(t) for t in rec.get("content", {}).get("relateTagIds", [])]
    out = {"Name": get_text(loc, rid, lang, fallback=raw_name)}
    if kind == "1105":
        out.update(map_res(tids, loc, lang))
    elif kind == "1106":
        out.update(map_weap(tids, loc, lang))
    elif kind == "1107":
        out.update(map_echo(tids, loc, lang))
    return out


def get_targets() -> Dict[str, Path]:
    res = {}
    src = BASE / INP
    if not src.exists():
        return {}
    for p in src.glob("*.json"):
        m = re.match(r"^(\d{4})_(\d{10})\.json$", p.name)
        if m and m.group(1) in TYPES:
            v, k = int(m.group(2)), m.group(1)
            if v > res.get(k, (0, None))[0]:
                res[k] = (v, p)
    return {k: v[1] for k, v in res.items()}


def scan_meta(targets: Dict[str, Path]):
    for p in targets.values():
        raw = json.loads(p.read_text("utf-8")).get("data", {})
        parse_tree(raw.get("tagTree", {}))
        for r in raw.get("results", {}).get("records", []):
            u = r.get("content", {}).get("contentUrl")
            name = r.get("name")
            if u and name:
                URLS[str(name)] = u


def process_record(
    tid: str, r: Dict[str, Any], loc: Dict[str, Any], store: Dict[str, Any]
):
    rid = r.get("id")
    if rid is None:
        return None
    fid = str(rid)
    tids = [str(t) for t in r.get("content", {}).get("relateTagIds", [])]
    if tid == "1107" and (SKIP_TAG in tids or SKIP_TAG.zfill(5) in tids):
        return None

    ukey = str(uuid.uuid5(uuid.NAMESPACE_DNS, fid))
    name_key = str(r.get("name") or "")
    url = r.get("content", {}).get("contentUrl") or URLS.get(name_key, "")
    icon = fetch(url, ukey)

    for lang in LANGS:
        item = build_item(tid, r, loc, lang)
        item["Icon"] = icon
        store[lang][TYPES[tid]][ukey] = item
    return fid


def main():
    try:
        targets = get_targets()
        if not targets:
            return
        out_dir = BASE / OUP
        lp = BASE / LOC_FILE  # ? Localization is usually at root
        if not lp.exists():
            lp = out_dir / LOC_FILE
        loc_data = json.loads(lp.read_text("utf-8")) if lp.exists() else {}

        scan_meta(targets)
        store: Dict[str, Dict[str, Dict[str, Any]]] = {
            lang: {t: {} for t in TYPES.values()} for lang in LANGS
        }

        for tid, path in targets.items():
            cat = TYPES[tid]
            recs = (
                json.loads(path.read_text("utf-8"))
                .get("data", {})
                .get("results", {})
                .get("records", [])
            )
            total = len(recs)
            for i, r in enumerate(recs, 1):
                fid = process_record(tid, r, loc_data, store)
                if fid:
                    print(f"\r>> {cat}: [{i}/{total}] {fid}", end="", flush=True)
            print()

        for lang in LANGS:
            ld = out_dir / lang
            ld.mkdir(parents=True, exist_ok=True)
            for cat, data in store[lang].items():
                (ld / f"{cat}.json").write_text(
                    json.dumps(data, ensure_ascii=False, separators=(",", ":")), "utf-8"
                )
    except Exception as e:
        print(f"\n!! {e}")
        exit(1)


if __name__ == "__main__":
    main()
