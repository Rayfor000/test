# bundle.py v1.0.0a1-1

import json
import base64
from pathlib import Path
from typing import Dict, Any

# CONFIG
BASE = Path(__file__).parent
DATA_DIR = BASE / "data"
IMG_DIR = BASE / "img"
OUT_DIR = BASE / "dist"
LANGS = ["TC", "SC", "EN"]


def load_json(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text("utf-8"))
    except Exception:
        return {}


def img_to_base64(path: Path) -> str:
    if not path.exists():
        return ""
    try:
        ext = path.suffix.lower().replace(".", "")
        if ext == "jpg":
            ext = "jpeg"
        data = path.read_bytes()
        b64 = base64.b64encode(data).decode()
        return f"data:image/{ext};base64,{b64}"
    except Exception:
        return ""


def bundle_language(lang: str):
    print(f">> Bundling {lang}...")

    lang_dir = DATA_DIR / lang
    if not lang_dir.exists():
        print(f"!! Language dir not found: {lang_dir}")
        return

    # Load all data files
    resonators = load_json(lang_dir / "resonators.json")
    weapons = load_json(lang_dir / "weapons.json")
    echoes = load_json(lang_dir / "echoes.json")

    # Embed images into resonators
    for rid, data in resonators.items():
        if data.get("Icon"):
            img_path = IMG_DIR / Path(data["Icon"]).name
            if img_path.exists():
                data["Icon"] = img_to_base64(img_path)
        if data.get("AttributeIcon"):
            img_path = IMG_DIR / Path(data["AttributeIcon"]).name
            if img_path.exists():
                data["AttributeIcon"] = img_to_base64(img_path)
        if data.get("WeaponTypeIcon"):
            img_path = IMG_DIR / Path(data["WeaponTypeIcon"]).name
            if img_path.exists():
                data["WeaponTypeIcon"] = img_to_base64(img_path)
        if data.get("RarityIcon"):
            img_path = IMG_DIR / Path(data["RarityIcon"]).name
            if img_path.exists():
                data["RarityIcon"] = img_to_base64(img_path)

    # Embed images into weapons
    for wid, data in weapons.items():
        if data.get("Icon"):
            img_path = IMG_DIR / Path(data["Icon"]).name
            if img_path.exists():
                data["Icon"] = img_to_base64(img_path)
        if data.get("RarityIcon"):
            img_path = IMG_DIR / Path(data["RarityIcon"]).name
            if img_path.exists():
                data["RarityIcon"] = img_to_base64(img_path)

    # Embed images into echoes
    for eid, data in echoes.items():
        if data.get("Icon"):
            img_path = IMG_DIR / Path(data["Icon"]).name
            if img_path.exists():
                data["Icon"] = img_to_base64(img_path)
        if data.get("SonataGroup"):
            for sonata in data["SonataGroup"]:
                if sonata.get("Icon"):
                    img_path = IMG_DIR / Path(sonata["Icon"]).name
                    if img_path.exists():
                        sonata["Icon"] = img_to_base64(img_path)

    # Create bundled output
    bundle = {"resonators": resonators, "weapons": weapons, "echoes": echoes}

    # Save bundled file
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUT_DIR / f"bundle_{lang}.json"
    out_path.write_text(
        json.dumps(bundle, ensure_ascii=False, separators=(",", ":")), "utf-8"
    )
    print(f"   Saved: {out_path} ({out_path.stat().st_size / 1024 / 1024:.2f} MB)")


def main():
    try:
        for lang in LANGS:
            bundle_language(lang)
        print(">> Bundling complete!")
    except Exception as e:
        print(f"!! Error: {e}")
        exit(1)


if __name__ == "__main__":
    main()
