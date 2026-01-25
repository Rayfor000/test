import os
import json
import re
import email
import uuid
import base64
import requests
from bs4 import BeautifulSoup

INPUT_DIR = "input"
OUTPUT_DIR = "data"
LOCALE_FILE = "localization.json"
ASSETS_FILE = "assets.json"
LANGUAGES = ["en", "zh-Hans", "zh-Hant"]
VALID_EXTENSIONS = (".html", ".htm", ".mhtml", ".mht")
IMG_BASE_URL = "https://prod-alicdn-community.kurobbs.com/forum/"
# IMAGE_MODE: "URL" (Direct Link), "LOCAL" (Download), "BASE64" (Embedded)
IMAGE_MODE = "URL"
LOCAL_IMG_DIR = "img"
# INCREMENTAL_MODE: 開啟增量模式
INCREMENTAL_MODE = True


def load_json(filepath):
    if not os.path.exists(filepath):
        print(f"Warning: {filepath} not found.")
        return {}
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(data, folder, filename):
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, filename)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Saved: {path}")


def extract_hash_from_url(img_src):
    if not img_src:
        return None
    match = re.search(r"[-_]([a-fA-F0-9]{8})\.", img_src)
    return match.group(1) if match else None


def get_localized_text(category, key_id, lang, locale_data, fallback_text=None):
    try:
        return locale_data[category][key_id][lang]
    except KeyError:
        return fallback_text


def get_asset_url(category, key_id, assets_data, fallback_url=None):
    try:
        return assets_data[category][key_id]
    except KeyError:
        return fallback_url


def get_image_url_priority(img_tag):
    if not img_tag:
        return ""
    url = img_tag.get("data-src")
    if url:
        return url
    return img_tag.get("src") or ""


def _download_image_to_local(remote_url, filename):
    """輔助函數：下載圖片到本地"""
    full_img_dir = os.path.join(OUTPUT_DIR, LOCAL_IMG_DIR)
    os.makedirs(full_img_dir, exist_ok=True)
    local_path = os.path.join(full_img_dir, filename)
    if INCREMENTAL_MODE and os.path.exists(local_path):
        return f"{LOCAL_IMG_DIR}/{filename}"
    try:
        print(f"Downloading: {filename}")
        resp = requests.get(remote_url, timeout=10)
        if resp.status_code == 200:
            with open(local_path, "wb") as f:
                f.write(resp.content)
            return f"{LOCAL_IMG_DIR}/{filename}"
    except Exception as e:
        print(f"Download failed for {filename}: {e}")
    return remote_url


def _convert_image_to_base64(remote_url, filename):
    """輔助函數：轉換圖片為 Base64"""
    try:
        print(f"Encoding Base64: {filename}")
        resp = requests.get(remote_url, timeout=10)
        if resp.status_code == 200:
            b64_data = base64.b64encode(resp.content).decode("utf-8")
            mime_type = (
                "image/png" if filename.lower().endswith(".png") else "image/jpeg"
            )
            return f"data:{mime_type};base64,{b64_data}"
    except Exception as e:
        print(f"Base64 failed for {filename}: {e}")
    return remote_url


def process_final_image_url(local_url):
    """處理圖片 URL：分發到不同的處理模式"""
    if not local_url:
        return ""
    filename = os.path.basename(local_url)
    if "?" in filename:
        filename = filename.split("?")[0]
    remote_url = f"{IMG_BASE_URL}{filename}"
    if IMAGE_MODE == "LOCAL":
        return _download_image_to_local(remote_url, filename)
    elif IMAGE_MODE == "BASE64":
        return _convert_image_to_base64(remote_url, filename)
    return remote_url


def _get_or_create_id(storage_map, key):
    if key not in storage_map:
        storage_map[key] = str(uuid.uuid4())
    return storage_map[key]


def extract_id_from_url_string(url_string):
    if not url_string:
        return None
    match = re.search(r"item\/(\d+)", url_string)
    return match.group(1) if match else None


def extract_id_from_page_meta(html_content):
    comment_match = re.search(r"saved from url=.*?\/item\/(\d+)", html_content)
    if comment_match:
        return comment_match.group(1)
    try:
        soup = BeautifulSoup(html_content, "html.parser")
        meta_url = soup.find("meta", property="og:url")
        if meta_url:
            res = extract_id_from_url_string(meta_url.get("content", ""))
            if res:
                return res
        link_canon = soup.find("link", rel="canonical")
        if link_canon:
            res = extract_id_from_url_string(link_canon.get("href", ""))
            if res:
                return res
    except Exception:
        pass
    return None


def _read_html_content(filepath):
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()
    except Exception as e:
        print(f"Error reading HTML {filepath}: {e}")
        return None


