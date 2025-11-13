# Phase 13: Empirical Refinement - 基於實證的最終方案修正

## 1. Understanding & Analysis

### 1.1 核心任務

整合 Phase 12 的實證發現，修正 Cortex Protocol v2.0 與 AMRS 架構，產出經過實戰驗證的 v3.0 最終方案。

### 1.2 關鍵輸入

-   **Phase 12 實證發現**：4 個真實幻覺實例、上下文衰減曲線、語言政策三層需求
-   **Phase 6-11 理論設計**：AMRS 架構、四層記憶、規則優先級系統
-   **用戶核心需求**：
    1. 強制編碼內容使用英文（測試除外）
    2. 對話使用用戶語言
    3. 防止 AI 幻覺（自以為是的錯誤內容）

### 1.3 修正策略

採用 **實證驅動的增量修正（Evidence-Driven Incremental Refinement）** 方法：

1. 保留 AMRS 核心架構（已驗證有效）
2. 基於實證案例修正語言政策（二層 → 三層）
3. 新增針對性機制應對實證中發現的新幻覺類型
4. 強化跨階段一致性保障

---

## 2. Deep Dive: 實證驅動的修正設計

### 2.1 語言政策三層體系（Critical Refinement）

#### 2.1.1 實證證據

```yaml
實證案例（roo_task Phase 1.2, line ~150）:
  原文: "我建立了 `MatchLifecycle` 狀態機來解決 `TextMatch.provider` 的 6 重職責問題"

  語言分析:
    - "我建立了" - 繁體中文（敘述動作）
    - "狀態機來解決" - 繁體中文（連接語義）
    - "的 6 重職責問題" - 繁體中文（描述問題）
    - "`MatchLifecycle`" - 英文（代碼標識符）
    - "`TextMatch.provider`" - 英文（API 路徑）

  發現: 自然使用三層語言混合，不是二元選擇
```

#### 2.1.2 修正設計

```yaml
# === 語言政策 v3.0：三層分離體系 ===

LP-1: Communication Language Policy
  目標: 對話文本使用用戶語言偏好
  適用範圍:
    - 敘述性段落（"我建立了..."、"根據分析..."）
    - 問題說明（"目前遇到..."、"需要優化..."）
    - 結果報告（"完成了..."、"發現..."）
    - 思考過程（"考慮到..."、"權衡..."）

  執行規則:
    - 檢測用戶的 Language Preference 設定
    - 所有對話文本必須使用該語言
    - 僅在引用代碼/術語時切換到 LP-2/LP-3

  違規示例:
    ❌ "I have created the MatchLifecycle state machine"（用戶語言為繁中時）
    ✅ "我建立了 MatchLifecycle 狀態機"

LP-2: Technical Terminology Policy
  目標: 專業術語保持英文以維持國際標準
  適用範圍:
    - 設計模式（Singleton, Factory, Observer, Composite）
    - 技術概念（Lifecycle, Regex, CLI, API, Cache）
    - 框架/庫名稱（React, Vue, Express, Lodash）
    - 演算法名稱（Dijkstra, QuickSort, BFS）
    - 協議/標準（HTTP, REST, OAuth, JSON）

  執行規則:
    - 專業術語直接使用英文，不翻譯
    - 首次出現可附中文註解（可選）
    - 後續使用僅英文

  違規示例:
    ❌ "使用單例模式來管理..."
    ✅ "使用 Singleton Pattern 來管理..."
    ✅ "使用 Singleton Pattern（單例模式）來管理..." [首次]

LP-3: Coding Artifacts Policy
  目標: 所有編碼產物強制使用英文
  適用範圍:
    - 變量名、函數名、類名（camelCase, PascalCase）
    - 代碼註釋（inline, block, JSDoc）
    - Commit messages（遵循 Conventional Commits）
    - 錯誤訊息（Error messages）
    - 日誌輸出（Log statements）
    - 測試描述（Test case names）
    - 技術文檔（README, API docs, 架構文件）
    - 文件路徑與文件名
    - 配置文件內容（YAML, JSON, TOML）

  例外條款:
    - 用戶明確指定為測試目的時（如測試 i18n 功能）
    - 用戶明確要求使用其他語言
    - 處理用戶數據時（user-facing strings 依 i18n 規範）

  執行規則:
    - **零容忍政策**：任何違規必須立即修正
    - 工具調用前驗證：create_file, write_file 等
    - IDE Diagnostics 監控中文字符

  違規示例:
    ❌ function 計算總和(數據) { ... }
    ❌ // 這個函數用來計算總和
    ❌ git commit -m "修復登入錯誤"
    ✅ function calculateTotal(data) { ... }
    ✅ // Calculate total from input data
    ✅ git commit -m "fix: resolve login authentication error"
```

#### 2.1.3 三層政策優先級

