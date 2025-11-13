# Phase B: 配置檔案修改計劃

## 目標

將 Cortex Protocol v3.0 的核心改進整合到當前配置檔案中。

## 修改策略

### cortex.md 修改重點

1. **添加三層語言政策** (Section 0.2 之後)

    - LP-1: 對話語言 (用戶語言)
    - LP-2: 專業術語 (英文)
    - LP-3: 編碼產物 (英文，零容忍)

2. **添加信心水平系統** (Section 3.4 之後)

    - 5 級信心標記 (VERIFIED/CONFIDENT/PROBABLE/UNCERTAIN/ASSUMPTION)
    - 強制要求所有宣稱都必須標記信心水平

3. **增強 State Reporting Protocol** (修改 Section 3.4)
    - 添加 TURN 計數器
    - 添加 LANG 聲明
    - 添加一致性檢查狀態

### custom_modes.yaml 修改重點

針對所有編輯模式 (code, debug, code-simplifier, test-engineer) 添加：

1. **LP-3 強制規則**：所有代碼/註釋/commit 必須英文
2. **信心水平要求**：技術建議需標記信心水平
3. **工具預驗證**：使用 write_to_file/apply_diff 前需內部驗證

## 實施順序

1. ✅ Phase A: 完成 CORTEX_PROTOCOL_V3.0.md (1,500+ 行)
2. ⏳ Phase B: 修改 cortex.md + custom_modes.yaml
3. ⏳ Phase C: 創建快速實施指南

## 當前狀態

Phase B 開始執行...
