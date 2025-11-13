# Phase 1: Current Protocol Analysis - Language Control Mechanisms

## 1. Understanding & Analysis

### Core Issue

分析 Cortex Protocol 和 custom_modes.yaml 中關於語言控制的現有機制，識別以下問題：

1. **語言控制的模糊性**：何時使用英文、何時使用用戶語言的規則不明確
2. **文件編輯語言未強制**：沒有明確規定代碼、文檔等文件必須使用英文
3. **缺乏幻覺防範機制**：沒有系統性防止 AI 產生不確定內容的規則

### Context

-   **Cortex Protocol** (`cortex.md`): 核心協議文件，定義了狀態機、執行策略、質量門檻
-   **Custom Modes** (`custom_modes.yaml`): 定義了 10 個專業模式的行為規範
-   **Current Language Setting**:
    -   Global Defaults 設定 `Default Language: en-US`
    -   User's Language Preference 設定為 `繁體中文 (zh-TW)`
    -   存在衝突：協議說英文，用戶偏好說中文

### Chosen Approach

逐段分析兩個文件，識別：

1. 語言控制相關的規則（顯性和隱性）
2. 可能導致語言使用混亂的模糊地帶
3. 缺失的幻覺防範機制
4. 與其他協議規則的衝突點

---

## 2. Deep Dive

### 2.1 Cortex Protocol (`cortex.md`) 語言相關分析

#### 2.1.1 Section 0.2: Global Defaults

```markdown
-   **Default Language**: `en-US`
```

**發現**：

-   ✅ 明確設定了預設語言為英文
-   ❌ **Critical Gap**: 沒有說明「Default Language」的適用範圍
    -   是指「與用戶對話」的語言？
    -   還是指「編寫代碼/文檔」的語言？
    -   還是兩者都是？
-   ❌ **Conflict**: 與實際的 "Language Preference: 繁體中文" 指令存在直接衝突

**推論**：這個設定意圖不明，實際執行中會被用戶的 Language Preference 覆蓋。

#### 2.1.2 Section 4: Code Craftsmanship

```markdown
1.  **Meaningful Commit Messages**: Adhere to the `Conventional Commits` specification.
2.  **Meaningful Comments**: Explain the _why_, not the _what_.
3.  **Internationalization (i18n)**: User-facing strings **MUST NOT** be hardcoded.
```

**發現**：

-   ✅ Commit Messages 使用 Conventional Commits（通常是英文）
-   ✅ 強調 i18n，暗示對用戶界面要支援多語言
-   ❌ **Missing Rule**: 沒有明確規定 commit message 必須使用英文
-   ❌ **Missing Rule**: 沒有規定代碼註釋(comments)的語言
-   ❌ **Missing Rule**: 沒有規定變量名、函數名的語言（但業界慣例是英文）

**推論**：協議隱含假設使用英文編寫代碼，但沒有顯性規定。

#### 2.1.3 Section 6: Evidentiary Communication Protocol

```markdown
#### **6.1. Principle of Verbatim Evidence**

In situations involving errors, failures, or test results, the AI is forbidden from providing only a summary. It **must** present the original, verbatim output...
```

**發現**：

-   ✅ **Anti-Hallucination Mechanism**: 要求逐字呈現證據，不得僅提供摘要
-   ✅ 這是一個重要的幻覺防範規則
-   ⚠️ **Limited Scope**: 僅適用於錯誤報告和測試結果，不涵蓋其他場景

**推論**：這是協議中唯一明確的幻覺防範機制，但範圍有限。

### 2.2 Custom Modes (`custom_modes.yaml`) 語言相關分析

#### 2.2.1 Architect Mode (lines 7-30)

```yaml
roleDefinition: You are a senior AI software architect...
4.  **Actionable Plans, Not Implementation Code**: Your primary output is documentation, diagrams, and structured plans.
```

**發現**：

-   ✅ 輸出為「documentation, diagrams, and structured plans」
-   ❌ **Missing Rule**: 沒有規定這些文檔的語言
-   ⚠️ **Ambiguity**: 文檔應該用英文（便於國際協作）還是用戶語言（便於理解）？

#### 2.2.2 Alpha Coder Mode (lines 398-433)

```yaml
5.  **Intellectual Honesty**: You must explicitly acknowledge uncertainties, gaps in your knowledge, or areas where an assumption is being made. State your confidence level in your conclusions. Do not present a flawed answer as complete.
```