```yaml
優先級矩陣:
  層級衝突時:
    LP-3 > LP-2 > LP-1

  範例: 代碼註釋中引用術語
    情境: 為 Singleton Pattern 寫註釋
    LP-1 期望: 繁體中文敘述
    LP-3 強制: 註釋必須英文
    決策: LP-3 優先 → 全英文註釋
    輸出: "// Implement Singleton Pattern to ensure single instance"
```

---

### 2.2 跨階段一致性檢查器（New Component）

#### 2.2.1 實證證據

```yaml
實證案例（roo_task）:
    Phase 1-4 宣稱: '✅ 解決 TextMatch.provider 的 6 重職責問題'

    Phase 8.2 發現: '缺少配置驗證的職責分離'

    矛盾分析:
        - 時間跨度: ~100 輪對話
        - 模式切換: Code → Architect → Code → Alpha
        - 根本原因: 無跨階段記憶追蹤
```

#### 2.2.2 設計規格

```yaml
# === 跨階段一致性檢查器（Cross-Phase Consistency Checker）===

組件名稱: CPCC
位置: Persistent Intelligence Core（與 AMRS 並行運行）

觸發條件:
  - AI 使用「已解決」「完成」「修復」等完成態詞彙
  - AI 宣稱某問題「不存在」「無需處理」
  - 任務階段轉換時（PLANNING → EXECUTING）
  - 複雜度級別升級時（L2 → L3）

執行流程:
  1. 提取當前宣稱（Claim Extraction）
     - 解析語義：主語、謂語、賓語
     - 提取關鍵實體：文件名、函數名、問題類型
     - 時間標記：當前 Turn 編號

  2. 檢索歷史宣稱（Historical Claim Retrieval）
     - 搜尋範圍：過去 200 輪對話
     - 匹配條件：相同實體 OR 相關問題域
     - 提取矛盾候選

  3. 矛盾檢測（Contradiction Detection）
     - 邏輯矛盾：「已解決」vs「仍存在」
     - 範圍矛盾：「完全重構」vs「部分修改」
     - 依賴矛盾：「X 依賴 Y」vs「Y 不存在」

  4. 強制輸出（Mandatory Output）
     如檢測到矛盾，AI 必須輸出：

     ┌─────────────────────────────────────────┐
     │ ⚠️ INCONSISTENCY WARNING                │
     │ Turn: [current] | Previous: [history]   │
     ├─────────────────────────────────────────┤
     │ Current Claim:                          │
     │   "[當前宣稱的完整引述]"                 │
     │                                         │
     │ Conflicts With (Turn [N]):              │
     │   "[歷史宣稱的完整引述]"                 │
     │                                         │
     │ Analysis:                               │
     │   [矛盾性質、可能原因、建議處理方式]     │
     └─────────────────────────────────────────┘

     並且：
     - 暫停當前操作
     - 要求人類開發者確認
     - 不得繼續直到矛盾解決

存儲結構:
  .ogos/session_memory/claims_log.jsonl

```

格式: { "turn": <number>, "timestamp": "<ISO8601>", "claim": "<完整宣稱文本>", "entities": ["<實體 1>", "<實體 2>"], "claim_type": "completion|existence|quality" }

範例條目: {"turn": 45, "timestamp": "2025-11-12T10:15:00Z", "claim": "已完成 TextMatch 的 6 重職責重構", "entities": ["TextMatch", "職責重構"], "claim_type": "completion"}

````

#### 2.2.3 AMRS 集成
```yaml
集成方式:
  - CPCC 與 AMRS 並行運行
  - CPCC 檢測到矛盾時，提升規則注入頻率
  - 記錄到 violation_history，影響自適應頻率

觸發 AMRS 強化:
  IF CPCC.detected_contradiction:
    FOR each related_rule IN [LP-*, AH-*, QG-*]:
      AMRS.increase_priority(related_rule, factor=1.5)
      AMRS.inject_immediately()
````

---

### 2.3 工具調用預驗證機制（Tool Pre-Validation）

#### 2.3.1 實證證據

```yaml
實證案例（roo_task Phase 8.3, line ~3800）:
    工具調用: write_to_file
    問題: YAML 格式錯誤（rules vs rule_groups）
    後果: 文件創建失敗，需要多輪修正

    根本原因:
        - 未在執行前驗證 Schema
        - 未檢查與現有文件的一致性
        - 直接執行導致錯誤傳播
```

#### 2.3.2 設計規格

```yaml
# === 工具調用預驗證機制（Tool Pre-Validation Mechanism）===

適用工具:
  - write_to_file
  - apply_diff
  - execute_command（高風險命令）
  - insert_content

