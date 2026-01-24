import json
from bs4 import BeautifulSoup
import re
import os

ATTR_MAPPING = {
    "qidong": "氣動",
    "rerong": "熱熔",
    "daodian": "導電",
    "jielin": "湮滅",
    "yanshe": "衍射",
    "bingning": "冷凝",
}


def extract_attribute_info(soup_entry):
    """
    從條目中提取屬性名稱和圖標 URL
    (已包含 Pylance 類型修復)
    """
    attr_box = soup_entry.find("div", class_="card-skill-attr-icon")
    if not attr_box:
        return "Unknown", ""
    img = attr_box.find("img")
    if not img or not img.get("src"):
        return "Unknown", ""
    icon_url = img["src"]
    match = re.search(r"attr-([a-z]+)-", icon_url)
    if match:
        attr_code = match.group(1)
        attr_name = ATTR_MAPPING.get(attr_code, "Unknown")
    else:
        attr_name = "Unknown"
    return attr_name, icon_url


def extract_rarity(soup_entry):
    """從 class 中提取星級"""
    card_inner = soup_entry.find("div", class_="card-inner")
    if not card_inner:
        return 0
    classes = card_inner.get("class", [])
    if "card-star-5" in classes:
        return 5
    elif "card-star-4" in classes:
        return 4
    elif "card-star-3" in classes:
        return 3
    return 0


def extract_image_url(soup_entry):
    """提取角色圖片"""
    content_inner = soup_entry.find("div", class_="card-content-inner")
    if not content_inner:
        return ""
    img = content_inner.find("img")
    if not img:
        return ""
    return img.get("data-src") or img.get("src", "")


def process_single_entry(entry):
    """提取單個角色的資料 (不包含 ID)"""
    name_span = entry.find("div", class_="card-footer-inner").find("span")
    name = name_span.get_text(strip=True) if name_span else "Unknown"
    rarity = extract_rarity(entry)
    image_url = extract_image_url(entry)
    attr_name, attr_icon = extract_attribute_info(entry)
    return {
        "name": name,
        "rarity": rarity,
        "attribute": attr_name,
        "attribute_icon": attr_icon,
        "image": image_url,
    }


def parse_resonators(html_file):
    if not os.path.exists(html_file):
        print(f"錯誤：找不到檔案 {html_file}")
        return
    with open(html_file, "r", encoding="utf-8") as f:
        html_content = f.read()
    soup = BeautifulSoup(html_content, "html.parser")
    entries = soup.find_all("div", class_="entry-wrapper")
    resonator_list = []
    print(f"找到 {len(entries)} 個角色條目，開始解析...")
    for index, entry in enumerate(entries, start=1):
        try:
            raw_data = process_single_entry(entry)
            final_data = {
                "id": index,
                "name": raw_data["name"],
                "rarity": raw_data["rarity"],
                "attribute": raw_data["attribute"],
                "attribute_icon": raw_data["attribute_icon"],
                "image": raw_data["image"],
            }
            resonator_list.append(final_data)
        except Exception as e:
            print(f"解析第 {index} 個條目時發生錯誤: {e}")
    output_filename = "resonators_list.json"
    with open(output_filename, "w", encoding="utf-8") as f:
        json.dump(resonator_list, f, ensure_ascii=False, indent=4)
    print(f"解析完成！共 {len(resonator_list)} 位角色。已保存至 {output_filename}")


if __name__ == "__main__":
    parse_resonators("resonators.html")
