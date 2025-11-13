# Phase 9: Persistent Memory System Architecture Design

## 1. Understanding & Analysis

### 1.1 Design Goal

設計一個**主動式記憶強化系統（Active Memory Reinforcement System, AMRS）**，確保關鍵規則在長對話中不會因上下文壓縮或注意力衰減而失效。

### 1.2 Core Design Principles

1. **Frequency-Adaptive**: 根據規則重要性和對話長度動態調整提醒頻率
2. **State-Triggered**: 在關鍵狀態轉換時自動注入規則
3. **Acknowledgment-Based**: 要求 AI 明確確認關鍵規則
4. **Structured-Enforcement**: 通過輸出格式約束強制遵守
5. **Cost-Efficient**: 平衡提醒頻率與 token 消耗

## 2. Deep Dive: System Architecture

### 2.1 Memory Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 0: Immutable Core (System Prompt Level)              │
│  • Role Definition                                          │
│  • Execution Framework Schema                               │
│  • Critical P0 Rules (Compressed)                           │
│  Decay Risk: MINIMAL (highest priority in attention)       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Active Reinforcement Buffer (Dynamic Injection)   │
│  • Rule Injection Points (triggered by state/turn count)   │
│  • Acknowledgment Validation                                │
│  • Compliance Monitoring                                    │
│  Decay Risk: LOW (refreshed every N turns)                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Task Context (Working Memory)                     │
│  • Current task details                                     │
│  • Mode-specific instructions                               │
│  • Execution plan                                           │
│  Decay Risk: MEDIUM (can be overwritten by new tasks)      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Conversational Context                            │
│  • User messages                                            │
│  • AI responses                                             │
│  • Tool outputs                                             │
│  Decay Risk: HIGH (compressed after window saturation)     │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Rule Injection Mechanism

#### 2.2.1 Injection Trigger Matrix

| Trigger Type              | Condition             | Injected Rules                             | Frequency Cap    |
| ------------------------- | --------------------- | ------------------------------------------ | ---------------- |
| **State Transition**      | IDLE → ANALYZING      | Language Policy, Context Foundation        | Every transition |
| **State Transition**      | PLANNING → EXECUTING  | Tool Confirmation, Anti-Hallucination AH-2 | Every transition |
| **State Transition**      | EXECUTING → VERIFYING | Evidentiary Protocol                       | Every transition |
| **Turn Counter**          | Every 5 turns         | P0 Critical Rules                          | Max 1/5 turns    |
| **Turn Counter**          | Every 10 turns        | P1 High-Priority Rules                     | Max 1/10 turns   |
| **Error Event**           | Tool failure          | Tool Confirmation Protocol                 | Immediate        |
| **Complexity Escalation** | L1→L2 or L2→L3        | Quality Gates for new level                | Immediate        |

#### 2.2.2 Injection Format (Structured)

```markdown
╔════════════════════════════════════════════════════════════════╗ ║ 🔒 CRITICAL RULE INJECTION [Turn: 15 | Trigger: State→EXECUTING] ║ ╚════════════════════════════════════════════════════════════════╝

[RULE AH-2: Tool Call Confirmation Protocol] • You MUST wait for explicit user confirmation after each tool use • NEVER assume a tool operation succeeded without seeing the result • If no confirmation received, ask for status before proceeding

[RULE LP-1: Coding Language Enforcement] • ALL code, comments, commit messages, and technical docs → English • Conversation with user → Follow Language Preference (currently: zh-TW) • Exception: User-facing strings or explicit user override

╔════════════════════════════════════════════════════════════════╗ ║ ✓ ACKNOWLEDGMENT REQUIRED: Respond with the exact phrase below ║ ╚════════════════════════════════════════════════════════════════╝ "✓ [ACKNOWLEDGED] I will enforce tool confirmation and English coding standards."
```

### 2.3 Response Schema Enforcement

#### 2.3.1 Mandatory Response Structure

所有 AI 回應必須遵守以下 schema：

```yaml
response:
    required:
        - headers:
              - state_policy: '[STATE: <state> | POLICY: <L/M>]'
              - language_declaration: '[LANG: Comm=<user_lang> | Code=en]'
              - turn_number: '[TURN: <N>]' # Auto-incremented

        - acknowledgments: # Only when rule injection occurred
              - format: '✓ [ACKNOWLEDGED] <specific rule compliance statement>'

        - confidence_markers: # For any claims or assumptions
              - format: '[<LEVEL>] <statement>'
              - levels: [VERIFIED, HIGH-CONFIDENCE, INFERRED, UNCERTAIN, ASSUMPTION]

        - body:
              - content: '<main response>'

        - footers: # Optional but recommended
              - next_state: 'Next: <state>'
              - rule_reminder: '[REMEMBER: <critical rule if approaching threshold>]'
```

#### 2.3.2 Validation & Auto-Correction

如果 AI 的回應違反 schema：

1. **System-level validation** (由 IDE/系統執行)
2. **Auto-rejection** 並返回錯誤：

```
⚠️ RESPONSE REJECTED: Missing required header [STATE: <state> | POLICY: <L/M>]
Please regenerate response with proper structure.
```

### 2.4 Adaptive Frequency Algorithm

```python
def calculate_injection_frequency(rule_priority, conversation_context):
    """
    動態計算規則注入頻率
    """
    base_frequency = {
        'P0': 5,   # Every 5 turns
        'P1': 10,  # Every 10 turns
        'P2': 20   # Every 20 turns
    }

    # 根據違規歷史調整
    if rule_priority in conversation_context.recent_violations:
        frequency = base_frequency[rule_priority] // 2  # 加倍頻率
    else:
        frequency = base_frequency[rule_priority]

    # 根據對話複雜度調整
    if conversation_context.task_complexity >= 'L3':
        frequency = frequency // 1.5  # 提高頻率

    # 根據上下文使用率調整
    context_usage = conversation_context.token_count / conversation_context.max_tokens
    if context_usage > 0.7:  # 接近窗口上限
        frequency = frequency // 2  # 顯著提高頻率

    return int(frequency)
```

## 3. Synthesis & Conclusion: Complete Refactoring Strategy

### 3.1 Cortex Protocol v2.0 Structure

```
# Cortex Protocol v2.0: Active Memory Architecture

## Section 0: Execution Framework (NEW)
├─ 0.1 Response Schema (Mandatory Structure)
├─ 0.2 Memory Layers & Persistence Rules
├─ 0.3 Rule Injection System
└─ 0.4 Validation & Enforcement Mechanisms

## Section
```