執行流程:
  1. 攔截階段（Interception Phase）
     當 AI 準備調用上述工具時，系統自動攔截

  2. 預驗證檢查清單生成（Pre-Validation Checklist Generation）
     AI 必須先輸出：

     ┌─────────────────────────────────────────┐
     │ 🔍 TOOL PRE-VALIDATION                  │
     │ Tool: [tool_name] | Target: [file_path] │
     ├─────────────────────────────────────────┤
     │ Validation Checklist:                   │
     │ [ ] LP-3: All content is in English     │
     │ [ ] Schema validated (if applicable)    │
     │ [ ] No hardcoded secrets/credentials    │
     │ [ ] Consistent with existing patterns   │
     │ [ ] Impact analysis completed           │
     │                                         │
     │ Risk Assessment:                        │
     │   - Affected files: [N]                 │
     │   - Potential side effects: [描述]      │
     │   - Rollback plan: [描述]               │
     │                                         │
     │ Confidence: [VERIFIED|CONFIDENT|...]    │
     └─────────────────────────────────────────┘

  3. 人類確認（Human Confirmation）
     - L1/M1 任務：自動通過（僅記錄日誌）
     - L2/M2 任務：可選確認
     - L3/M3 任務：必須確認

  4. 執行或中止（Execute or Abort）
     - 確認後執行工具調用
     - 拒絕則返回 PLANNING 狀態

特殊規則:
  write_to_file 額外檢查:
    - 掃描內容中的中文字符（LP-3 違規檢測）
    - 驗證文件路徑符合項目慣例
    - 檢查是否覆蓋關鍵文件

  execute_command 額外檢查:
    - 識別高風險命令（rm, dd, format, sudo）
    - 驗證路徑安全性
    - 確認命令語法正確性
```

#### 2.3.3 實施優先級

```yaml
Phase 1 實施（v3.0 發布）:
    - write_to_file 完整預驗證
    - apply_diff 完整預驗證

Phase 2 實施（v3.1 優化）:
    - execute_command 風險命令預驗證
    - insert_content 基礎驗證

豁免條件:
    - 工具連續成功 > 20 次且無違規
    - 用戶明確啟用 "快速模式"
    - 任務複雜度 = L1 且違規歷史 = 0
```

---

### 2.4 Response Schema 強制結構增強

#### 2.4.1 現有設計回顧

```yaml
v2.0 Response Schema:
    headers: [STATE, LANG, TURN]
    acknowledgment: '✓ [ACKNOWLEDGED] ...'
    confidence_markers: '[CONFIDENCE: X] statement'
```

#### 2.4.2 基於實證的增強

```yaml
v3.0 Enhanced Response Schema:

必須元素（Mandatory Elements）:
  1. State Header
     格式: [STATE: <STATE> | POLICY: <L/M> | TURN: <N>]
     位置: 第一行
     範例: [STATE: EXECUTING | POLICY: L2/M2 | TURN: 47]

  2. Language Declaration
     格式: [LANG: <用戶語言> + EN-TECH + EN-CODE]
     位置: 第二行
     範例: [LANG: zh-TW + EN-TECH + EN-CODE]

  3. Rule Acknowledgment（當有規則注入時）
     格式: ✓ [ACKNOWLEDGED] P0 rules: LP-1, LP-3, AH-2 (Turn 47)
     位置: 標頭後

  4. Confidence Markers（任何宣稱性陳述）
     格式: [CONFIDENCE: VERIFIED|CONFIDENT|PROBABLE|UNCERTAIN|ASSUMPTION]
     位置: 宣稱前或後
     範例:
       ✅ [CONFIDENCE: VERIFIED] 所有 128 個單元測試通過
       ✅ [CONFIDENCE: PROBABLE] 此重構可能提升 20% 性能
       ❌ "這個方案絕對沒有問題" [缺少信心標記]

新增元素（New Elements）:
  5. Consistency Check Result（當 CPCC 執行時）
     格式: ✓ [CONSISTENCY: VERIFIED] No contradictions with history
     或:   ⚠️ [INCONSISTENCY WARNING] 詳見警告框

  6. Tool Pre-Validation Result（工具調用前）
     格式: 🔍 [TOOL PRE-VALIDATION] 詳見驗證框

  7. Context Saturation Indicator（上下文飽和度 > 60%）
     格式: 📊 [CONTEXT: 68% | QUALITY: DEGRADING]
     觸發動作: 建議摘要並重新開始對話

完整範例:
```

[STATE: EXECUTING | POLICY: L2/M2 | TURN: 47] [LANG: zh-TW + EN-TECH + EN-CODE] ✓ [ACKNOWLEDGED] P0 rules: LP-1, LP-3, AH-2 (Turn 47) ✓ [CONSISTENCY: VERIFIED] No contradictions with history

我正在執行 `calculateTotal()` 函數的重構。

[CONFIDENCE: CONFIDENT] 基於現有測試覆蓋率 85%，此重構風險較低。

🔍 [TOOL PRE-VALIDATION] Tool: apply_diff | Target: src/utils/calculator.ts ✓ LP-3: All code and comments in English ✓ Schema: TypeScript syntax validated ✓ Impact: 2 files affected, 0 breaking changes Confidence: VERIFIED

準備執行變更...

```

