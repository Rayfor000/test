import json
from bs4 import BeautifulSoup
import re
import os


def get_set_name(soup):
    """
    提取並清理套裝名稱
    解決 S5857: 使用否定字元類 [^）]* 替換非貪婪匹配
    """
    title_tag = soup.find("h1", class_="terminology")
    raw_title = title_tag.get_text(strip=True) if title_tag else "Unknown_Set"
    set_name = re.sub(r"（[^）]*）", "", raw_title)
    return set_name


def get_set_icon(soup):
    """提取套裝圖標 URL"""
    basic_info_component = soup.find("div", class_="basic-component")
    if basic_info_component:
        img_tag = basic_info_component.find("img")
        if img_tag and img_tag.get("src"):
            return img_tag["src"]
    return ""


def extract_echo_from_cell(cell, cost_level):
    """從表格單元格中提取單個聲骸資訊"""
    texts = list(cell.stripped_strings)
    echo_name = texts[-1] if texts else "Unknown"
    icon_img = cell.find("img")
    echo_icon = icon_img["src"] if icon_img else ""
    return {"name": echo_name, "cost": cost_level, "icon": echo_icon}


def process_component_echos(comp):
    """
    處理單個 HTML 組件塊，若包含 COST 資訊則返回聲骸列表
    """
    echos = []
    title_div = comp.find("span", class_="component-title-text")
    if not title_div:
        return echos
    title_text = title_div.get_text(strip=True)
    cost_match = re.search(r"COST\s*(\d+)", title_text)
    if not cost_match:
        return echos
    cost_level = int(cost_match.group(1))
    content_div = comp.find("div", class_="component-content-inner")
    if content_div:
        cells = content_div.find_all("td")
        for cell in cells:
            echos.append(extract_echo_from_cell(cell, cost_level))
    return echos


def parse_html_to_json(html_file):
    """
    主解析函式
    解決 S3776: 邏輯已拆分至輔助函式，大幅降低複雜度
    """
    with open(html_file, "r", encoding="utf-8") as f:
        html_content = f.read()
    soup = BeautifulSoup(html_content, "html.parser")
    set_name = get_set_name(soup)
    set_icon_url = get_set_icon(soup)
    echos_list = []
    components = soup.find_all("div", class_="J-component-layout")
    for comp in components:
        found_echos = process_component_echos(comp)
        echos_list.extend(found_echos)
    result_data = {"set_name": set_name, "set_icon": set_icon_url, "echos": echos_list}
    output_filename = f"{set_name}.json"
    with open(output_filename, "w", encoding="utf-8") as f:
        json.dump(result_data, f, ensure_ascii=False, indent=4)
    print(f"成功生成文件: {output_filename}")
    return result_data


if __name__ == "__main__":
    if os.path.exists("input.html"):
        parse_html_to_json("input.html")
    else:
        print("錯誤: 未找到 input.html 文件")
