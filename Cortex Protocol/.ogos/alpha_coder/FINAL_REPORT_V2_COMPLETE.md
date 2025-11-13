# Cortex Protocol v2.0: Complete Refactoring Report

# 主動式記憶強化系統 - 完整重構方案

## Executive Summary

本報告提供 Cortex Protocol 的完整重構方案，核心目標是解決 LLM 在長對話中的**上下文衰減（Context Decay）**和**規則遺忘（Rule Forgetting）**問題。

### 核心轉型

```
從: 被動式指令集 (Passive Instruction Set)
到: 主動式記憶強化系統 (Active Memory Reinforcement System, AMRS)

從: 依賴 AI 自律遵守規則
到: 結構化約束 + 動態提醒 + 明確確認
```

### 關鍵創新

1. **四層記憶架構**: 從不可變核心到壓縮歷史，每層有不同的衰減風險和刷新策略
2. **自適應注入頻率**: 根據規則重要性、違規歷史、上下文飽和度動態調整提醒頻率
3. **強制輸出格式**: 將關鍵規則轉換為不可逃避的結構化約束
4. **明確確認機制**: 要求 AI 在注入關鍵規則後明確回應確認語句

---

## Part 1: Problem Analysis

### 1.1 根本問題: 上下文衰減

用戶的核心洞察:

> "如果原先記得，隨後因為上下文壓縮或注意力丟失而忘記呢"

這揭示了當前所有基於「指令」的 AI 協議的固有缺陷：

```
┌─────────────────────────────────────────┐
│ Turn 1-10: AI 完美遵守所有規則          │ ✓
├─────────────────────────────────────────┤
│ Turn 11-30: 開始出現偶發性遺忘          │ ⚠️
├─────────────────────────────────────────┤
│ Turn 31-50: 頻繁違反非關鍵規則          │ ⚠️⚠️
├─────────────────────────────────────────┤
│ Turn 51+: 甚至關鍵規則也可能被忽略      │ ❌
└─────────────────────────────────────────┘

原因:
1. Context Window Saturation (上下文窗口飽和)
2. Attention Weight Decay (注意力權重衰減)
3. Instruction Override (新指令覆蓋舊指令)
4. Recency Bias (最近訊息優先偏誤)
```

### 1.2 現有協議的脆弱性評估

| 機制                   | 位置        | 持久性 | 衰減風險                 | 問題                        |
| ---------------------- | ----------- | ------ | ------------------------ | --------------------------- |
| State Reporting        | Section 3.4 | LOW    | 在 50+ 輪後容易忘記      | 純自然語言指令，無強制機制  |
| Language Policy (提案) | Section 7   | LOW    | 易被用戶語言偏好覆蓋     | 與 Language Preference 衝突 |
| Anti-Hallucination     | Section 8   | MEDIUM | 複雜任務中降級為「建議」 | 無法驗證 AI 是否真的執行    |
| Evidentiary Protocol   | Section 6   | MEDIUM | L1/M1 模式中易被跳過     | 依賴 AI 記得要呈現證據      |
| Quality Gates          | Section 5   | HIGH   | 較不易忘記               | 有具體檢查點，但仍非強制    |

**結論**: 當前協議是**被動式**的，100% 依賴 AI 自律。

### 1.3 AI 幻覺的六大類型與記憶衰減的關聯

| 幻覺類型       | 與記憶衰減的關係                 | 嚴重性   |
| -------------- | -------------------------------- | -------- |
| **事實性幻覺** | 忘記需要查證，直接編造 API/函數  | CRITICAL |
| **上下文幻覺** | 忘記已讀過哪些文件，假設文件存在 | HIGH     |
| **能力幻覺**   | 忘記需要等待工具確認，宣稱已完成 | CRITICAL |
| **知識幻覺**   | 忘記要聲明不確定性，過度自信     | HIGH     |
| **一致性幻覺** | 忘記先前的陳述，前後矛盾         | MEDIUM   |
| **引用幻覺**   | 忘記引用需要驗證，編造文檔連結   | MEDIUM   |

所有這些幻覺都可以追溯到：**AI 忘記了要遵守的規則**。

---

## Part 2: Solution Architecture

### 2.1 四層記憶架構 (Four-Layer Memory Architecture)