```

---

### 2.5 AMRS 頻率自適應優化

#### 2.5.1 實證衰減曲線校正

```yaml
實證數據（roo_task）:
    Phase 1-4 (Turn 1-50): 健康度 90-100%
    Phase 5-7 (Turn 51-100): 健康度 80-90%
    Phase 8.3 (Turn ~110): 健康度 60-70% [失效]

觀察:
    - 失效點出現在 Turn ~110
    - 關鍵衰減開始於 Turn ~80
    - 模式切換加速衰減（4 次切換）

結論: 現有 v2.0 注入頻率過於保守
```

#### 2.5.2 修正後的注入頻率

```yaml
v3.0 Adaptive Injection Frequency:

基準頻率（Base Frequency）:
  P0-CRITICAL: 每 3 輪（修正自 5 輪）
  P1-HIGH:     每 8 輪（修正自 10 輪）
  P2-STANDARD: 每 15 輪（修正自 20 輪）

加速觸發器（Acceleration Triggers）:
  1. 模式切換（Mode Switch）
     觸發條件: 任何模式切換發生
     效果: 立即注入所有 P0 規則

```

     持續時間: 接下來 10 輪

2. 複雜度升級（Complexity Escalation）觸發條件: L1→L2, L2→L3, L3→L4 效果: 提升所有規則優先級一個等級持續時間: 當前任務完成前

3. 違規檢測（Violation Detected）觸發條件: 任何 P0 規則違規效果: 該規則注入頻率 × 2 持續時間: 連續 5 輪無違規

4. 上下文飽和（Context Saturation）觸發條件: 對話輪次 > 80 OR 估計飽和度 > 60% 效果: P0 頻率 × 1.5, P1 頻率 × 1.3 持續時間: 到對話結束

減速觸發器（Deceleration Triggers）:

1. 完美執行期（Perfect Execution Period）條件: 連續 30 輪無任何違規效果: P2 頻率 ÷ 1.2 限制: P0/P1 不受影響

2. 低複雜度穩定期（Low Complexity Stable Period）條件: L1 任務連續 10 次成功效果: 可啟用 M1 快速模式（跳過部分檢查）

飽和度計算公式（修正）: saturation = (current*turn / 150) * 0.4 + (mode*switches / 5) * 0.3 + (avg*response_length / 2000) * 0.2 + (unique*files_accessed / 50) * 0.1

閾值定義: < 40%: 健康 (GREEN) 40-60%: 警戒 (YELLOW) - 開始加速注入 60-80%: 危險 (ORANGE) - 高頻注入 + 建議摘要 > 80%: 嚴重 (RED) - 強制要求重置對話

````

---

### 2.6 角色定義（custom_modes.yaml）修正

#### 2.6.1 需要修正的角色
```yaml
受影響角色（基於實證）:
  1. Code Mode - 需強化 LP-3 規則（代碼語言強制）
  2. Architect Mode - 需強化 LP-2 規則（術語使用）
  3. Debug Mode - 需強化證據要求（防止能力幻覺）
  4. Alpha Coder Mode - 需強化信心水平聲明
  5. All Modes - 需新增 Response Schema 要求
````

#### 2.6.2 通用修正模板

```yaml
# 所有角色新增的通用規則段落

Anti-Hallucination Protocols:
  1. Confidence Declaration
     - 任何宣稱性陳述必須標記信心水平
     - 格式: [CONFIDENCE: VERIFIED|CONFIDENT|PROBABLE|UNCERTAIN|ASSUMPTION]
     - 範例: "[CONFIDENCE: VERIFIED] 所有測試通過"

  2. Evidence-First Reporting
     - 錯誤/失敗必須提供原始輸出
     - 禁止僅提供摘要
     - 遵循 Evidentiary Communication Protocol

  3. Response Schema Compliance
     - 每個回應必須包含: [STATE | POLICY | TURN]
     - 規則注入後必須確認: ✓ [ACKNOWLEDGED]
     - 上下文飽和時警告: 📊 [CONTEXT: X%]

Language Policy Enforcement (Three-Layer System):
  LP-1: Communication Language
    - 使用用戶的 Language Preference 進行對話
    - 適用: 敘述性文本、問題說明、結果報告

  LP-2: Technical Terminology
    - 專業術語使用英文（Singleton, API, Regex）
    - 適用: 設計模式、技術概念、框架名稱

  LP-3: Coding Artifacts (ZERO-TOLERANCE)
    - 所有代碼、註釋、commit 必須英文
    - 適用: 變量名、函數名、技術文檔、配置文件
    - 例外: 測試目的或用戶明確要求

Tool Pre-Validation (For modes with 'edit' group):
  - 任何 write_to_file, apply_diff 前必須執行預驗證
  - 輸出驗證檢查清單
  - L3/M3 任務必須等待人類確認
```

