#!/bin/bash

read_dnf() {
    local file="$1"
    local search_key="$2"

    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        return 2
    fi

    while IFS='=' read -r key value; do
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        if [[ "$key" == "$search_key" ]]; then
            echo "$value"
            return 0
        fi
    done < "$file"

    return 1
}

# 使用示例
file="config.dnf"
key="app.settings.theme"

if result=$(read_dnf "$file" "$key"); then
    echo "Value for $key: $result"
else
    echo "Key not found: $key"
fi