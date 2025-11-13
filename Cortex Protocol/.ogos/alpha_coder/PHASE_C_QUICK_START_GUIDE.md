# Cortex Protocol v3.0 - Quick Start Guide

# 快速實施指南

**版本**: v3.0  
**目標受眾**: 開發者、團隊領導者  
**預計閱讀時間**: 10-15 分鐘  
**實施時間**: 30-45 分鐘

---

## 📋 目錄

1. [前置準備](#前置準備)
2. [5 分鐘快速啟動](#5-分鐘快速啟動)
3. [核心功能驗證](#核心功能驗證)
4. [常見問題排查](#常見問題排查)
5. [進階配置](#進階配置)
6. [附錄：速查表](#附錄速查表)

---

## 前置準備

### 系統要求

-   ✅ Git (用於版本控制與回滾)
-   ✅ 文本編輯器 (VS Code 推薦)
-   ✅ 備份當前配置文件

### 需要修改的文件

```
📁 專案根目錄/
├── 📄 cortex.md                 (核心協議文檔)
├── 📄 custom_modes.yaml         (AI 模式配置)
└── 📁 .ogos/
    └── 📁 alpha_coder/
        ├── 📄 CORTEX_PROTOCOL_V3.0.md           (完整理論文檔)
        ├── 📄 PHASE_B_MODIFICATION_GUIDE.md     (詳細修改指南)
        └── 📄 PHASE_C_QUICK_START_GUIDE.md      (本文檔)
```

### ⚠️ 重要：先備份！

```bash
# 進入專案目錄
cd /path/to/Cortex-Protocol

# 創建備份分支
git checkout -b backup-before-v3.0
git add cortex.md custom_modes.yaml
git commit -m "backup: save config before v3.0 upgrade"

# 返回主分支進行修改
git checkout main
```

---

## 5 分鐘快速啟動

### Step 1: 修改 cortex.md (3 分鐘)

#### 1.1 添加三層語言政策 (在 Section 0.2 之後)

找到這行：

```markdown
-   **Default Execution Policy**: `L2/M2` (Standard Cycle)

---
```

在其後添加：

```markdown
#### **0.3. Language Policy (v3.0 Three-Layer System)**

The AI **MUST** enforce strict language separation across three layers:

**LP-1: Communication Language (敘述層)**

-   **Scope**: Task descriptions, result summaries, explanatory text
-   **Rule**: Use the user's language preference (e.g., zh-TW, en-US)
-   **Example**: "我已建立狀態機來管理生命週期" ✅

**LP-2: Technical Terminology (術語層)**

-   **Scope**: Design patterns, framework names, technical concepts
-   **Rule**: Keep in English (international standard)
-   **Example**: "使用 Singleton Pattern 確保唯一實例" ✅

**LP-3: Coding Artifacts (程式層) [ZERO-TOLERANCE]**

-   **Scope**: Source code, comments, commit messages, variable names, function names, API docs
-   **Rule**: **English ONLY**. Zero exceptions unless explicitly testing i18n or user override.
-   **Violation**: ❌ `function 計算總和() { ... }`
-   **Correct**: ✅ `function calculateTotal() { ... }`

**Priority Rule**: When conflict occurs, LP-3 > LP-2 > LP-1

---
```

#### 1.2 添加信心水平系統 (在 Section 3.4 之後)

找到：

```markdown
**Mandatory Rule**: Every AI response **MUST** begin with a status line...

---
```

在其後添加：

```markdown
#### **3.5. Confidence Level Declaration System (v3.0)**

The AI **MUST** mark all substantive claims with one of the following confidence levels:

| Level          | Tag            | Usage                                                |
| -------------- | -------------- | ---------------------------------------------------- |
| **Verified**   | `[VERIFIED]`   | Direct evidence (test output, logs, code inspection) |
| **Confident**  | `[CONFIDENT]`  | Strong analysis with high certainty                  |
| **Probable**   | `[PROBABLE]`   | Reasonable inference with good evidence              |
| **Uncertain**  | `[UNCERTAIN]`  | Multiple possibilities, insufficient evidence        |
| **Assumption** | `[ASSUMPTION]` | Explicit stated assumption                           |

**Examples**:

-   ✅ `[VERIFIED] All 128 tests passed (see output above)`
-   ✅ `[CONFIDENT] This refactoring will improve maintainability based on SOLID principles`
-   ✅ `[PROBABLE] The bug is likely in the parser module, based on the stack trace`
-   ✅ `[UNCERTAIN] The issue could be network-related or database timeout`
-   ✅ `[ASSUMPTION] Assuming Node.js version >= 16`

**Enforcement**: Claims without confidence tags = protocol violation.

---
```

#### 1.3 增強狀態報告協議 (修改 Section 3.4)

找到這段：

```markdown
**Mandatory Rule**: Every AI response **MUST** begin with a status line declaring its current state and the active execution policy using the format `[STATE: <CURRENT_STATE> | POLICY: <L/M>]`.
```

替換為：

```markdown
**Mandatory Rule**: Every AI response **MUST** begin with a status line using this format:
```

[STATE: <STATE> | POLICY: <L/M> | LANG: <LP-1_LANG>]

```

**Components**:
- `STATE`: Current TESM state (IDLE, ANALYZING, PLANNING, etc.)
- `POLICY`: Execution policy (L1/M1, L2/M2, etc.)
- `LANG`: LP-1 communication language (zh-TW, en-US, etc.)

**Example**:
```

[STATE: PLANNING | POLICY: L2/M2 | LANG: zh-TW]

```

```

### Step 2: 修改 custom_modes.yaml (2 分鐘)

#### 2.1 更新 `code` mode

找到 `code` mode 的 `# Operational Rules` 部分，在第 6 條規則之後添加：

```yaml
          7.  **Confidence-Driven Claims (Anti-Hallucination):** Never make absolute claims without evidence. Use confidence level tags: `[VERIFIED]` for direct evidence, `[CONFIDENT]` for strong analysis, `[PROBABLE]` for reasonable inference, `[UNCERTAIN]` for multiple possibilities, `[ASSUMPTION]` for explicit assumptions.
          8.  **Language Policy Enforcement (LP-3 ZERO-TOLERANCE):** All generated code, comments, commit messages, variable names, and technical documentation **MUST** be in English. Explanations and summaries follow the user's language preference (LP-1). This is non-negotiable except for explicit i18n testing or user override.
```

#### 2.2 更新 `debug` mode

同樣在第 6 條規則之後添加：

```yaml
7.  **Confidence-Driven Debugging:** All diagnoses and hypotheses must include confidence levels. Use `[VERIFIED]` only when you have direct evidence (e.g., a passing test after a fix). Use `[PROBABLE]` for likely root causes based on stack traces and analysis.
```

#### 2.3 更新 `alpha-coder` mode

在第 5 條規則之後添加：

```yaml
          6.  **Explicit Uncertainty Acknowledgment:** You must clearly state when you are uncertain about an aspect of your analysis. Use confidence level tags consistently: `[VERIFIED]`, `[CONFIDENT]`, `[PROBABLE]`, `[UNCERTAIN]`, `[ASSUMPTION]`. Never present speculative analysis as definitive fact.
          7.  **Language Policy (Analysis Context):** While your working files can use the user's preferred language for reasoning, all code examples, technical identifiers, and final recommendations in reports must adhere to LP-3 (English only for code artifacts).
```

#### 2.4 為其他編輯模式添加語言政策註釋

在以下 modes 的 `# Operational Rules` 最後添加註釋：

-   `ui-ux-designer`
-   `code-simplifier`
-   `test-engineer`

```yaml
# Language Policy Compliance (v3.0):
#   - LP-3 (ZERO-TOLERANCE): All generated code MUST be in English
#   - Explanations follow user's language preference (LP-1)
```

---

## 核心功能驗證

### Test 1: LP-3 強制英文代碼 ✅

**測試任務** (使用繁體中文指示):

```
請使用 Code mode 建立一個簡單的 JavaScript 函數來計算兩個數字的總和
```

**期望結果**:

```javascript
// ✅ 正確：函數名、參數、註釋全為英文
function calculateSum(a, b) {
	// Calculate the sum of two numbers
	return a + b;
}

// ❌ 錯誤：出現中文變數名或註釋
function 計算總和(數字1, 數字2) {
	// ← 協議違規
	// 計算兩個數字的總和
	return 數字1 + 數字2;
}
```

**AI 的說明部分應為繁中**:

```
我已建立 calculateSum 函數。這個函數接收兩個參數並回傳其總和。
```

---

### Test 2: 信心水平標記 ✅

**測試任務**:

```
請使用 Debug mode 分析為什麼這段代碼會導致性能問題
```

**期望結果** (AI 回應應包含):

```markdown
[STATE: ANALYZING | POLICY: L2/M2 | LANG: zh-TW]

根據代碼分析，我識別出以下潛在性能瓶頸：

1. [VERIFIED] 在 line 42，存在一個 O(n²) 的嵌套迴圈（已透過代碼檢查確認）
2. [CONFIDENT] 這會在輸入數據量 > 1000 時導致顯著延遲
3. [PROBABLE] 可以透過使用 HashMap 優化為 O(n)
4. [ASSUMPTION] 假設輸入數據不包含重複值

推薦方案：將嵌套迴圈重構為單次遍歷 + HashMap 查找...
```

```

---

### Test 3: 增強狀態報告 ✅

**測試任務**:
```

請使用任何 mode 開始一個需要規劃的任務

```

**期望結果** (AI 回應開頭):
```

[STATE: ANALYZING | POLICY: L2/M2 | LANG: zh-TW]

我正在分析此任務的複雜度...

````

**驗證點**:
- ✅ 包含 `STATE`
- ✅ 包含 `POLICY`
- ✅ 包含 `LANG` (新增的 v3.0 功能)

---

## 常見問題排查

### Q1: YAML 格式錯誤

**症狀**: 修改 `custom_modes.yaml` 後無法載入配置

**解決方案**:
1. 檢查縮排是否使用**空格**（不是 Tab）
2. 檢查多行字串是否正確使用 `|-`
3. 使用 YAML validator 驗證：
   ```bash
   # 線上驗證工具
   https://www.yamllint.com/

   # 或使用命令行工具
   yamllint custom_modes.yaml
````

**常見錯誤**:

```yaml
# ❌ 錯誤：使用 Tab 縮排
	customInstructions: |-
	    content here

# ✅ 正確：使用空格
    customInstructions: |-
        content here
```

---

### Q2: AI 仍然產生中文代碼

**症狀**: 即使設定 LP-3，AI 仍產生中文變數名或註釋

**可能原因與解決方案**:

1. **配置未生效**

    - 確認 `custom_modes.yaml` 已正確儲存
    - 重新載入 AI 配置（重啟 session）

2. **舊的對話上下文干擾**

    - 開始新的對話 session
    - 明確告知 AI："請遵循 Cortex Protocol v3.0"

3. **用戶明確覆蓋**
    - 檢查是否在任務描述中要求使用中文
    - LP-3 僅在「測試 i18n」或「用戶明確要求」時可例外

---

### Q3: 信心水平標記過於頻繁

**症狀**: AI 在每句話都加上信心標記，影響可讀性

**這不是問題**: v3.0 設計如此

**理由**:

-   協議要求「所有實質性宣稱」必須標記
-   目的是防止 AI 幻覺，特別是能力幻覺（Capability Hallucination）
-   在關鍵決策場景，這種明確性是必要的

**可選的緩解措施**:

-   對於敘述性段落，可使用段落級標記：

    ```markdown
    [CONFIDENT] 以下分析基於充分的代碼審查：

    此架構採用 MVC pattern，這提供了... Controller 層負責... Model 層封裝...
    ```

---

### Q4: 如何回滾到舊版本

**完整回滾步驟**:

```bash
# 1. 檢視可用的備份
git log --oneline

# 2. 回滾到備份點
git checkout backup-before-v3.0

# 3. 複製文件到主分支
git checkout main
git checkout backup-before-v3.0 -- cortex.md custom_modes.yaml

# 4. 提交回滾
git commit -m "revert: rollback to pre-v3.0 config"
```

---

## 進階配置

### 選項 1: 調整信心水平強制等級

如果您的團隊認為信心標記過於嚴格，可以調整為「建議性」而非「強制性」。

**修改位置**: `cortex.md` Section 3.5

**原文**:

```markdown
**Enforcement**: Claims without confidence tags = protocol violation.
```

**調整為**:

```markdown
**Enforcement**: Claims without confidence tags = warning (not blocking).
```

**權衡**:

-   ✅ 減少摩擦，提高流暢性
-   ❌ 降低幻覺防範效果
-   建議：至少在 L3/M3 (Complex/Rigorous) 任務中保持強制

---

### 選項 2: 為特定語言配置例外

如果您的團隊有特殊需求（例如，日本團隊需要日文註釋），可以擴展 LP-3 規則。

**修改位置**: `cortex.md` Section 0.3

**原始 LP-3**:

```markdown
-   **Rule**: **English ONLY**. Zero exceptions unless explicitly testing i18n or user override.
```

**擴展為**:

```markdown
-   **Rule**: **English ONLY**, except:
    -   i18n/l10n testing scenarios
    -   Explicit user override with `[LANG-OVERRIDE: ja-JP]` directive
    -   User-facing error messages (must be in resource files, not hardcoded)
```

**使用範例**:

```
[LANG-OVERRIDE: ja-JP]
請建立一個登入表單，所有 UI 文字使用日文
```

---

### 選項 3: 整合到 CI/CD 流程

**目標**: 自動驗證 commit 是否符合 LP-3

**實施方案** (使用 Git hooks):

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Check for non-ASCII characters in code files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|py|go|java|cpp|c|h)$')

for FILE in $STAGED_FILES; do
    # Check for Chinese/Japanese/Korean characters in code
    if grep -P '[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]' "$FILE"; then
        echo "❌ LP-3 Violation: Non-ASCII characters found in $FILE"
        echo "   All code artifacts must use English only."
        exit 1
    fi
done

echo "✅ LP-3 Check passed"
exit 0
```

**啟用方式**:

```bash
chmod +x .git/hooks/pre-commit
```

---

### 選項 4: 自定義 AMRS 注入頻率

**背景**: v3.0 預設每 3 輪對話注入一次記憶強化

**調整位置**: `cortex.md` Section 2 (需在完整版中添加 AMRS 配置)

**可調參數**:

```yaml
AMRS_CONFIG:
    P0_injection_frequency: 3 # 關鍵規則注入頻率（輪次）
    P1_injection_frequency: 10 # 重要規則注入頻率
    P2_injection_frequency: 30 # 一般規則注入頻率

    # 長對話觸發器（超過此輪次，增加注入頻率）
    long_conversation_threshold: 50
    long_conversation_p0_freq: 2 # 長對話時的 P0 頻率
```

**權衡**:

-   頻率 ↑ → 記憶更強 → Token 成本 ↑
-   頻率 ↓ → 成本 ↓ → 上下文衰減風險 ↑

---

## 附錄：速查表

### LP-3 英文強制規則速查

| 項目                 | 規則       | 範例                       |
| -------------------- | ---------- | -------------------------- |
| 函數名               | ✅ English | `calculateTotal()`         |
| 變數名               | ✅ English | `const userName = ...`     |
| 類別名               | ✅ English | `class UserManager`        |
| 註釋                 | ✅ English | `// Calculate total price` |
| Commit 訊息          | ✅ English | `feat: add user login`     |
| API 文檔             | ✅ English | `@param {string} userId`   |
| 測試描述             | ✅ English | `it('should return 200')`  |
| 錯誤訊息 (hardcoded) | ❌ 禁止    | 應使用 i18n 資源檔         |
| UI 文字 (hardcoded)  | ❌ 禁止    | 應使用 i18n 資源檔         |
| 任務說明             | 🟡 LP-1    | 使用用戶語言               |
| 結果報告             | 🟡 LP-1    | 使用用戶語言               |

---

### 信心水平選擇流程圖

```
開始陳述一個事實或結論
           ↓
    是否有直接證據？
    (測試輸出/日誌/代碼檢查)
       ↙YES        ↘NO
  [VERIFIED]      是否基於充分分析？
                      ↙YES        ↘NO
                 [CONFIDENT]    是否有合理推論？
                                   ↙YES        ↘NO
                              [PROBABLE]    是否有多種可能？
                                               ↙YES        ↘NO
                                          [UNCERTAIN]  是明確假設？
                                                          ↙YES
 cortex.md

# 暫存當前修改
git stash

# 恢復之前的暫存
git stash pop

# 建立新分支測試 v3.0
git checkout -b test-v3.0
```

---

## 實施時程建議

### 小型團隊 (1-3 人)

**Day 1: 準備與測試**

-   09:00-09:30: 備份當前配置
-   09:30-10:30: 按照本指南修改 `cortex.md` 和 `custom_modes.yaml`
-   10:30-12:00: 執行 3 個核心功能驗證測試
-   14:00-15:00: 使用真實任務測試 1 小時
-   15:00-16:00: 根據測試結果微調

**Day 2-3: 團隊適應**

-   團隊成員開始使用 v3.0
-   收集反饋，特別是關於信心水平標記的可讀性
-   如需要，執行「進階配置 - 選項 1」放寬強制等級

**Week 2: 穩定化**

-   確認所有團隊成員適應新規則
-   評估是否需要 CI/CD 整合（選項 3）

---

### 中大型團隊 (4+ 人)

**Week 1: 試點階段**

-   選擇 2-3 位技術領導者先行測試
-   在隔離的分支進行 v3.0 配置
-   完成至少 5 個真實任務的驗證
-   記錄遇到的問題與解決方案

**Week 2: 團隊培訓**

-   向全團隊介紹 v3.0 的三大核心改進
-   進行 30 分鐘實作工作坊
-   分享試點階段的最佳實踐

**Week 3: 全面部署**

-   合併 v3.0 配置到主分支
-   啟用 CI/CD 整合（如適用）
-   設立「v3.0 回饋頻道」收集意見

**Week 4: 優化與穩定**

-   根據團隊反饋進行微調
-   更新內部文檔與範例
-   確認 KPI（如幻覺事件減少率）

---

## 成功指標 (KPI)

實施 v3.0 後，您應該觀察到以下改善：

### 定量指標

1. **LP-3 違規率**

    - **目標**: < 5% 的代碼審查發現中文代碼
    - **測量**: Code review 記錄 / Git hook 攔截數
    - **基準**: v2.0 時期的違規率（如有記錄）

2. **AI 幻覺事件**

    - **目標**: 減少 60-80%
    - **測量**:
        - 「AI 宣稱完成但實際未完成」事件數
        - 「AI 提供錯誤假設但未標記」事件數
    - **追蹤方式**: 團隊回報 + 代碼審查記錄

3. **信心水平使用率**
    - **目標**: > 90% 的實質性宣稱包含信心標記
    - **測量**: 隨機抽樣 20 個 AI 回應進行人工檢查

### 定性指標

4. **團隊滿意度**

    - **方法**: 每週快速調查（1-5 分）
    - **問題**:
        - "v3.0 是否提高了 AI 輸出品質？"
        - "LP-3 規則是否過於嚴格？"
        - "信心水平標記是否有助於決策？"

5. **代碼品質感知**
    - **方法**: 代碼審查者的反饋
    - **觀察**:
        - AI 生成代碼的可讀性
        - 命名一致性
        - 註釋品質

---

## 進階閱讀與資源

### 完整理論文檔

如需深入理解 v3.0 的設計原理，請閱讀：

📄 **CORTEX_PROTOCOL_V3.0.md**  
位置: `.ogos/alpha_coder/CORTEX_PROTOCOL_V3.0.md`  
內容:

-   15 個完整章節 (1,500+ 行)
-   AMRS v3.0 記憶系統架構
-   六大幻覺類型深度分析
-   Tool Pre-Validation 機制
-   Response Schema 規範

### 實證案例分析

了解 v3.0 如何解決真實世界的問題：

📄 **12_empirical_case_analysis.md**  
位置: `.ogos/alpha_coder/12_empirical_case_analysis.md`  
內容: 基於 461 行真實 AI 工作記錄的分析

📄 **13_empirical_refinement.md**  
位置: `.ogos/alpha_coder/13_empirical_refinement.md`  
內容: 基於實證數據的 v3.0 修正方案 (1000+ 行)

### 社群與支援

-   **GitHub Issues**: 回報 bug 或建議改進
-   **內部 Wiki**: 分享最佳實踐與案例
-   **定期審查會議**: 每月檢視協議效果

---

## 結語與下一步

### 🎉 恭喜！

完成本快速指南後，您已經：

-   ✅ 理解 Cortex Protocol v3.0 的三大核心改進
-   ✅ 掌握 5 分鐘快速配置流程
-   ✅ 學會核心功能驗證方法
-   ✅ 了解常見問題的排查方案
-   ✅ 知道如何進行進階配置

### 📋 建議的下一步行動

**立即執行**:

1. [ ] 備份當前配置（使用 Git）
2. [ ] 按照 Step 1 & 2 完成配置修改
3. [ ] 執行 3 個核心功能驗證測試

**本週完成**: 4. [ ] 用 v3.0 完成 3-5 個真實任務 5. [ ] 記錄遇到的問題與解決方案 6. [ ] 決定是否需要進階配置

**持續優化**: 7. [ ] 收集團隊反饋 8. [ ] 追蹤 KPI 指標 9. [ ] 閱讀完整理論文檔（如需深入）

### 💡 記住核心原則

> **LP-3 (ZERO-TOLERANCE)**: 所有代碼產物必須使用英文  
> **信心水平聲明**: 所有實質性宣稱必須標記  
> **證據優先**: 先證據，後分析

### 🆘 需要幫助？

如果遇到本指南未涵蓋的問題：

1. 查閱完整理論文檔 (`CORTEX_PROTOCOL_V3.0.md`)
2. 查閱詳細修改指南 (`PHASE_B_MODIFICATION_GUIDE.md`)
3. 搜尋實證案例分析 (`12_empirical_case_analysis.md`)
4. 向團隊技術領導者諮詢
5. 在專案 GitHub Issues 提出問題

---

## 文檔版本資訊

**版本**: v3.0  
**最後更新**: 2025-11-12  
**作者**: Alpha Coder (AI Research Engineer)  
**審閱狀態**: Phase 14 完成

**修訂歷史**:

-   v3.0 (2025-11-12): 初始版本，涵蓋三大核心改進
-   v3.0.1 (TBD): 預計加入更多真實案例

---

**相關文檔**:

-   [`CORTEX_PROTOCOL_V3.0.md`](.ogos/alpha_coder/CORTEX_PROTOCOL_V3.0.md) - 完整理論文檔
-   [`PHASE_B_MODIFICATION_GUIDE.md`](.ogos/alpha_coder/PHASE_B_MODIFICATION_GUIDE.md) - 詳細修改指南
-   [`cortex.md`](cortex.md) - 主協議文件（待修改）
-   [`custom_modes.yaml`](custom_modes.yaml) - AI 模式配置（待修改）

---

_End of Quick Start Guide - Phase C Complete_ [ASSUMPTION]

````

---

### 常用 Git 命令速查

```bash
# 備份當前配置
git add cortex.md custom_modes.yaml
git commit -m "backup: v3.0 upgrade checkpoint"

# 檢視修改差異
git diff cortex.md
git diff custom_modes.yaml

# 回滾單個文件
git checkout HEAD~1
````