```
┌──────────────────────────────────────────────────────────┐
│ Layer 0: Immutable Core (System Prompt Level)           │
│ -------------------------------------------------------- │
│ • Role Definition (壓縮版)                               │
│ • Response Schema (強制格式)                             │
│ • P0 Critical Rules (最高優先級規則，極度壓縮)           │
│ -------------------------------------------------------- │
│ Decay Risk: MINIMAL (始終在注意力最高層)                │
│ Refresh Strategy: NEVER (永久嵌入系統提示)              │
│ Token Budget: ~500 tokens                                │
└──────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────┐
│ Layer 1: Active Reinforcement Buffer                    │
│ -------------------------------------------------------- │
│ • 根據觸發條件動態注入的規則                             │
│ • 狀態轉換時自動注入                                     │
│ • Turn 計數器觸發注入 (5/10/20 turns)                   │
│ • 事件觸發注入 (錯誤、複雜度升級)                        │
│ -------------------------------------------------------- │
│ Decay Risk: LOW (定期刷新)                              │
│ Refresh Strategy: Adaptive (5-20 turns)                  │
│ Token Budget: ~300 tokens per injection                  │
└──────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────┐
│ Layer 2: Task Context (Working Memory)                  │
│ -------------------------------------------------------- │
│ • 當前任務詳情                                           │
│ • 執行計劃                                               │
│ • Mode 特定指令                                          │
│ -------------------------------------------------------- │
│ Decay Risk: MEDIUM (可被新任務覆蓋)                     │
│ Refresh Strategy: Per-task reset                        │
│ Token Budget: Variable (500-2000 tokens)                 │
└──────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────┐
│ Layer 3: Conversational History                         │
│ -------------------------------------------------------- │
│ • 用戶訊息                                               │
│ • AI 回應                                                │
│ • 工具輸出                                               │
│ -------------------------------------------------------- │
│ Decay Risk: HIGH (窗口飽和後壓縮)                       │
│ Refresh Strategy: N/A (由 LLM provider 管理)            │
│ Token Budget: Remaining context window                   │
└──────────────────────────────────────────────────────────┘
```

### 2.2 規則注入系統 (Rule Injection System)

#### 2.2.1 規則分級與注入頻率

| 優先級          | 規則類型   | 範例                           | 基礎頻率 | 違規後頻率 |
| --------------- | ---------- | ------------------------------ | -------- | ---------- |
| **P0-CRITICAL** | 零容忍規則 | 語言政策、工具確認、證據要求   | 每 5 輪  | 每 2-3 輪  |
| **P1-HIGH**     | 質量門檻   | 測試覆蓋、錯誤處理、上下文基礎 | 每 10 輪 | 每 5 輪    |
| **P2-STANDARD** | 最佳實踐   | 代碼風格、文檔標準             | 每 20 輪 | 每 10 輪   |

#### 2.2.2 觸發機制

**1. 狀態轉換觸發 (State-Triggered)**

```yaml
IDLE → ANALYZING:
    inject:
        - LP-1: Language Policy
        - CF-1: Context Foundation Requirements

ANALYZING → PLANNING:
    inject:
        - AH-1: Confidence Level Declaration
        - AH-3: Knowledge Boundary Acknowledgment

PLANNING → EXECUTING:
    inject:
        - AH-2: Tool Confirmation Protocol
        - EH-1: Error Handling Requirements

EXECUTING → VERIFYING:
    inject:
        - EP-1: Evidentiary Protocol
        - QG-*: Quality Gates (based on L/M policy)

VERIFYING → DELIVERING:
    inject:
        - DOC-1: Documentation Standards
        - SR-1: State Reporting Protocol
```

**2. Turn 計數器觸發 (Turn-Counter Triggered)**

```python
current_turn = get_current_turn()

if current_turn % 5 == 0:
    inject_rules(priority='P0', context=conversation_state)

if current_turn % 10 == 0:
    inject_rules(priority='P1', context=conversation_state)

if current_turn % 20 == 0:
    inject_rules(priority='P2', context=conversation_state)
```

**3. 事件觸發 (Event-Triggered)**

```python
# 工具操作失敗
on_tool_failure():
    inject_immediately(rule='AH-2: Tool Confirmation Protocol')

# 複雜度升級
on_complexity_escalation(from_level, to_level):
    inject_immediately(rule=f'QG-{to_level}: Quality Gates')

# 上下文飽和度告警
on_context_saturation(usage_ratio):
    if usage_ratio > 0.7:
        double_injection_frequency(priority='P0')
    if usage_ratio > 0.85:
        inject_immediately(all_critical_rules())

# 規則違規檢測
on_rule_violation(rule_id):
    inject_immediately(rule=rule_id)
    record_violation(rule_id, current_turn)
```

#### 2.2.3 自適應頻率算法

```python
class AdaptiveInjectionManager:
    def __init__(self):
        self.base_frequency = {
            'P0': 5,   #
```