def _read_mhtml_content(filepath):
    try:
        with open(filepath, "rb") as f:
            msg = email.message_from_binary_file(f)
            for part in msg.walk():
                if part.get_content_type() == "text/html":
                    payload = part.get_payload(decode=True)
                    if isinstance(payload, bytes):
                        charset = part.get_content_charset() or "utf-8"
                        return payload.decode(charset, errors="ignore")
    except Exception as e:
        print(f"Error parsing MHTML {filepath}: {e}")
    return None


def read_file_content(filepath):
    filename = os.path.basename(filepath)
    ext = os.path.splitext(filename)[1].lower()
    if ext in (".html", ".htm"):
        return _read_html_content(filepath)
    elif ext in (".mhtml", ".mht"):
        return _read_mhtml_content(filepath)
    return None


def _get_resonator_rarity(entry):
    star_class = entry.select_one(".card-inner")
    if not star_class:
        return 0
    classes = star_class.get("class")
    if classes and isinstance(classes, list):
        for c in classes:
            if c.startswith("card-star-"):
                try:
                    return int(c.split("-")[-1])
                except ValueError:
                    pass
    return 0


def _get_resonator_image(entry):
    char_img = entry.select_one(".card-content-inner img")
    raw_url = get_image_url_priority(char_img)
    return process_final_image_url(raw_url)


def parse_resonators(soup, raw_resonators, id_map):
    entries = soup.select(".entry-wrapper")
    for entry in entries:
        link_tag = entry.find("a", class_="common-link-wrapper")
        kuro_id = None
        if link_tag and link_tag.get("href"):
            kuro_id = extract_id_from_url_string(link_tag.get("href"))
        name_tag = entry.select_one(".card-footer-inner span")
        if not name_tag:
            continue
        name = name_tag.get_text(strip=True)
        key = kuro_id if kuro_id else name
        new_uuid = _get_or_create_id(id_map, key)
        attr_img = entry.select_one(".card-skill-attr-icon img")
        attr_src = get_image_url_priority(attr_img)
        attr_id = extract_hash_from_url(attr_src)
        raw_resonators.append(
            {
                "id": new_uuid,
                "kuro_id": kuro_id,
                "name_cn": name,
                "attribute_id": attr_id,
                "rarity": _get_resonator_rarity(entry),
                "image": _get_resonator_image(entry),
            }
        )


def _get_sonata_descriptions(soup):
    desc_2pc = ""
    desc_3pc = ""
    desc_5pc = ""
    rows = soup.select("tr")
    for row in rows:
        cols = row.select("td")
        text = row.get_text(strip=True)
        if len(cols) > 1:
            content = cols[-1].get_text(strip=True)
            if "2件套" in text:
                desc_2pc = content
            elif "3件套" in text:
                desc_3pc = content
            elif "5件套" in text:
                desc_5pc = content
    return desc_2pc, desc_3pc, desc_5pc


def _extract_echo_info(td):
    img_tag = td.select_one("img")
    raw_img_url = get_image_url_priority(img_tag)
    img_url = process_final_image_url(raw_img_url)
    a_tags = td.select("a")
    echo_name = ""
    for a in a_tags:
        txt = a.get_text(strip=True)
        if txt:
            echo_name = txt
            break
    return echo_name, img_url


def _process_echo_component(comp, sonata_kuro_id, raw_echoes, echo_id_map):
    title_div = comp.select_one(".component-title-text")
    if not title_div:
        return
    title_text = title_div.get_text(strip=True)
    cost = 0
    if "COST 4" in title_text:
        cost = 4
    elif "COST 3" in title_text:
        cost = 3
    elif "COST 1" in title_text:
        cost = 1
    if cost == 0:
        return
    tds = comp.select("td")
    for td in tds:
        echo_name, img_url = _extract_echo_info(td)
        if echo_name and img_url:
            new_echo_uuid = _get_or_create_id(echo_id_map, echo_name)
            if echo_name not in raw_echoes:
                raw_echoes[echo_name] = {
                    "id": new_echo_uuid,
                    "name": echo_name,
                    "cost": cost,
                    "image": img_url,
                    "sonata_kuro_ids": [],
                }
            if sonata_kuro_id not in raw_echoes[echo_name]["sonata_kuro_ids"]:
                raw_echoes[echo_name]["sonata_kuro_ids"].append(sonata_kuro_id)