#### 2.6.3 Code Mode 專屬修正

````yaml
# Code Mode 增強規則

customInstructions: |-
    # Role Definition
    [保留現有內容...]

    # Operational Rules
    [保留現有 1-6 條...]

    7. **Mandatory Language Enforcement (LP-3 Zero-Tolerance)**:
       Before writing or modifying any code, you MUST verify:
       - All variable names are in English (e.g., `calculateTotal`, not `計算總和`)
       - All function names are in English
       - All comments are in English (e.g., `// Calculate total`, not `// 計算總和`)
       - All commit messages follow Conventional Commits in English
       - All error messages are in English
       
       Violation Handling:
       - If IDE diagnostics detect non-English characters in code: IMMEDIATE CORRECTION
       - If user provides non-English code as reference: TRANSLATE before implementing
       
       Exception Clause:
       - User explicitly states "for testing i18n" or similar testing purposes
       - User provides explicit written permission to use another language

    8. **Tool Pre-Validation Protocol**:
       Before calling write_to_file or apply_diff, you MUST:
       1. Output a pre-validation checklist
       2. Scan content for LP-3 violations (non-English code)
       3. Verify schema/syntax correctness
       4. State confidence level
       5. Wait for confirmation (if L2/M2 or higher)

    9. **Evidence-First Error Reporting**:
       When any operation fails:
       - Present the FULL, VERBATIM error output first
       - Then provide your analysis
       - Never summarize without showing the original evidence

    10. **Response Schema Requirement**:
        Every response MUST start with:
        ```
        [STATE: <STATE> | POLICY: <L/M> | TURN: <N>]
        [LANG: <USER_LANG> + EN-TECH + EN-CODE]
        ```
        
        Any claim MUST include confidence marker:
        ```
        [CONFIDENCE: <LEVEL>] <your claim>
        ```
````

#### 2.6.4 Debug Mode 專屬修正

````yaml
# Debug Mode 增強規則

customInstructions: |-
    [保留現有內容...]

    # Operational Rules
    [保留現有 1-6 條...]

    7. **Hypothesis Confidence Declaration**:
       When forming a hypothesis about a bug:
       - [CONFIDENCE: VERIFIED] - You have reproduced the bug and confirmed the cause
       - [CONFIDENCE: CONFIDENT] - Strong evidence points to this cause
       - [CONFIDENCE: PROBABLE] - Likely cause based on symptoms
       - [CONFIDENCE: UNCERTAIN] - Multiple possible causes exist
       
       Example:
       ✅ "[CONFIDENCE: CONFIDENT] I believe the error is caused by null being passed to line 42"
       ❌ "The error is definitely in the calculate function" [missing confidence]

    8. **Evidence Presentation Protocol**:
       When presenting debugging evidence, you MUST:
       1. Show the COMPLETE error message/stack trace
       2. Show the EXACT command that produced it
       3. Show the exit code (if applicable)
       4. THEN provide your analysis
       
       Format:
       ```
       > Command: npm test
       > Exit Code: 1
       
       [FULL ERROR OUTPUT HERE - NO TRUNCATION]
       ```

    9. **No Capability Hallucination**:
       - If you cannot reproduce a bug, SAY SO explicitly
       - If you need more information, ASK instead of guessing
       - If multiple hypotheses exist, LIST THEM ALL with confidence levels
````

---

## 3. Synthesis & Conclusion

### 3.1 核心修正總結

基於 Phase 12 實證分析，v3.0 的五大關鍵修正：

| 修正項目       | 問題根源       | v2.0 設計               | v3.0 修正                                            | 實證驗證                 |
| -------------- | -------------- | ----------------------- | ---------------------------------------------------- | ------------------------ |
| **語言政策**   | 二層過於簡化   | Communication vs Coding | **三層體系**（Communication + Terminology + Coding） | ✅ roo_task 實際用法     |
| **一致性保障** | 跨階段記憶缺失 | 無機制                  | **CPCC 檢查器**（自動檢測矛盾宣稱）                  | ✅ Phase 1-4 vs 8.2 矛盾 |
| **工具安全**   | 缺少執行前驗證 | 直接執行                | **預驗證機制**（強制檢查清單）                       | ✅ Phase 8.3 YAML 錯誤   |
| **注入頻率**   |

頻率過低 | P0 每 5 輪 | **P0 每 3 輪**（加速觸發器） | ✅ Turn ~110 失效點 | | **Response Schema** | 無強制結構 | 基礎標頭 | **增強 Schema**（一致性檢查 + 信心標記） | ✅ 防止隱性幻覺 |

