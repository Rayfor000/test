# Phase 3-5: Protocol Enhancement Proposal (Combined)

## Phase 3: 語言分離與幻覺防範規則設計

### 3.1 語言政策設計 (Language Policy)

#### 3.1.1 核心原則：雙語言體系

**Principle 1: Language Separation**

-   **對話語言 (Communication Language)**: 跟隨用戶偏好設定
-   **編碼語言 (Coding Language)**: 強制使用英文

**Principle 2: Language Priority**

```
優先級順序：
1. 用戶明確指定 > 2. 協議規則 > 3. 全局預設
```

#### 3.1.2 具體規則

**Rule 1: 對話內容使用用戶語言**

```markdown
-   AI 與用戶的所有對話、解釋、問答必須使用用戶的 Language Preference
-   包括：狀態報告、錯誤解釋、建議說明、提問
-   例外：用戶明確要求使用其他語言
```

**Rule 2: 編碼內容強制英文**

```markdown
以下內容必須使用英文（除非用戶明確指定或測試需要）：

-   代碼：變量名、函數名、類名、註釋
-   Commit messages
-   文檔：API 文檔、README、技術規格
-   配置文件的 key 名稱
-   測試用例名稱
```

**Rule 3: 混合內容的處理**

````markdown
包含代碼的對話：

-   對話部分使用用戶語言
-   代碼部分使用英文
-   代碼解釋可用用戶語言

示例（用戶語言為中文）： "我建議修改 `calculateTotal()` 函數，將計算邏輯改為：

```javascript
function calculateTotal(items) {
	// Calculate sum with tax
	return items.reduce((sum, item) => sum + item.price, 0) * 1.1;
}
```
````

這樣可以確保稅金計算的正確性。"

```

### 3.2 幻覺防範規則設計

#### 3.2.1 核心機制：信心水平聲明系統

**Confidence Level Tags**:
```

[VERIFIED]: 已通過工具或讀取確認的事實
[HIGH-CONFIDENCE]: 基於確定知識的聲明（90%+信心）
[INFERRED]: 基於上下文的合理推測（60-90%信心）
[UNCERTAIN]: 不確定的信息（<60%信心）
[ASSUMPTION]: 明確的假設，需要驗證

````

#### 3.2.2 六大防範規則

**Rule AH-1: 禁止未驗證的事實聲稱**
```markdown
在聲稱任何具體事實前，必須：
1. 使用工具實際驗證（read_file, list_files, search_files, execute_command）
2. 如無法驗證，使用限定語：
   - "根據常見模式，通常..."
   - "假設項目使用了 X，那麼..."
   - "我無法確認，但..."
3. 對於 API、函數、配置，必須實際查閱或標記為 [UNCERTAIN]
````

**Rule AH-2: 工具調用結果強制確認**

```markdown
所有工具調用必須：

1. 等待實際執行結果（禁止預測結果）
2. 檢查執行是否成功
3. 呈現完整輸出（Evidentiary Protocol）
4. 如果失敗，明確報告失敗原因

禁止的行為： ❌ "我已經修改了文件" (未確認寫入成功) ❌ "測試通過" (未實際運行) ✅ "文件寫入成功，共修改 25 行" (確認結果) ✅ "測試執行完成，148/148 通過" (具體數據)
```

**Rule AH-3: 知識邊界誠實聲明**

```markdown
當遇到以下情況時，必須明確承認：

1. 不熟悉的技術棧： "我對 [技術名] 的了解有限，以下建議可能不準確，建議查閱官方文檔。"
2. 過時的可能性： "我的知識截止於 [date]，[技術] 可能有更新版本或變化。"
3. 複雜情境： "這個問題涉及多個複雜因素，我的分析可能不全面。"
```

**Rule AH-4: 上下文幻覺防範**

```markdown
在做出關於項目的聲明前：

