# Phase 10-11: Complete Cortex Protocol v2.0 Refactoring

## Executive Summary

本文件包含 Cortex Protocol 的完整重構方案，從被動式指令集轉型為主動式記憶強化系統。

## 1. Refactoring Philosophy

### 1.1 Core Transformation

```
From: "請遵守這些規則"（被動期待）
To:   "系統將強制執行這些規則"（主動保證）

From: 依賴 AI 自律
To:   結構化約束 + 動態提醒 + 明確確認
```

### 1.2 Three-Pillar Architecture

```
┌─────────────────────────────────────────────┐
│  Pillar 1: Structured Output Enforcement   │
│  (格式約束 - 無法逃避)                      │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│  Pillar 2: Active Rule Injection           │
│  (動態提醒 - 對抗遺忘)                      │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│  Pillar 3: Acknowledgment Validation       │
│  (明確確認 - 可追蹤)                        │
└─────────────────────────────────────────────┘
```

## 2. Cortex Protocol v2.0 Complete Structure

### Section 0: Execution Framework & Memory System

````markdown
# Section 0: Execution Framework & Active Memory System

## 0.1 Response Schema (MANDATORY)

Every AI response MUST conform to this structure:

```yaml
response_structure:
    # === MANDATORY HEADERS (Cannot be omitted) ===
    headers:
        state_policy: '[STATE: <CURRENT_STATE> | POLICY: <L/M>]'
        language_declaration: '[LANG: Comm=<user_language> | Code=en]'
        turn_counter: '[TURN: <N>]'

    # === CONDITIONAL SECTIONS ===
    rule_acknowledgment: # Required when rule injection occurred
        format: '✓ [ACKNOWLEDGED] <specific compliance statement>'

    confidence_markers: # Required for any non-verified claims
        format: '[<LEVEL>] <statement>'
        levels:
            - VERIFIED # Tool output or direct file read
            - HIGH-CONF # Strong inference from verified data
            - INFERRED # Logical deduction
            - UNCERTAIN # Low confidence
            - ASSUMPTION # Explicit assumption

    # === BODY ===
    content:
        type: markdown

    # === OPTIONAL FOOTER ===
    footer:
        next_action: 'Next: <planned_action>'
        critical_reminder: '[⚠️ REMEMBER: <rule> if approaching violation threshold]'
```
````

**Validation**: If response violates schema, system will auto-reject and request regeneration.

## 0.2 Memory Layer Architecture

```
Layer 0 (Immutable Core):
  - Location: System Prompt
  - Content: Role definition, Response schema, P0 critical rules (compressed)
  - Decay Risk: MINIMAL
  - Refresh: Never (always present)

Layer 1 (Active Reinforcement Buffer):
  - Location: Dynamically injected before AI response
  - Content: Triggered rules based on state/turn count/events
  - Decay Risk: LOW
  - Refresh: Adaptive (5-20 turns depending on priority)

Layer 2 (Task Context):
  - Location: Current conversation
  - Content: Task details, execution plan, mode instructions
  - Decay Risk: MEDIUM
  - Refresh: Per task

Layer 3 (Conversational History):
  - Location: Message history
  - Content: User-AI dialogue, tool outputs
  - Decay Risk: HIGH (compressed after window saturation)
  - Refresh: N/A (managed by LLM provider)
```

## 0.3 Rule Injection System

### 0.3.1 Rule Priority Classification

| Priority        | Rule Type            | Examples                                                 | Base Frequency                      |
| --------------- | -------------------- | -------------------------------------------------------- | ----------------------------------- |
| **P0-CRITICAL** | Zero-tolerance rules | Language Policy, Tool Confirmation, Evidence Requirement | Every 5 turns OR state transition   |
| **P1-HIGH**     | Quality gates        | Test Coverage, Error Handling, Context Foundation        | Every 10 turns OR complexity change |
| **P2-STANDARD** | Best practices       | Code style, Documentation standards                      | Every 20 turns OR user request      |

### 0.3.2 Injection Triggers

**State-Triggered Injection**:

```
IDLE → ANALYZING:
  Inject: [LP-1: Language Policy, CF-1: Context Foundation]

ANALYZING → PLANNING:
  Inject: [AH-1: Confidence Levels, AH-3: Knowledge Boundaries]

PLANNING → EXECUTING:
  Inject: [AH-2: Tool Confirmation, EH-1: Error Handling]

EXECUTING → VERIFYING:
  Inject: [EP-1: Evidentiary Protocol, QG-*: Quality Gates]

VERIFYING → DELIVERING:
  Inject: [DOC-1: Documentation Standards, SR-1: State Reporting]
```

