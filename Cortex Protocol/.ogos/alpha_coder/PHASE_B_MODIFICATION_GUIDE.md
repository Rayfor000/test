# Phase B: 配置檔案修改指南

**狀態**: Ready for Implementation  
**目標檔案**: `cortex.md`, `custom_modes.yaml`  
**執行者**: Human Developer 或 Code Mode

---

## 修改 1: cortex.md - 添加三層語言政策

### 插入位置

在 `#### **0.2. Global Defaults**` 區段之後（第 18 行之後）

### 插入內容

````markdown
---

### **0.3. Language Policy v3.0 (Three-Layer System)**

#### **LP-1: Communication Language Policy**

**Rule**: Use the user's language preference for all conversational text.

**Scope**: Narrative paragraphs, problem descriptions, result reports, thought processes, questions to the user.

**Example**:

-   ❌ "I have created the MatchLifecycle state machine" (when user language = zh-TW)
-   ✅ "我建立了 MatchLifecycle 狀態機"

#### **LP-2: Technical Terminology Policy**

**Rule**: Maintain English for professional terminology to preserve international standards.

**Scope**: Design patterns, technical concepts, framework/library names, algorithm names, protocols/standards.

**Example**:

-   ✅ "使用 Singleton Pattern 來管理全局狀態"
-   ✅ "實現 REST API 來處理 HTTP 請求"

#### **LP-3: Coding Artifacts Policy (ZERO-TOLERANCE)**

**Rule**: Enforce English-only for ALL coding artifacts.

**Scope**:

-   Variable names, function names, class names
-   Code comments (inline, block, JSDoc, docstrings)
-   Commit messages (Conventional Commits)
-   Error messages and log statements
-   Test case names and descriptions
-   Technical documentation (README, API docs)
-   File paths and file names
-   Configuration file content

**Exception**: User explicitly requests for testing purposes OR user-facing data following i18n best practices.

**Violation Examples**:

```javascript
❌ function 計算總和(數據) { ... }
❌ // 這個函數用來計算總和
❌ git commit -m "修復登入錯誤"

✅ function calculateTotal(data) { ... }
✅ // Calculate total from input data array
✅ git commit -m "fix: resolve login authentication error"
```
````

**Priority**: LP-3 > LP-2 > LP-1 (when layers conflict, LP-3 always wins)

````

---

## 修改 2: cortex.md - 添加信心水平系統

### 插入位置
在 `#### **3.4. State Reporting Protocol**` 區段之後（第 118 行之後）

### 插入內容

```markdown

#### **3.5. Confidence Level Declaration System**

**Rule**: Every claim, recommendation, or prediction MUST be marked with a confidence level.

**Available Levels**:

```yaml
[VERIFIED] - Confirmed with concrete evidence
  Use when: Direct evidence available (test results, logs, code inspection)
  Example: "[VERIFIED] All 128 tests passed (see output above)"

[CONFIDENT] - Based on thorough analysis and strong evidence
  Use when: Strong analysis with high certainty
  Example: "[CONFIDENT] This refactor will improve maintainability"

[PROBABLE] - Reasonable inference but not fully verified
  Use when: Reasonable inference with good evidence
  Example: "[PROBABLE] The bug is likely in the parser module"

[UNCERTAIN] - Multiple possibilities exist
  Use when: Multiple possibilities, insufficient evidence
  Example: "[UNCERTAIN] Could be network OR database issue"

[ASSUMPTION] - Explicit assumption being made
  Use when: Making explicit assumptions
  Example: "[ASSUMPTION] Assuming Node.js version >= 16"
````

**Enforcement**:

-   Any definitive statement without confidence marker = PROTOCOL VIOLATION
-   Response Schema enforces this requirement
-   Prevents "self-assured but incorrect" outputs (AI hallucination)

**Example Usage**:

```
[STATE: PLANNING | POLICY: L2/M2]

我已分析了 AuthService 的架構。

[CONFIDENT] 目前的 6 個職責可以分離為 3 個獨立的 service classes。
[PROBABLE] 重構後 cyclomatic complexity 會降低約 70%。
[ASSUMPTION] 假設現有的單元測試涵蓋率 > 80%。

下一步：...
```

````

---

## 修改 3: cortex.md - 增強 State Reporting Protocol

### 替換位置
替換 `#### **3.4. State Reporting Protocol**` 整個區段（第 116-118 行）

### 新內容

```markdown
#### **3.4. State Reporting Protocol (v3.0)**

**Mandatory Format**: Every AI response MUST begin with:

````

[STATE: <CURRENT_STATE> | POLICY: <L/M> | TURN: <N>] [LANG: <USER_LANG> + EN-TECH + EN-CODE]

````

**Components**:
- `STATE`: Current state machine state (IDLE, ANALYZING, PLANNING, etc.)
- `POLICY`: Execution policy (L1/M1, L2/M2, L3/M3, L4/M4)
- `TURN`: Conversation turn counter (for context tracking)
- `LANG`: Language policy declaration
  - `USER_LANG`: User's language preference (e.g., zh-TW, en-US)
  - `EN-TECH`: English technical terminology (LP-2)
  - `EN-CODE`: English coding artifacts (LP-3, zero-tolerance)

**Complete Example**:
```markdown
[STATE: EXECUTING | POLICY: L2/M2 | TURN: 47]
[LANG: zh-TW + EN-TECH + EN-CODE]

我已完成 AuthService 的重構...
````

**Simplified Example** (for non-code-editing modes like Ask, Architect):

```markdown
[STATE: IDLE | POLICY: L4/M4]

您的問題是關於...
```