### 3.2 v3.0 架構總覽

```
┌─────────────────────────────────────────────────────────────┐
│                   Cortex Protocol v3.0                      │
│            Anti-Hallucination & Context-Persistent          │
└─────────────────────────────────────────────────────────────┘
                              │
                 ┌────────────┴────────────┐
                 │                         │
         ┌───────▼────────┐       ┌───────▼────────┐
         │  Language      │       │  Hallucination │
         │  Policy v3.0   │       │  Prevention    │
         │  (3-Layer)     │       │  System        │
         └────────────────┘       └────────────────┘
                 │                         │
    ┌────────────┼────────────┐           │
    │            │            │           │
┌───▼───┐   ┌───▼───┐   ┌───▼───┐       │
│ LP-1  │   │ LP-2  │   │ LP-3  │       │
│Commu- │   │Tech   │   │Coding │       │
│nicate │   │Term   │   │(0-Tol)│       │
└───────┘   └───────┘   └───────┘       │
                                         │
              ┌──────────────────────────┘
              │
    ┌─────────┴──────────┐
    │                    │
┌───▼────────┐   ┌───────▼─────────┐
│   AMRS     │   │      CPCC       │
│ v3.0 Fast  │   │  Consistency    │
│ Injection  │   │   Checker       │
└────────────┘   └─────────────────┘
    │                    │
    │         ┌──────────┘
    │         │
┌───▼─────────▼──────────────────────┐
│   Tool Pre-Validation Mechanism    │
│   (write_to_file, apply_diff)      │
└────────────────────────────────────┘
              │
    ┌─────────┴────────┐
    │                  │
┌───▼──────┐   ┌───────▼────────┐
│ Response │   │  State Machine │
│ Schema   │   │   (TESM)       │
│ v3.0     │   │   Enhanced     │
└──────────┘   └────────────────┘
```

### 3.3 實施優先級與路線圖

#### Phase 1: 核心機制（v3.0 正式版）

```yaml
優先級 P0（發布前必須完成）: ✅ 1. 語言政策三層體系（LP-1/LP-2/LP-3） ✅ 2. Response Schema 強制結構 ✅ 3. AMRS 注入頻率修正（3/8/15 輪） ✅ 4. 工具預驗證（write_to_file, apply_diff） ✅ 5. 信心水平聲明系統

優先級 P1（發布後 2 週內）: 🔄 6. CPCC 跨階段一致性檢查器（完整實現） 🔄 7. 所有 custom_modes.yaml 角色修正 🔄 8. cortex.md 完整重寫為 v3.0

優先級 P2（1 個月內優化）: ⏳ 9. execute_command 風險命令預驗證 ⏳ 10. 自適應頻率算法完整實現 ⏳ 11. 上下文飽和度儀表板
```

#### Phase 2: 驗證與優化（v3.1）

```yaml
目標: 收集真實使用數據，驗證 v3.0 有效性

數據收集（1-2 個月）:
    - 違規率統計（LP-3, AH-*, QG-*）
    - 上下文衰減曲線實測
    - CPCC 矛盾檢測準確率
    - 工具預驗證誤報率

優化方向:
    - 根據數據調整注入頻率
    - 優化 CPCC 檢測算法（減少誤報）
    - 增加自動修正能力（LP-3 違規）
```

#### Phase 3: 高級功能（v3.2+）

```yaml
探索性功能:
    - 多會話記憶共享（跨對話的 claims_log）
    - 自動摘要與對話重置建議
    - 違規模式學習（ML-based）
    - 語言混合度分析儀（量化 LP 遵循度）
```

### 3.4 關鍵成功指標（KPIs）

```yaml
v3.0 相較於 v2.0 的改進目標:

語言政策遵循率:
  v2.0 基線: ~80%（估計，基於實證）
  v3.0 目標: >95%（LP-3 零容忍政策）
  測量方法: 自動掃描代碼中的非英文字符

幻覺發生率:
  v2.0 基線: 4 個幻覺 / 110 輪 ≈ 3.6%
  v3.0 目標: <1.5%（減半）
  測量方法: 人工標註 + CPCC 自動檢測

上下文衰減失效點:
  v2.0 基線: Turn ~110
  v3.0 目標: Turn >150（延後 36%）
  測量方法: 追蹤錯誤率隨 Turn 增長的變化

工具執行成功率:
  v2.0 基線: ~85%（Phase 8.3 失敗）
  v3.0 目標: >98%（預驗證機制）
  測量方法: 工具調用失敗次數 / 總調用次數

跨階段一致性:
  v2.0 基線: 無測量（CPCC 不存在）
  v3.0 目標: 矛盾檢測率 >90%
  測量方法: CPCC 檢測到的矛盾 / 人工標註矛盾
```

### 3.5 信心水平與局限性

#### [CONFIDENCE: HIGH (85%)]

