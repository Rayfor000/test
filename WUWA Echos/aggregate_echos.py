import json
import os
import glob


def update_echo_entry(echo_db, echo_data, current_set_info):
    """
    輔助函式：更新單個聲骸在資料庫中的條目
    處理初始化、新增關聯套裝以及圖標更新邏輯
    """
    name = echo_data["name"]
    if name not in echo_db:
        echo_db[name] = {
            "name": name,
            "cost": echo_data["cost"],
            "icon": echo_data["icon"],
            "sets": [current_set_info],
        }
    else:
        entry = echo_db[name]
        existing_set_names = {s["name"] for s in entry["sets"]}
        if current_set_info["name"] not in existing_set_names:
            entry["sets"].append(current_set_info)
        if not entry["icon"] and echo_data["icon"]:
            entry["icon"] = echo_data["icon"]


def process_single_file(file_path, echo_db):
    """
    輔助函式：讀取並處理單個 JSON 檔案
    """
    if "echos" in file_path:
        return
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if "set_name" not in data or "echos" not in data:
            return
        current_set_info = {"name": data["set_name"], "icon": data.get("set_icon", "")}
        for echo in data["echos"]:
            update_echo_entry(echo_db, echo, current_set_info)
    except (json.JSONDecodeError, OSError) as e:
        print(f"警告：處理檔案 {file_path} 時發生錯誤: {e}")


def save_master_list(echo_db, output_filename="echos_list.json"):
    """
    輔助函式：排序並保存最終結果
    """
    master_list = []
    sorted_echos = sorted(echo_db.values(), key=lambda x: (-x["cost"], x["name"]))
    for index, echo_data in enumerate(sorted_echos, start=1):
        master_list.append(
            {
                "id": index,
                "name": echo_data["name"],
                "cost": echo_data["cost"],
                "icon": echo_data["icon"],
                "related_sets": echo_data["related_sets"]
                if "related_sets" in echo_data
                else echo_data["sets"],
            }
        )
    with open(output_filename, "w", encoding="utf-8") as f:
        json.dump(master_list, f, ensure_ascii=False, indent=4)
    return len(master_list)


def aggregate_echos(json_folder="."):
    """
    主函式：聚合指定目錄下的聲骸 JSON 數據
    """
    search_pattern = os.path.join(json_folder, "*.json")
    json_files = glob.glob(search_pattern)
    if not json_files:
        print(f"在目錄 '{json_folder}' 中未找到 JSON 檔案。")
        return
    echo_db = {}
    print(f"找到 {len(json_files)} 個 JSON 檔案，開始處理...")
    for file_path in json_files:
        process_single_file(file_path, echo_db)
    count = save_master_list(echo_db)
    print(f"聚合完成！共處理 {count} 個唯一聲骸。已保存至 echos_list.json")


if __name__ == "__main__":
    potential_files = [f for f in glob.glob("*.json") if "echos" not in f]
    if potential_files:
        aggregate_echos(".")
    else:
        print("提示：當前目錄下未發現任何有效的套裝 JSON 檔案。")
        print("請先執行解析腳本生成資料。")