def parse_sonata_detail(
    html_string, soup, raw_sonatas, raw_echoes, sonata_id_map, echo_id_map
):
    sonata_kuro_id = extract_id_from_page_meta(html_content=html_string)
    if not sonata_kuro_id:
        title_tag = soup.select_one(".terminology.JWkEntryTitle") or soup.select_one(
            ".menu-title"
        )
        print(
            f"Skipping: Could not extract ID from metadata for {title_tag.get_text(strip=True) if title_tag else 'Unknown'}"
        )
        return
    new_sonata_uuid = _get_or_create_id(sonata_id_map, sonata_kuro_id)
    if sonata_kuro_id not in raw_sonatas:
        desc_2pc, desc_3pc, desc_5pc = _get_sonata_descriptions(soup)
        raw_sonatas[sonata_kuro_id] = {
            "id": new_sonata_uuid,
            "kuro_id": sonata_kuro_id,
            "desc_2pc": desc_2pc,
            "desc_3pc": desc_3pc,
            "desc_5pc": desc_5pc,
        }
    components = soup.select(".J-component-layout")
    for comp in components:
        _process_echo_component(comp, sonata_kuro_id, raw_echoes, echo_id_map)


def _is_sonata_detail_page(soup):
    tables = soup.select("table")
    for table in tables:
        text = table.get_text()
        if "2件套" in text or "3件套" in text:
            return True
    return False


def _process_single_file(filepath, raw_resonators, raw_sonatas, raw_echoes, id_maps):
    content = read_file_content(filepath)
    if not content:
        return
    soup = BeautifulSoup(content, "html.parser")
    filename = os.path.basename(filepath)
    if "共鸣者" in filename and "合鸣" not in filename:
        parse_resonators(soup, raw_resonators, id_maps["resonator"])
    elif _is_sonata_detail_page(soup):
        parse_sonata_detail(
            content, soup, raw_sonatas, raw_echoes, id_maps["sonata"], id_maps["echo"]
        )


def generate_output(
    lang,
    locale_data,
    assets_data,
    raw_resonators,
    raw_sonatas,
    raw_echoes,
    sonata_id_map,
):
    print(f"Generating output for language: {lang}")
    out_resonators = []
    for res in raw_resonators:
        attr_id = res["attribute_id"]
        attr_name = get_localized_text(
            "attributes", attr_id, lang, locale_data, "Unknown"
        )
        attr_icon = get_asset_url("attributes", attr_id, assets_data, "")
        out_resonators.append(
            {
                "id": res["id"],
                "name": res["name_cn"],
                "rarity": res["rarity"],
                "element": attr_name,
                "element_icon": attr_icon,
                "image": res["image"],
            }
        )
    save_json(out_resonators, os.path.join(OUTPUT_DIR, lang), "resonators.json")
    out_sonatas = []
    for kuro_s_id, s_data in raw_sonatas.items():
        s_name = get_localized_text("sonatas", kuro_s_id, lang, locale_data, "Unknown")
        s_icon = get_asset_url("sonatas", kuro_s_id, assets_data, "")
        out_sonatas.append(
            {
                "id": s_data["id"],
                "name": s_name,
                "icon": s_icon,
                "2pc_description": s_data["desc_2pc"],
                "3pc_description": s_data["desc_3pc"],
                "5pc_description": s_data["desc_5pc"],
            }
        )
    save_json(out_sonatas, os.path.join(OUTPUT_DIR, lang), "sonatas.json")
    out_echoes = []
    for e_name, e_data in raw_echoes.items():
        set_names = []
        new_sonata_uuids = []
        for kuro_sid in e_data["sonata_kuro_ids"]:
            set_name = get_localized_text(
                "sonatas", kuro_sid, lang, locale_data, kuro_sid
            )
            set_names.append(set_name)
            if kuro_sid in sonata_id_map:
                new_sonata_uuids.append(sonata_id_map[kuro_sid])
        out_echoes.append(
            {
                "id": e_data["id"],
                "name": e_name,
                "cost": e_data["cost"],
                "sonata_sets": set_names,
                "sonata_ids": new_sonata_uuids,
                "image": e_data["image"],
            }
        )
    save_json(out_echoes, os.path.join(OUTPUT_DIR, lang), "echoes.json")


def process_files():
    locale_data = load_json(LOCALE_FILE)
    assets_data = load_json(ASSETS_FILE)
    raw_resonators = []
    raw_sonatas = {}
    raw_echoes = {}
    id_maps = {
        "resonator": {},
        "sonata": {},
        "echo": {},
    }
    input_files = [
        f for f in os.listdir(INPUT_DIR) if f.lower().endswith(VALID_EXTENSIONS)
    ]
    for file in input_files:
        print(f"Processing: {file}")
        filepath = os.path.join(INPUT_DIR, file)
        _process_single_file(filepath, raw_resonators, raw_sonatas, raw_echoes, id_maps)
    for lang in LANGUAGES:
        generate_output(
            lang,
            locale_data,
            assets_data,
            raw_resonators,
            raw_sonatas,
            raw_echoes,
            id_maps["sonata"],
        )


if __name__ == "__main__":
    process_files()