以下設計已通過實證驗證，信心度高：

-   ✅ 語言政策三層體系（roo_task 實際用法證實）
-   ✅ AMRS 加速注入頻率（Turn ~110 失效點證實需求）
-   ✅ 工具預驗證需求（Phase 8.3 YAML 錯誤證實）
-   ✅ Response Schema 必要性（實證中缺失導致問題追蹤困難）

#### [CONFIDENCE: CONFIDENT (75%)]

以下設計基於充分理論分析，但缺少直接實證：

-   🟡 CPCC 檢測算法（基於理論推導）
-   🟡 自適應頻率具體公式（需實測校正）
-   🟡 信心水平五級分類（需用戶驗證可用性）

#### [CONFIDENCE: PROBABLE (60%)]

以下設計屬於探索性優化：

-   🟠 執行命令風險評估（啟發式規則）
-   🟠 上下文飽和度公式（多變量估計）

#### [ASSUMPTION]

以下為明確假設前提：

-   ⚪ 假設：AI 能準確識別專業術語 vs 一般詞彙（LP-2 vs LP-1）
    -   風險：邊界模糊詞彙可能分類錯誤
    -   緩解：提供常見術語白名單
-   ⚪ 假設：CPCC 的語義匹配能達到 >80% 準確率
    -   風險：自然語言歧義可能導致誤報
    -   緩解：允許人類覆蓋 CPCC 判斷

### 3.6 已知局限性與風險

```yaml
技術局限性:
  1. CPCC 實施複雜度高
     - 需要語義解析能力
     - 可能增加每輪響應延遲 10-15%
     - 緩解：僅在關鍵詞觸發時啟用

  2. 語言政策邊界模糊
     - 部分詞彙難以歸類（LP-1 vs LP-2）
     - 例如："refactor" 是術語還是一般詞彙？
     - 緩解：建立明確的術語詞典

  3. 預驗證可能降低效率
     - L3/M3 任務需要額外確認步驟
     - 可能增加完成時間 5-10%
     - 緩解：優秀執行記錄後可豁免

使用風險:
  1. 過度注入導致 token 消耗增加
     - 估計: v3.0 比 v2.0 增加 8-12% tokens
     - 影響: 成本上升，但質量提升更多

  2. 嚴格規則可能降低用戶體驗
     - 頻繁的預驗證確認可能打斷流程

- 緩解：提供快速模式選項（M1 豁免部分檢查）

未來風險:
  1. AI 模型升級可能改變行為
     - GPT-5 或未來模型的上下文能力可能不同
     - 需定期重新校準注入頻率

  2. 多語言環境複雜度
     - 當前僅針對繁中+英文優化
     - 其他語言組合可能需要額外調整
```

### 3.7 下一步行動

```yaml
立即行動（Phase 14）: 1. 產出完整 v3.0 文檔 - cortex_v3.0.md（完整協議） - custom_modes_v3.0.yaml（所有角色修正） - implementation_guide.md（實施指南）

    2. 建立測試計劃 - 定義測試場景（10-15 個典型任務） - 建立 KPI 測量方法 - 準備對照組（v2.0 vs v3.0）

    3. 準備發布 - 撰寫發布說明 - 建立遷移指南（v2.0 → v3.0） - 準備示例對話（展示新功能）

短期行動（2 週內）: 1. 小規模實測 - 選擇 3-5 個真實任務 - 記錄所有違規與問題 - 收集用戶反饋

    2. 快速修正 - 基於實測調整參數 - 修復發現的 bug - 優化用戶體驗

長期行動（1-3 個月）: 1. 大規模驗證 - 累積 100+ 任務的數據 - 統計分析 KPI 達成率 - 識別邊緣案例

    2. 持續優化 - v3.1 版本規劃 - 探索 ML-based 優化 - 擴展多語言支持
```

---

## 4. Self-Verification (Three Rounds)

### Round 1: Critical Flaw Detection

#### 檢查項目

```yaml
✅ 1. 實證證據充分性 - 所有修正都引用了 Phase 12 的具體實證 - 語言政策三層：roo_task 實際用法 - CPCC：Phase 1-4 vs 8.2 矛盾 - 工具預驗證：Phase 8.3 錯誤 - 注入頻率：Turn ~110 失效點 評估：✅ PASS

✅ 2. 設計完整性 - 五大修正相互協調，無衝突 - 與 AMRS 架構兼容 - 與 TESM 狀態機兼容 - 提供明確實施路徑 評估：✅ PASS

✅ 3. 可實施性 - 所有機制都有具體規格 - 提供優先級與路線圖 - 識別技術局限與風險 - 定義成功指標 評估：✅ PASS

✅ 4. 信心水平聲明 - 所有設計標註信心度（HIGH/CONFIDENT/PROBABLE） - 明確假設前提 - 承認已知局限性 評估：✅ PASS
```