````

---

## 修改 4: custom_modes.yaml - Code Mode 強化

### 位置
`code` mode 的 `customInstructions` 區段（第 42-67 行）

### 在 `# Operational Rules` 之後添加

```yaml
          7.  **Language Policy Compliance (v3.0)**:
              - **LP-3 (ZERO-TOLERANCE)**: All code, comments, commits, variable names, function names, and any coding artifacts MUST be in English. This is non-negotiable unless explicitly requested by the user for testing purposes.
              - **LP-1**: Use the user's language preference for explanations and dialogue.
              - **LP-2**: Keep technical terminology in English (e.g., "使用 Singleton Pattern" not "使用單例模式").
              - **Pre-Generation Scan**: Before using write_to_file or apply_diff, internally verify that no non-English characters exist in code/comments.

          8.  **Confidence Level Marking**:
              - Any technical recommendation or prediction must be marked with a confidence level: [VERIFIED], [CONFIDENT], [PROBABLE], [UNCERTAIN], or [ASSUMPTION].
              - Example: "[CONFIDENT] This change will resolve the race condition."
````

---

## 修改 5: custom_modes.yaml - Debug Mode 強化

### 位置

`debug` mode 的 `customInstructions` 區段（第 113-137 行）

### 在 `# Operational Rules` 之後添加（第 129 行之後）

288-331)

-   `test-engineer` (line 364-397)

### 添加內容（在各模式的 `# Operational Rules` 最後一條之後）

```yaml
# Language Policy Compliance (v3.0):
#   - LP-3 (ZERO-TOLERANCE): All generated code MUST be in English
#   - Explanations follow user's language preference (LP-1)
```

---

## 驗證清單

完成上述修改後，請驗證：

### cortex.md 驗證

-   [ ] Section 0.3 已添加（三層語言政策）
-   [ ] Section 3.5 已添加（信心水平系統）
-   [ ] Section 3.4 已更新（增強狀態報告協議）
-   [ ] 所有新增內容的 Markdown 格式正確
-   [ ] 代碼區塊的縮排正確

### custom_modes.yaml 驗證

-   [ ] `code` mode 已添加規則 7, 8
-   [ ] `debug` mode 已添加規則 7
-   [ ] `alpha-coder` mode 已添加規則 6, 7
-   [ ] 其他編輯模式已添加語言政策註釋
-   [ ] YAML 縮排正確（使用空格，非 Tab）
-   [ ] 所有字串正確使用 `|-` 或引號

---

## 快速測試

修改完成後，建議進行以下測試：

### 測試 1: LP-3 強制執行

**任務**: 要求 AI (Code mode) 建立一個簡單的 JavaScript function **期望**:

-   ✅ 函數名稱為英文
-   ✅ 註釋為英文
-   ✅ 說明使用您的語言（如繁中）

### 測試 2: 信心水平標記

**任務**: 要求 AI 分析一段代碼的性能瓶頸 **期望**:

-   ✅ 分析結論包含 `[CONFIDENT]` 或 `[PROBABLE]` 等標記
-   ✅ 不會出現無標記的絕對宣稱

### 測試 3: 增強狀態報告

**任務**: 啟動任何需要規劃的任務 **期望**:

-   ✅ 回應開頭包含 `[STATE: ... | POLICY: ...]`
-   ✅ 包含 `[LANG: ...]` 聲明

---

## 回滾方案

如果修改後出現問題，您有以下備份檔案可供回滾：

-   `cortex.md` → 當前版本已在 git history
-   `custom_modes.yaml` → 當前版本已在 git history

建議在修改前先執行：

```bash
git add cortex.md custom_modes.yaml
git commit -m "backup: save current config before v3.0 upgrade"
```

---

## 完整性確認

**Phase B 任務狀態**:

-   ✅ 完整修改指南已產出
-   ✅ 所有關鍵 v3.0 改進已涵蓋
-   ✅ 驗證清單已提供
-   ✅ 測試方案已準備
-   ✅ 回滾方案已說明

**下一步**: 執行 Phase C - 創建快速實施指南

---

_End of Phase B Modification Guide_

```yaml
          7.  **Language Policy Compliance (v3.0)**:
              - **LP-3 (ZERO-TOLERANCE)**: All code fixes, comments, and commit messages MUST be in English.
              - **LP-1**: Explain debugging process and root cause analysis in the user's language.
              - **Confidence Level for Root Cause**: Always mark your root cause hypothesis with a confidence level.
              - Example: "[PROBABLE] The error is caused by null pointer in line 42."
```

---

## 修改 6: custom_modes.yaml - Alpha Coder Mode 強化

### 位置

`alpha-coder` mode 的 `customInstructions` 區段（第 403-427 行）

### 在 `# Operational Rules` 的第 5 條之後添加

```yaml
6.  **Confidence Level Declarations (v3.0)**: You must explicitly mark all conclusions with confidence levels ([VERIFIED], [CONFIDENT], [PROBABLE], [UNCERTAIN], [ASSUMPTION]). This prevents capability hallucination and ensures intellectual honesty. State your confidence level at the end of each major analysis section.

7.  **Language Policy (v3.0)**:
    - All analysis documents in `.ogos/alpha_coder/` must use English for code examples, technical terms, and file/function names (LP-2, LP-3).
    - Explanatory text may use the user's language preference (LP-1) but technical precision takes priority.
    - Example: '分析結果顯示 `calculateTotal()` function 的 cyclomatic complexity 為 42...'
```

---

## 修改 7: custom_modes.yaml - 其他編輯模式

### 適用模式

-   `code-simplifier` (line
