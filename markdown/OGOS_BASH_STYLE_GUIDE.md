# OGOS Bash 風格指南 (OGOS Bash Style Guide)

本指南定義了 **OGOS Bash 程式碼風格 (OGOS Bash Style)**。此規範旨在將動態、弱型別且易出錯的傳統 Bash 腳本，升級為具備 **強型別約束 (Type-Safe Feeling)**、**高度防禦性 (Highly Defensive)** 與 **極致視覺美感 (Aesthetic Consistency)** 的現代軟體工程產物。

此風格在 [`sh/utilkit.sh`](sh/utilkit.sh) 8.0.0 版本中獲得了深度驗證與統一重構，完美平衡了編程規範與工程實務。

---

## 核心設計哲學 (Core Philosophies)

1. **命名空間隔離 (Namespace Isolation)**：全域資源必須完全置於命名空間保護下。
2. **極致視覺平坦 (Extremely Flat Flow)**：摒棄深層巢狀，善用衛語句與簡短邏輯，但對複合任務保持結構安全。
3. **顯式型別優先 (Explicit Type Over Implicit)**：顯式宣告變數的型別與作用域，保障記憶體安全性 (Memory Safety)。
4. **字串與括號完整包裹 (Complete Quote & Braces Wrapping)**：防範空值、空格與萬用字元 (Wildcards) 造成的解析崩潰。
5. **執行安全性保障 (Execution Hardening Security)**：徹底拒絕 `eval` 等高危動態執行，提供完備的主動環境硬化 (Active Environment Hardening)。

---

## 1. 命名空間架構 (Namespace Architecture)

### 1.1 雙冒號語法 (Double-Colon Syntax)

- 所有全域暴露的函式、全域狀態變數，必須完全置於特定的命名空間下，並以雙冒號 `::` 作為連接符：

  ```bash
  function fs::file_exist() { ... }
  ```

- 命名空間名稱與函式名稱必須採用小寫蛇形命名法 `snake_case`。

### 1.2 函式宣告語法 (Function Declaration Syntax)

- 宣告函式時必須同時包含 `function` 關鍵字與括號 `()`：

  ```bash
  # 正確 (Correct)
  function sys::cpu_usage() { ... }

  # 錯誤 (Incorrect)
  sys::cpu_usage() { ... }
  ```

---

## 2. 變數宣告與強型別規範 (Variables & Type Constraints)

### 2.1 常數與變數命名風格 (Naming Style)

- **可變與不可變變數 (Mutable & Immutable Variables)**：使用小寫蛇形命名法 `snake_case`（例如 `local_buffer`）。
- **全域常數 (Global Constants)**：使用大寫蛇形命名法 `SNAKE_CASE`（例如 `readonly LANG_ENV="C.UTF-8"`）。

### 2.2 作用域宣告與 `local` 約束

- 在函式內部，所有變數必須顯式宣告為 `local`。
- 只有在全域範疇 (Global Scope) 且非唯讀時才可使用 `declare`；常數一律使用 `readonly` 宣告。

### 2.3 顯式型別優先順序 (Explicit Type Priority)

當有多種類型的變數需要宣告，應遵循「顯式型別優先於隱式型別」的原則，在函式頂端依以下順序排列： `local -i` (整數) > `local -n` (名稱參照) > `local -r` / `readonly` (唯讀) > `local -x` (環境變數) > none (純鍵名/字串)

```bash
# 正確的宣告順序範例 (Correct Declaration Order)
local -i row_num=1 col_num=1
local -n out_cols="$2"
local temp_cols=()
local row_arg
```

### 2.4 陣列宣告規範 (Array Declaration)

- **禁止**使用 `local -a` 宣告索引陣列，應一律採用 `local array_name=()` 語法同時完成「宣告」與「初始化空陣列」。
- 允許在同一個 `local` 指令中宣告多個陣列。
- 唯一的例外是關聯陣列，必須顯式使用 `declare -A` (全域) 或 `local -A` (區域)。

### 2.5 唯讀 (Immutable) 變數與 declare -r 的替代

- 在全域範疇中，應**徹底棄用** `declare -r`，改用 `readonly` 關鍵字宣告唯讀常數。
- 在函式內部，為了防止變數逸出 (Escape) 成為全域唯讀，允許使用 `local -r`。

### 2.6 指令替換的賦值防護 (Command Substitution Hardening)

- **硬性要求**：若變數的賦值對象是指令替換 `$(command)`，必須**分兩行**進行宣告與賦值。
- 這是為了避免 `local` 或 `declare` 的內建傳回值（永遠為 0）靜默遮蔽 (Shadowing) 了指令替換本身的結束狀態碼 (Exit Status)。

```bash
# 正確 (Correct) - 完美捕捉 exit status
local virt_typ
virt_typ="$(systemd-detect-virt 2>/dev/null)"

# 錯誤 (Incorrect) - exit status 被 local 遮蔽
local virt_typ="$(systemd-detect-virt 2>/dev/null)"
```

