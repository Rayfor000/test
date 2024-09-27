#!/bin/bash

# Function: detect_width
# Description: 判斷輸入字符的字節數並輸出相應的結果。
#              字節數為 1 或 2 時，輸出 1（半形或全形）
#              字節數為 3 時，輸出 2（簡體/繁體中文）
# Usage: ./detect_width.sh

detect_width() {
    local char

    # 提示用戶輸入字符
    read -p "請輸入一個字符: " char

    # 確保有輸入字符
    if [[ -z "$char" ]]; then
        echo "錯誤: 未提供任何字符。"
        return 1
    fi

    # 驗證是否僅輸入了一個字符
    # 使用 grep -o . 來正確處理多字節字符
    local char_length
    char_length=$(echo -n "$char" | grep -o . | wc -l)
    if [[ "$char_length" -ne 1 ]]; then
        echo "錯誤: 請僅提供一個字符。"
        return 1
    fi

    # 獲取字符的字節長度
    local byte_length
    byte_length=$(echo -n "$char" | wc -c)

    case "$byte_length" in
        1|2)
            echo "1"  # 半形或全形
            ;;
        3)
            echo "2"  # 簡體或繁體中文
            ;;
        *)
            echo "不支持的字符字節長度: $byte_length 字節。"
            return 2
            ;;
    esac
}

# 執行函數
detect_width