**發現**：

-   ✅ **Strong Anti-Hallucination Rule**:
    -   必須明確承認不確定性
    -   必須陳述信心水平
    -   禁止將有缺陷的答案呈現為完整答案
-   ✅ 這是最嚴格的幻覺防範機制
-   ⚠️ **Mode-Specific**: 只有 Alpha Coder 模式有此規則，其他模式沒有

### 2.3 User's Custom Instructions 分析

```
Language Preference:
You should always speak and think in the "繁體中文" (zh-TW) language unless
the user gives you instructions below to do otherwise.
```

**發現**：

-   ✅ 明確要求使用繁體中文「speak and think」
-   ❌ **Critical Ambiguity**: "speak and think" 是否包含「編寫代碼/文檔」？
-   ❌ **Conflict**: 與 Cortex Protocol 的 `Default Language: en-US` 直接衝突

**推論**：

-   "speak" 應該指「與用戶對話」→ 應該用中文
-   "think" 應該指「內部推理」→ 可以用中文
-   **未涵蓋**：「編寫代碼/文檔/commit message」→ 應該用什麼語言？

---

## 3. Synthesis & Conclusion

### 3.1 Summary of Findings

#### 語言控制方面的關鍵問題：

1. **規則衝突**：

    - Cortex Protocol: `Default Language: en-US`
    - User Preference: `繁體中文 (zh-TW)`
    - 沒有明確的優先級或適用範圍

2. **語言適用範圍模糊**：

    - ❌ 沒有區分「對話語言」vs「編碼語言」
    - ❌ 沒有規定代碼、註釋、文檔、commit message 的語言
    - ❌ 沒有規定變量名、函數名的命名語言

3. **缺乏強制機制**：
    - ❌ 沒有在 Quality Gates 中加入語言檢查
    - ❌ 沒有在 State Reporting 中要求語言聲明
    - ❌ 違反語言規則沒有後果

#### 幻覺防範方面的關鍵問題：

1. **現有機制有限**：

    - ✅ Evidentiary Communication Protocol (Section 6)：要求逐字呈現證據
    - ✅ Alpha Coder Mode：要求承認不確定性和陳述信心水平
    - ❌ 其他 9 個模式缺乏類似規則

2. **未涵蓋的幻覺類型**：

    - ❌ **事實性幻覺**：編造不存在的 API、函數、文件
    - ❌ **能力幻覺**：宣稱已完成未完成的工作
    - ❌ **知識幻覺**：對不熟悉的技術假裝專家
    - ❌ **上下文幻覺**：對未讀取的文件進行推測

3. **缺乏驗證機制**：
    - ❌ 沒有要求 AI 在聲稱事實前先驗證
    - ❌ 沒有要求 AI 區分「已驗證的事實」vs「推測」
    - ❌ 沒有要求 AI 提供信息來源

### 3.2 Key Takeaways

1. **語言分離勢在必行**：

    - 必須明確區分「對話語言」（跟隨用戶語言）和「編碼語言」（強制英文）
    - 需要建立清晰的優先級規則

2. **幻覺防範需要系統化**：

    - Alpha Coder 的「Intellectual Honesty」規則應該推廣到所有模式
    - Evidentiary Protocol 的範圍應該擴大
    - 需要新的 Quality Gate 來檢測幻覺

3. **需要新的協議章節**：
    - 建議增加 **Section 7: Language Policy**
    - 建議增加 **Section 8: Anti-Hallucination Protocol**

### 3.3 Confidence Level

-   **語言控制分析**: 95% 信心

    -   文件內容明確，問題識別清晰
    -   基於實際協議文本的分析

-   **幻覺防範分析**: 90% 信心
    -   現有機制識別準確
    -   但幻覺類型的完整性需要在 Phase 2 進一步研究業界最佳實踐來驗證

### 3.4 Remaining Unknowns

1. 業界對 AI 幻覺的分類標準是什麼？（需要外部研究）
2. 其他 AI 協議（如 OpenAI 的 system prompts）如何處理語言分離？
3. 如何在不增加過多複雜度的情況下強制執行語言規則？

### 3.5 Next Steps

✅ **Phase 1 Complete** → **Phase 2**: 深入研究 AI 幻覺的類型、成因、防範機制