_對於局部唯讀變數，若分行賦值，則可在賦值完成後使用 `readonly var_name` 將其鎖定。_

---

## 3. 變數展開花括號 `${}` 與雙引號 `""` 補充規範 (Quotes & Braces Expansion)

在 OGOS Bash 中，變數展開必須具有絕對的一致性，透過區分「整數域」、「特殊系統變數域」與「普通字串/路徑域」來平衡視覺噪點與安全性。

### 3.1 必須使用花括號 `${}` 且必須加雙引號 `""` 的情境

所有**非純整數、非布林、非特殊系統變數**的字串、路徑、陣列展開或動態變數，展開時**必須**用花括號 `${}` 包裹，且**必須**用雙引號 `""` 鎖定：

- **一般字串**：`"${my_string}"`，防範其含有空格時發生引數分割。
- **檔案路徑**：`"${file_path}"`，保障含有空格或萬用字元的目錄能安全運作。
- **陣列全部展開**：`"${array_name[@]}"`，這是多重型別，必須安全包裹以保留元素邊界。
- **大/小寫轉換**：一律採用 `${var_name,,}` (小寫) 或 `${var_name^^}` (大寫)。

```bash
# 正確 (Correct)
local item
for item in "${items[@]}"; do
    [[ -f "${item}" ]] && io::txt "Found: ${item}"
done
```

### 3.2 允許「裸露不加引號與花括號」的例外情境

為了降低不必要的語法噪點，並確保 Regex、萬用字元能發揮其原生作用，以下情境**絕對不應**或**不需**加引號與花括號：

1. **純數值評估域 (Pure Numeric Context)**：
   - 在雙小括號 `(( ... ))` 的算術運算條件或 `$(( ... ))` 的賦值子中，變數展開**絕對不應**帶有雙引號，且**建議省略** `$` 與 `{}` 符號。

   ```bash
   # 正確 (Correct)
   ((row_num < total_rows))

   # 錯誤 (Incorrect)
   (($row_num < ${total_rows}))
   ```

2. **條件測試的左側 (Left Hand of Double Brackets)**：
   - 在雙中括號 `[[ ... ]]` 測試子中，變數置於**左側**時**不應**加雙引號（例如：`[[ -z "${v}" ]]` 中的 `"${v}"` 是右側或唯一值，故需加；若是 `[[ ${v} == "target" ]]`，則左側 `${v}` 不應加引號）。
3. **Regex 或 Pattern 匹配的右側 (Pattern Matching / Wildcards)**：
   - 在條件測試右側，若需要使用 Wildcards 或正則表達式，**絕對不加**雙引號，否則匹配會降級為字面值比較。
4. **特殊系統變數**：
   - 一位數的特殊系統變數（如 `$1` 至 `$9`、`$#`、`$*`、`$@`、`$?`、`$$`）在無後續字元拼接、且作為單獨參數傳入已包裝的防禦性函式時，允許省略 `{}`，直接寫 `$1`、`$#` 等。超過一位數（如 `${10}`）則必須加花括號。
5. **case ... in 選項模式 (Case Patterns)**：
   - 因支持萬用字元與正則，模式選項**絕對不加**雙引號。

```bash
# 特殊與例外情境範例 (Exceptions & Special Cases)
case "${os_id^^}" in
    DEBIAN) cat /etc/debian_version ;; # 選項不加雙引號
    *) io::txt "${VERSION_ID}" ;;
esac
```

---

## 4. 條件子與 C 風格運算 (Conditionals & Operators)

### 4.1 雙中括號保護 (Double Brackets)

- 對於非純數值條件評估，一律使用 `[[ ... ]]` 取代動態拆分且存在安全漏洞的 `[ ... ]`。

### 4.2 嚴格 C 風格數值運算 (C-Style Arithmetic)

- 數值條件評估必須使用雙小括號 `(( ... ))`；數值賦值必須使用 `$(( ... ))`。
- **絕對禁用** `-eq`, `-ne`, `-gt`, `-ge`, `-lt`, `-le`。一律採用符號運算子：`==`, `!=`, `>`, `>=`, `<`, `<=`。

---

## 5. 邏輯控制流與縮寫限制 (Control Flow & Guard Limits)

### 5.1 衛語句縮寫規範 (Guard Clauses)

- 允許使用簡短的 `&&` 或 `||` 代替單一指令的 `if` 判斷（例如：`(($# == 0)) && return 2`）。
- **極致安全硬性要求**：**絕對不允許**出現 `&& { ... }` 或 `|| { ... }` 等複合命令塊的邏輯縮寫！
- 實務上，複合命令塊在遭遇其中某個子指令失敗時，會發生極難排查的控制流偏轉與靜默崩潰。若需執行複合任務，一律改用 `if ... fi` 或 `case ... in`。

