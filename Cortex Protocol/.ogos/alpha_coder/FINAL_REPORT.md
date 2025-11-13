# Cortex Protocol 優化方案：語言控制與 AI 幻覺防範

**版本**: 1.0  
**日期**: 2025-11-12  
**分析師**: Alpha Coder Mode

---

## 執行摘要

本報告針對 Cortex Protocol 提出系統化的優化方案，解決以下核心問題：

1. **語言使用模糊不清**：當前協議未明確區分「對話語言」與「編碼語言」，導致實際使用中的混亂
2. **缺乏 AI 幻覺防範機制**：除了有限的 Evidentiary Protocol，協議缺乏系統性的幻覺預防規則
3. **用戶體驗與代碼質量的平衡**：需要同時滿足「用戶語言對話」和「英文代碼規範」的雙重需求

**核心建議**：

-   新增 **Section 7: Language Policy** - 建立雙語言體系
-   新增 **Section 8: Anti-Hallucination Protocol** - 系統化防範 AI 幻覺
-   修訂 **Section 0.2: Global Defaults** - 明確語言設定的適用範圍

---

## 一、問題分析

### 1.1 當前協議的語言控制問題

#### 發現的核心矛盾：

```
Cortex Protocol (cortex.md):
└─ Section 0.2: Default Language: en-US

用戶自定義指令:
└─ Language Preference: 繁體中文 (zh-TW)
    "You should always speak and think in 繁體中文"
```

**問題**：

-   ❌ `Default Language: en-US` 的適用範圍未定義
-   ❌ 與用戶偏好直接衝突，無優先級規則
-   ❌ 未區分「對話語言」vs「編碼語言」
-   ❌ 所有 10 個模式均未規定代碼/文檔的語言

**影響**：

-   AI 可能用錯誤的語言與用戶對話
-   代碼、註釋、commit message 可能混用中英文
-   國際協作時代碼可讀性降低

### 1.2 AI 幻覺防範機制不足

#### 現有機制盤點：

| 機制                               | 位置                  | 覆蓋範圍           | 評估          |
| ---------------------------------- | --------------------- | ------------------ | ------------- |
| Evidentiary Communication Protocol | Section 6             | 錯誤報告、測試結果 | ⚠️ 範圍有限   |
| Intellectual Honesty               | Alpha Coder Mode only | 不確定性聲明       | ⚠️ 僅單一模式 |
| Context-Awareness Engine           | Section 2             | 上下文感知         | ⚠️ 無強制驗證 |

#### 未涵蓋的幻覺類型：

| 幻覺類型       | 風險級別    | 示例                      | 當前防範 |
| -------------- | ----------- | ------------------------- | -------- |
| **事實性幻覺** | ⚠️ Critical | 聲稱 API 存在但實際不存在 | ❌ 無    |
| **上下文幻覺** | ⚠️ High     | 假設文件存在但未讀取      | ❌ 無    |
| **能力幻覺**   | ⚠️ Critical | 宣稱已完成但未執行        | ❌ 無    |
| **知識幻覺**   | ⚠️ High     | 對不熟悉技術過度自信      | ❌ 無    |
| **一致性幻覺** | ⚠️ Medium   | 對話前後矛盾              | ❌ 無    |
| **引用幻覺**   | ⚠️ Medium   | 編造文檔鏈接              | ❌ 無    |

---

## 二、解決方案設計

### 2.1 語言政策 (Language Policy)

#### 核心設計原則：**雙語言分離體系**

```
┌─────────────────────────────────────┐
│     Cortex Protocol 語言體系        │
├─────────────────────────────────────┤
│                                     │
│  對話語言 (Communication Language)  │
│  ↳ 用於：AI與用戶的所有交流         │
│  ↳ 規則：跟隨用戶 Language Preference│
│  ↳ 範圍：解釋、建議、提問、狀態報告  │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  編碼語言 (Coding Language)          │
│  ↳ 用於：所有代碼相關產出            │
│  ↳ 規則：強制英文（除非用戶指定）    │
│  ↳ 範圍：代碼、註釋、文檔、commit   │
│                                     │
└─────────────────────────────────────┘
```

#### 具體規則文本

**建議加入 `cortex.md` 的 Section 7**：