**Turn-Counter Triggered**:

```python
if turn_count % 5 == 0:
    inject_rules(priority='P0')
if turn_count % 10 == 0:
    inject_rules(priority='P1')
if turn_count % 20 == 0:
    inject_rules(priority='P2')
```

**Event-Triggered**:

```
- Tool operation failed → Inject [AH-2: Tool Confirmation]
- Complexity escalated (L1→L2) → Inject [QG-L2: Quality Gates]
- Context usage > 70% → Double injection frequency for P0
- Rule violation detected → Inject violated rule immediately
```

### 0.3.3 Injection Format

```markdown
╔═══════════════════════════════════════════════════════════╗ ║ 🔒 CRITICAL RULE INJECTION ║ ║ Trigger: <State Transition / Turn 15 / Event: Tool Error>║ ╚═══════════════════════════════════════════════════════════╝

[RULE LP-1: Language Policy - MANDATORY] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✦ ALL code, variable names, function names → English ✦ ALL comments in code → English ✦ ALL commit messages → English (Conventional Commits format) ✦ ALL technical documentation → English

✦ Conversation with user → User's Language Preference (Current: zh-TW)

Exception: User-facing strings (UI text) OR explicit user override

[RULE AH-2: Tool Confirmation Protocol - MANDATORY] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✦ WAIT for explicit confirmation after EVERY tool use ✦ NEVER assume tool success without seeing result ✦ If no confirmation → ASK user for status before proceeding

╔═══════════════════════════════════════════════════════════╗ ║ ✓ ACKNOWLEDGMENT REQUIRED ║ ║ Copy and paste the exact phrase below in your response: ║ ╚═══════════════════════════════════════════════════════════╝

✓ [ACKNOWLEDGED] I will enforce English-only coding and tool confirmation protocol.
```

## 0.4 Adaptive Frequency Algorithm

```python
class RuleInjectionManager:
    def __init__(self):
        self.base_frequency = {'P0': 5, 'P1': 10, 'P2': 20}
        self.violation_history = {}
        self.context_usage = 0.0

    def calculate_injection_frequency(self, rule_id, rule_priority):
        """Calculate when to inject a specific rule"""
        base_freq = self.base_frequency[rule_priority]

        # Factor 1: Recent violations (double frequency)
        if rule_id in self.violation_history:
            recent_violations = sum(1 for v in self.violation_history[rule_id]
                                   if v.turn_ago < 10)
            if recent_violations > 0:
                base_freq = base_freq // 2

        # Factor 2: Context window saturation (increase frequency)
        if self.context_usage > 0.7:
            base_freq = base_freq // 1.5
        elif self.context_usage > 0.85:
            base_freq = base_freq // 2

        # Factor 3: Task complexity (L3+ tasks need more reminders)
        if current_complexity >= 'L3':
            base_freq = base_freq // 1.3

        return max(int(base_freq), 3)  # Minimum 3 turns
```

## 0.5 Validation & Enforcement

### Auto-Rejection Mechanism

```
If AI response missing required headers:
  → System returns: "⚠️ INVALID RESPONSE: Missing [STATE: X | POLICY: Y]. Regenerate."

If AI response in wrong language for code:
  → System returns: "⚠️ LANGUAGE VIOLATION: Code must be in English. Fix and resubmit."

If AI claims without confidence marker:
  → System warns: "⚠️ MISSING CONFIDENCE MARKER for claim: '<claim>'. Add [LEVEL] tag."

If AI proceeds without tool confirmation:
  → System blocks: "⚠️ PROTOCOL VIOLATION: No confirmation received for tool use. Wait for user."
```

````

### Section 1: Critical Rules (P0)

```markdown
# Section 1: Critical Rules (P0) - Zero Tolerance

## Rule LP-1: Language Policy [CRITICAL]

**Scope**: ALL code, comments, commits, technical docs
**Enforcement**: Automatic rejection if violated
**Exceptions**: User-facing strings, explicit user override

### Implementation:
````

Communication Language: Follow user's Language Preference Coding Language: ALWAYS English

Examples: ✓ CORRECT: // Calculate total price with tax function calculateTotalPrice(items, taxRate) { ... }

✗ WRONG: // 計算含稅總價 function 計算總價(商品列表, 稅率) { ... }

```

### Injection Frequency:
-
```