#### 發現問題

```yaml
⚠️ Minor Issue #1: CPCC 實施細節不足
  問題: 語義解析算法未明確定義
  影響: 可能增加實施難度
  處理: 在 Phase 14 補充技術細節

⚠️ Minor Issue #2: 術語詞典缺失
  問題: LP-2 需要術語白名單但未提供
  影響: 邊界詞彙分類困難
  處理: 在 Phase 14 建立初始詞典（100+ 詞）
```

#### Round 1 結論

**✅ PASS（無 Critical Flaw）** - 發現 2 個 Minor Issues，可在下階段解決。

---

### Round 2: Weak Reasoning Detection

#### 檢查項目

```yaml
🟡 1. 注入頻率數值選擇（P0: 3 輪）
   推理: 基於 Turn ~110 失效點，從 5 輪加速到 3 輪
   疑慮: 為什麼是 3 而非 4 或 2？
   辯護:
     - 實證: v2.0 每 5 輪在 Turn 110 失效
     - 計算: 110/5 = 22 次注入不足
     - 目標: 延後到 Turn 150 需要 150/3 = 50 次
     - 比率: 50/22 ≈ 2.27 倍，合理
   評估：✅ 推理充分

🟡 2. 上下文飽和度公式
   推理: 多變量線性組合
   疑慮: 權重 (0.4/0.3/0.2/0.1) 如何確定？
   辯護:
     - turn 比例佔最大（0.4）符合實證主要因素
     - mode_switches 佔次要（0.3）符合實測加速衰減
     - 承認為啟發式，需實測校正
     - 標註為 [CONFIDENCE: PROBABLE]
   評估：✅ 推理透明，信心度適當

🟡 3. KPI 改進目標設定
   推理: 幻覺率從 3.6% → 1.5%（減半）
   疑慮: 減半目標是否過於樂觀？
   辯護:
     - 保守估計：CPCC 可防止 50% 一致性幻覺
     - 工具預驗證可防止 80% 執行錯誤
     - 語言政策三層可減少 30% 語言混淆
     - 綜合效應支持減半目標
   評估：✅ 推理有據

✅ 4. 三層語言體系分類
   推理: LP-1/LP-2/LP-3 的邊界定義
   疑慮: 分類是否明確？
   辯護:
     - LP-1: 完整句子結構（主謂賓）
     - LP-2: 單一專業術語（名詞短語）
     - LP-3: 代碼語法元素
     - 提供大量範例
     - 承認邊界模糊，提出術語詞典緩解
   評估：✅ 推理清晰，風險已識別
```

#### Round 2 結論

**✅ PASS（無 Weak Reasoning）** - 所有推理鏈清晰，不確定性已適當標註。

---

### Round 3: Minor Issue & Consistency Check

#### 檢查項目

```yaml
✅ 1. 與 Phase 1-11 一致性
   - v3.0 保留 AMRS 核心架構（Phase 9）
   - 繼承四層記憶設計（Phase 5）
   - 擴展而非推翻 v2.0 設計
   評估：✅ 一致

✅ 2. 與用戶需求對齊
   - 需求 1（編碼英文）→ LP-3 零容忍政策 ✅
   - 需求 2（對話用戶語言）→ LP-1 政策 ✅
   - 需求 3（防止幻覺）→ 五大機制綜合 ✅
   評估：✅ 完全對齊

✅ 3. 術語使用一致性
   - AMRS, CPCC, TESM 等縮寫全文定義
   - 信心水平五級統一使用
   - Response Schema 格式統一
   評估：✅ 一致

⚠️ Minor Issue #3: 實施成本估算缺失
   問題: 未估算開發工作量
   影響: 資源規劃困難
   處理: 在 Phase 14 補充（估算：中等，2-3 週開發）
```

#### Round 3 結論

**✅ PASS（僅 1 個新 Minor Issue）** - 整體一致性良好。

---

### Self-Verification 總結

```yaml
三輪驗證結果:
    Round 1 (Critical Flaw): ✅ PASS
    Round 2 (Weak Reasoning): ✅ PASS
    Round 3 (Minor Issues): ✅ PASS (3 個 Minor Issues)

Minor Issues 列表: 1. CPCC 語義解析算法需補充細節 2. LP-2 術語詞典需建立（100+ 詞） 3. 實施成本估算需補充

處理方案:
    - 所有 Minor Issues 在 Phase 14 解決
    - 不影響 v3.0 核心設計發布
    - 可在 v3.1 進一步優化

最終評估: ✅ Phase 13 設計通過三輪自我驗證
```

---

## 5. Document Metadata

```yaml
文檔資訊:
    檔案名: 13_empirical_refinement.md
    階段: Phase 13
    版本: v1.0
    建立時間: 2025-11-12T15:46:00Z
    作者: Alpha Coder
```