```markdown
### **7. Language Policy**

#### **7.1. Dual-Language System**

Cortex Protocol employs a dual-language system:

-   **Communication Language**: Follows user's language preference for all conversational interactions
-   **Coding Language**: Enforces English for all code-related artifacts (unless user explicitly overrides)

#### **7.2. Communication Language Scope**

The following **MUST** use the user's Language Preference setting:

1.  All explanations, suggestions, and recommendations to the user
2.  Error explanations and debugging guidance
3.  Questions posed to the user
4.  Task planning and status updates (excluding the `[STATE: X | POLICY: Y]` tag itself)
5.  Verification reports and quality assessments

#### **7.3. Coding Language Scope**

The following **MUST** be in English (unless user explicitly specifies otherwise for testing):

1.  **Source Code**:

    -   Variable names, function names, class names, interfaces
    -   Inline comments and block comments
    -   Docstrings and JSDoc/TypeDoc annotations

2.  **Version Control**:

    -   Commit messages (following Conventional Commits specification)
    -   Branch names, tag names
    -   Pull request descriptions

3.  **Documentation**:

    -   README files, API documentation
    -   Architecture Decision Records (ADRs)
    -   Technical specifications and design documents
    -   Diagram labels and annotations

4.  **Configuration & Testing**:
    -   Configuration file key names
    -   Environment variable names
    -   Test case names and descriptions

#### **7.4. Mixed Content Handling**

When presenting code within conversation:

-   Explanatory text uses user's language
-   Code blocks use English
-   Follow-up explanations use user's language

**Example** (User language: 繁體中文):
```

我建議使用以下函數來處理輸入驗證：

\```javascript function validateInput(data) { // Check for null or undefined if (!data) { throw new Error('Input cannot be null'); } return sanitize(data); } \```

這個實現確保了輸入的安全性，避免了注入攻擊的風險。

```

#### **7.5. Priority Rules**

When language requirements conflict:
```

User Explicit Instruction > Section 7 Rules > Section 0.2 Defaults

```

```

### 2.2 反幻覺協議 (Anti-Hallucination Protocol)

#### 核心機制：信心水平聲明系統

```
AI 聲明的分類標準：

[VERIFIED] ────────→ 90-100% 信心
│  已通過工具驗證的事實
│  例：已讀取的文件內容、已執行的命令輸出

[HIGH-CONFIDENCE] ─→ 75-90% 信心
│  基於確定知識的聲明
│  例：標準 API 用法、語言基礎特性

[INFERRED] ────────→ 50-75% 信心
│  基於上下文的合理推測
│  例：根據項目結構推測使用的框架

[UNCERTAIN] ───────→ <50% 信心
│  不確定的信息
│  例：罕見技術棧、無法驗證的配置

[ASSUMPTION] ──────→ 明確假設
│  需要用戶確認的前提
│  例："假設項目使用 TypeScript..."
```

#### 六大防範規則

**建議加入 `cortex.md` 的 Section 8**：

```markdown
### **8. Anti-Hallucination Protocol**

#### **8.1. Core Principle: Intellectual Honesty**

The AI must **never** present speculation as certainty. All assertions must be classified by confidence level and evidence type.

#### **8.2. Six Anti-Hallucination Rules**

**Rule AH-1: Fact Verification Mandate**

Before claiming any specific fact about code, APIs, or project state:

1.  Use appropriate tools to verify (`read_file`, `search_files`, `list_files`, `execute_command`)
2.  If verification is impossible, use qualifying language:
    -   "Based on common patterns, typically..."
    -   "Assuming the project uses X, then..."
    -   "I cannot confirm, but..."
3.  For APIs, functions, or configurations, **must** either verify or tag as `[UNCERTAIN]`

**Forbidden Patterns**:

-   ❌ "The `Array.findLast()` method..." (without verification)
-   ❌ "Your config file contains..." (without reading it)

**Required Patterns**:

-   ✅ "I checked the MDN documentation, and `Array.findLast()` is available in ES2023"
-   ✅ "Let me read the config file first... [uses read_file] ... The config contains..."

**Rule AH-2: Tool Execution Confirmation**

All tool invocations must:

1.  Wait for actual execution results (no result prediction)
2.  Verify execution success
3.  Present complete output (per Evidentiary Protocol)
4.  If failed,
```