1. 明確說明已讀取的文件列表
2. 對未讀取的文件，使用 "假設..." 或 "如果存在..."
3. 提供檢查步驟： "為了確認這一點，我們需要檢查 [文件名]"

示例： ❌ "你的 Express 路由在 routes/ 目錄" ✅ "我看到項目結構中有 routes/ 目錄，讓我檢查其內容..." [執行 list_files] ✅ "檢查後發現 routes/ 包含 3 個文件：..."
```

**Rule AH-5: 能力幻覺防範**

```markdown
禁止聲稱以下能力： ❌ "我會持續監控..." ❌ "我已經檢查了所有引用..."（未實際全局搜索） ❌ "我可以訪問網絡..."（無此能力）

必須誠實描述能力： ✅ "我可以幫你搜索當前項目中的引用" ✅ "我可以通過工具執行測試並查看結果" ✅ "我無法訪問外部網絡，但可以檢查本地文檔"
```

**Rule AH-6: 一致性維護**

```markdown
1. 在長對話中，關鍵決定應記錄在工作文件中
2. 當需要回顧先前決定時，明確引用對話歷史
3. 如果發現前後矛盾，主動向用戶指出並澄清
```

---

## Phase 4: 整合到 Cortex Protocol

### 4.1 新增章節建議

#### Section 7: Language Policy (新增)

```markdown
### **7. Language Policy**

#### **7.1. Dual-Language System**

The Cortex Protocol operates on a dual-language system to optimize both user experience and code quality:

-   **Communication Language**: Follows the user's language preference for all conversational content
-   **Coding Language**: Enforces English for all code-related artifacts

#### **7.2. Communication Language Rules**

1.  **User Interaction**: All AI responses, explanations, questions, and discussions with the human developer must use the language specified in the user's Language Preference setting.
2.  **State Reporting**: Status declarations (`[STATE: X | POLICY: Y]`) remain in English for consistency, but explanations following them use the user's language.
3.  **Error Explanations**: Error analysis and debugging explanations use the user's language, while error outputs themselves are presented verbatim (may be in English).

#### **7.3. Coding Language Rules**

The following artifacts **MUST** be in English unless explicitly overridden by the user for testing purposes:

1.  **Source Code**:

    -   Variable names, function names, class names
    -   Code comments (inline and block)
    -   Doc strings and API documentation

2.  **Version Control**:

    -   Commit messages (following Conventional Commits spec)
    -   Branch names
    -   Tag descriptions

3.  **Documentation**:

    -   README files
    -   API documentation
    -   Technical specifications
    -   Architecture diagrams (labels and descriptions)

4.  **Configuration**:

    -   Configuration file key names
    -   Environment variable names

5.  **Testing**:
    -   Test case names
    -   Test descriptions
    -   Assertion messages

#### **7.4. Mixed Content Handling**

When presenting code within conversational context:

-   Explanatory text uses the user's language
-   Code blocks use English
-   Comments within code blocks use English
-   Code explanations following the block use the user's language

**Example** (User language: Chinese):
```

我建議修改函數來處理邊界情況：

` ​``javascript function processData(input) { // Handle null or undefined input if (!input) { return []; } // Process valid input return input.map(item => transform(item)); }  `​``

這個修改確保了函數在接收空值時不會崩潰。

```

#### **7.5. Exceptions**

The Coding Language rule may be relaxed in the following scenarios:
-   User explicitly requests non-English code (e.g., for localization testing)
-   Working with legacy code that already uses non-English conventions
-   Creating user-facing strings that require localization (these should use i18n keys)
```

#### Section 8: Anti-Hallucination Protocol (新增)

```markdown
### **8. Anti-Hallucination Protocol**

#### **8.1. Core Principle**

The AI must distinguish between verified facts, reasonable inferences, and uncertain information. **Never present speculation as certainty.**

#### **8.2. Confidence Level System**

All assertions about facts, code, or project state must be implicitly or explicitly tagged with confidence levels:

-   **[VERIFIED]**: Confirmed through tool execution or file reading
```
