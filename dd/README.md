# DD重裝腳本

這是一個用於在Linux系統上進行網絡重裝的腳本。

## 功能

- 支持Debian/Ubuntu/CentOS等主流Linux發行版
- 自動檢測並配置網絡
- 可自定義鏡像源
- 支持自定義分區
- 可選擇是否保留數據

## 使用方法

1. 下載腳本:
   ```
   wget https://raw.githubusercontent.com/your-repo/dd.sh
   ```

2. 賦予執行權限:
   ```
   chmod +x dd.sh
   ```

3. 運行腳本:
   ```
   ./dd.sh
   ```

4. 根據提示進行操作

## 注意事項

- 腳本需要root權限運行
- 重裝過程中會格式化硬盤,請注意數據備份
- 默認root密碼為:password,請及時修改
- 如果重裝失敗,可查看/var/log/reinstall.log排查問題

## 參數說明

- -d/--debian: 指定安裝Debian系統
- -u/--ubuntu: 指定安裝Ubuntu系統  
- -c/--centos: 指定安裝CentOS系統
- --ip-addr: 指定IP地址
- --ip-gate: 指定網關
- --ip-mask: 指定子網掩碼

更多參數說明請使用 ./dd.sh -h 查看

## 貢獻

歡迎提交問題和改進建議!

## 授權

本項目採用 GPL-3.0 授權協議。