```bash
# 正確 (Correct)
if ! fs::file_exist /etc/resolv.conf; then
    io::err "找不到 DNS 設定檔"
    return 1
fi

# 錯誤 (Incorrect) - 嚴禁在邏輯縮寫中使用複合大括號
fs::file_exist /etc/resolv.conf || { io::err "找不到 DNS 設定檔" && return 1; }
```

---

## 6. 強韌防護與安全性：主動拒絕 eval (Hardening & Rejection of eval)

### 6.1 徹底禁用 eval 運算子

在 OGOS Bash 中，**嚴厲禁止使用 `eval`** 進行任何動態程式碼執行與動態變數取值。

- `eval` 會將字串無條件解析為程式碼執行，這在接收來自網路（如 IP 偵測、城市名稱）、檔案（如設定檔）或使用者輸入時，會產生極其危險的 **Shell 命令注入 (Command Injection)** 漏洞。
- 若需要動態變數取值，一律改用：
  - **名稱參照 (Name Reference)**：`local -n ref_var="dynamic_name"`。
  - **間接展開 (Indirect Expansion)**：`${!variable_name}`。

### 6.2 主動防禦與環境硬化 (Active Hardening Environment)

為確保在腳本進入執行後，即使有第三方函式庫或被注入之程式碼，也無法呼叫 `eval` 等高危運算子，建議在核心進入點或初始化中呼叫「主動覆蓋」機制：

```bash
# 主動防禦硬化 (Active Hardening)
function sys::harden_env() {
    function eval() { false; } # 主動使 eval 失效並返回失敗
    function curl() { false; }
    function wget() { false; }
}
```

透過將 `eval()` 重新宣告為恆回傳 `false` 的局部函式，徹底從底層鎖死其執行路徑，實現真正的環境硬化 (Environment Hardening)。

---

## 7. 內嵌輔助函式與 I/O 串流規範 (Helpers & I/O Streams)

### 7.1 內嵌輔助函式 (Nested Helpers)

- 當輔助函式僅供特定主函式內部使用時，應完全將其定義在主函式之內，並以單底線 `_` 開頭命名：

  ```bash
  function str::query() {
      function _parse() {
          # ...
      }
      _parse
  }
  ```

### 7.2 零 Echo 規範 (Zero Echo Policy)

- 原生 `echo` 命令被**完全棄用**。一律使用 `io::` 命名空間所封裝的強健 I/O 函式（如 `io::txt`、`io::raw`、`io::err`、`io::err_die`），其底層完全基於 `printf`。

---

## 8. OGOS Bash 標準範本 (OGOS Template)

```bash
#!/usr/bin/env bash
# ==============================================================================
#  OGOS Bash Standard Template
#  Style Signature: Double-colon, Typed local vars, Strict braces & double quotes
# ==============================================================================

set -o pipefail
shopt -s expand_aliases

# ------------------------------------------------------------------------------
#  Global Constants & Configuration (Read-only)
# ------------------------------------------------------------------------------
readonly LANG_ENV="${LANG:-C.UTF-8}"
readonly CLR_RESET="\x1b[0m"
readonly CLR_RED="\x1b[0;31m"

# ------------------------------------------------------------------------------
#  Namespace: io (Input/Output Core)
# ------------------------------------------------------------------------------
function io::txt() { [[ -n "$*" ]] && printf "%b\n" "$*"; }
function io::err() { [[ -n "$*" ]] && printf "%b\n" "${CLR_RED}$*${CLR_RESET}" >&2; }

# ------------------------------------------------------------------------------
#  Namespace: demo (Business Domain)
# ------------------------------------------------------------------------------
function demo::query_resource() {
    local -r target_file="${1:-}"

    # 1. Guard clause (Single-line, Brackets left hand unquoted)
    [[ -n "${target_file}" ]] || return 2

    # 2. Strict if-then-fi replacing dangerous '|| { ... }'
    if [[ ! -f "${target_file}" ]]; then
        io::err "Resource file '${target_file}' does not exist!"
        return 1
    fi

    # 3. Typed local declarations (Priority order: -i > none)
    local -i count=0
    local lines=()
    local line_content

    # 4. Inline streamlined helper
    function _process_parse() {
        local -r file_path="${1}"
        # File read redirection
        mapfile -t lines <"${file_path}"
    }

    # 5. Split declaration and command substitution assignment
    local has_data
    has_data=$(wc -l <"${target_file}")

    # 6. Pure numeric contexts - No brackets, quotes or dollars
    if ((has_data > 0)); then
        _process_parse "${target_file}"
        io::txt "Successfully parsed ${#lines[@]} lines."
    fi
}

# ------------------------------------------------------------------------------
#  Execution Entry
# ------------------------------------------------------------------------------
demo::query_resource "/etc/hosts"
```
