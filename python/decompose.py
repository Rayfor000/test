# Copyright (C) 2026.
"""
Minecraft-style block/item localization key decomposition and reverse-apply tool.

Supported key format:
    <domain>.<namespace>.<local_name>
    where domain is restricted to 'block' or 'item', and local_name may
    itself contain dots (treated identically to underscores as token
    boundaries).

Two operating modes:
    analyze - Decompose a flat key:value dictionary into token-level and
              compound-level meanings, WITHOUT relying on any built-in
              dictionary. Also emits an exact-key index and a
              namespace-agnostic local-key index for later reverse lookup.
    apply   - Given a previously produced analyze report (or a fresh
              source corpus) plus a target file of untranslated
              key:value pairs, reconstruct translations by:
                1. Exact full-key match against the learned corpus.
                2. Exact local-key match ignoring namespace.
                3. Greedy longest-n-gram token composition, falling back
                   to the raw target value's positionally-aligned word
                   for any token that remains unresolved.

Limitations:
    - Token composition assumes the target value's whitespace-separated
      word count equals the local key's token count. Reordered or
      non-literal translations break this alignment and fall back to a
      capitalized literal instead of guessing.
    - local_key collisions across different namespaces are resolved by
      majority vote, not per-namespace context.

Usage:
    uv run decompose.py analyze source.json -o output.json
    uv run decompose.py apply --source source.json target.json -o result.json --report diagnosis.json
"""

from __future__ import annotations

import argparse
import itertools
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from difflib import SequenceMatcher
from pathlib import Path

Tokens = tuple[str, ...]

# ---------------------------------------------------------------------------
# Configuration defaults
# ---------------------------------------------------------------------------
DEFAULT_MIN_CONFIDENCE = 0.5
DEFAULT_BOOTSTRAP_ROUNDS = 3
DEFAULT_BOOTSTRAP_MIN_CONFIDENCE = 0.75
DEFAULT_BOOTSTRAP_MIN_EVIDENCE = 2
DEFAULT_APPLY_MIN_CONFIDENCE = 0.6
MAX_SOURCE_SAMPLES = 5
MIN_SYNONYM_GROUP = 2

SUPPORTED_DOMAINS = ("block", "item")
FULL_KEY_PATTERN = re.compile(r"^(" + "|".join(SUPPORTED_DOMAINS) + r")\.([^.]+)\.(.+)$")
LOCAL_SPLIT_PATTERN = re.compile(r"[._]+")
HAN_PATTERN = re.compile(r"[\u4e00-\u9fff]")


# ---------------------------------------------------------------------------
# Key parsing
# ---------------------------------------------------------------------------
def tokenize_full_key(key: str) -> tuple[str, str, str, Tokens] | None:
    """
    Parse a full localization key.

    Accepts '<domain>.<namespace>.<local_name>'; local_name may contain
    dots, which are treated as token boundaries equivalent to
    underscores.

    Returns:
        The (domain, namespace, local_key, tokens) tuple, or None if the
        key does not match the supported format.

    """
    match = FULL_KEY_PATTERN.match(key)
    if not match:
        return None
    domain, namespace, local_key = match.groups()
    tokens = tuple(part for part in LOCAL_SPLIT_PATTERN.split(local_key) if part)
    if not tokens:
        return None
    return domain, namespace, local_key, tokens


@dataclass(frozen=True)
class Entry:
    """One supported key:value pair with its parsed decomposition."""

    tokens: Tokens
    value: str
    key: str
    domain: str
    namespace: str
    local_key: str


def build_entries(data: dict[str, str]) -> tuple[list[Entry], list[str]]:
    """
    Split the raw input into supported entries and skipped keys.

    Returns:
        A (entries, skipped_keys) pair.

    """
    entries: list[Entry] = []
    skipped: list[str] = []
    for key, value in data.items():
        parsed = tokenize_full_key(key)
        if parsed is None:
            skipped.append(key)
            continue
        domain, namespace, local_key, tokens = parsed
        entries.append(Entry(tokens, value, key, domain, namespace, local_key))
    return entries, skipped


# ---------------------------------------------------------------------------
# String / token alignment primitives
# ---------------------------------------------------------------------------
def longest_common_substring(a: str, b: str) -> str:
    """Return the longest substring shared by ``a`` and ``b``."""
    matcher = SequenceMatcher(a=a, b=b, autojunk=False)
    match = matcher.find_longest_match(0, len(a), 0, len(b))
    return a[match.a : match.a + match.size] if match.size else ""


def remove_first_occurrence(source: str, substring: str) -> str:
    """Remove the first occurrence of ``substring`` from ``source``."""
    if not substring:
        return source
    idx = source.find(substring)
    return source if idx == -1 else source[:idx] + source[idx + len(substring) :]


def partition_tokens(tokens_a: Tokens, tokens_b: Tokens) -> tuple[Tokens, Tokens, Tokens]:
    """
    Split two token sequences into their differing parts.

    Returns:
        A (shared, only_in_a, only_in_b) triple, order preserved.

    """
    matcher = SequenceMatcher(a=list(tokens_a), b=list(tokens_b), autojunk=False)
    shared: list[str] = []
    only_a: list[str] = []
    only_b: list[str] = []
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            shared.extend(tokens_a[i1:i2])
        else:
            only_a.extend(tokens_a[i1:i2])
            only_b.extend(tokens_b[j1:j2])
    return tuple(shared), tuple(only_a), tuple(only_b)


# ---------------------------------------------------------------------------
# Evidence collection (unsupervised alignment)
# ---------------------------------------------------------------------------
EvidenceMap = dict[Tokens, Counter]
SourceMap = dict[Tokens, list[str]]


def add_evidence(evidence: EvidenceMap, sources: SourceMap, ngram: Tokens, chunk: str, source_note: str) -> None:
    """Record one observed (ngram -> chunk) vote with its source note."""
    if not ngram or not chunk:
        return
    evidence[ngram][chunk] += 1
    sources[ngram].append(source_note)


def collect_self_evidence(entries: list[Entry], evidence: EvidenceMap, sources: SourceMap) -> None:
    """Let every entry vote for its own full token tuple -> full value mapping."""
    for entry in entries:
        add_evidence(evidence, sources, entry.tokens, entry.value, f"self:{entry.key}")


def build_token_index(entries: list[Entry]) -> dict[str, list[int]]:
    """Build a token -> entry-indices inverted index."""
    index: dict[str, list[int]] = defaultdict(list)
    for idx, entry in enumerate(entries):
        for token in set(entry.tokens):
            index[token].append(idx)
    return index


def collect_pairwise_evidence(entries: list[Entry], evidence: EvidenceMap, sources: SourceMap) -> None:
    """
    Compare entries sharing at least one token.

    Isolate the shared token group and the two differing token groups,
    then derive candidate meanings via longest-common-substring
    extraction on the values.
    """
    index = build_token_index(entries)
    candidate_pairs = set()
    for indices in index.values():
        for i, j in itertools.combinations(sorted(set(indices)), 2):
            candidate_pairs.add((i, j))

    for i, j in candidate_pairs:
        entry_a, entry_b = entries[i], entries[j]
        shared, only_a, only_b = partition_tokens(entry_a.tokens, entry_b.tokens)

        if shared:
            common = longest_common_substring(entry_a.value, entry_b.value)
            if not common:
                continue  # cannot safely separate meaning; skip rather than guess
            add_evidence(evidence, sources, shared, common, f"shared:{entry_a.key}<->{entry_b.key}")
            remainder_a = remove_first_occurrence(entry_a.value, common)
            remainder_b = remove_first_occurrence(entry_b.value, common)
        else:
            remainder_a = entry_a.value
            remainder_b = entry_b.value

        if only_a:
            add_evidence(evidence, sources, only_a, remainder_a, f"diff:{entry_a.key}<->{entry_b.key}")
        if only_b:
            add_evidence(evidence, sources, only_b, remainder_b, f"diff:{entry_a.key}<->{entry_b.key}")


def resolved_ngrams_snapshot(evidence: EvidenceMap, min_confidence: float, min_evidence: int) -> dict[Tokens, str]:
    """Return the subset of ngrams already resolved with high confidence."""
    resolved = {}
    for ngram, counter in evidence.items():
        total = sum(counter.values())
        if total < min_evidence:
            continue
        chunk, count = counter.most_common(1)[0]
        if count / total >= min_confidence:
            resolved[ngram] = chunk
    return resolved


def _subtract_known_span(  # noqa: PLR0913, PLR0917
    entry: Entry,
    remaining_tokens: list[str],
    remaining_value: str,
    start: int,
    span_len: int,
    resolved: dict[Tokens, str],
    evidence: EvidenceMap,
    sources: SourceMap,
) -> tuple[list[str], str, bool, bool]:
    """
    Subtract one resolved span from an entry's remaining tokens/value.

    Returns:
        A (tokens, value, changed, progressed) tuple.

    """
    span = tuple(remaining_tokens[start : start + span_len])
    if span not in resolved:
        return remaining_tokens, remaining_value, False, False
    chunk = resolved[span]
    if chunk not in remaining_value:
        return remaining_tokens, remaining_value, False, False

    rest = tuple(remaining_tokens[:start] + remaining_tokens[start + span_len :])
    new_value = remove_first_occurrence(remaining_value, chunk)
    progressed = False
    if rest and new_value:
        before = sum(evidence[rest].values())
        add_evidence(evidence, sources, rest, new_value, f"bootstrap:{entry.key} (after removing '{chunk}')")
        progressed = sum(evidence[rest].values()) > before

    tokens = remaining_tokens[:start] + remaining_tokens[start + span_len :]
    return tokens, new_value, True, progressed


def _bootstrap_entry(entry: Entry, evidence: EvidenceMap, sources: SourceMap, resolved: dict[Tokens, str]) -> bool:
    """
    Run iterative subtraction against a single entry until it stabilizes.

    Returns:
        Whether any new evidence was produced for this entry.

    """
    progressed = False
    remaining_tokens: list[str] = list(entry.tokens)
    remaining_value = entry.value
    while True:
        changed, sub_progressed = _try_subtract_once(entry, remaining_tokens, remaining_value, evidence, sources, resolved)
        if not changed:
            break
        progressed = progressed or sub_progressed
    return progressed


def _try_subtract_once(  # noqa: PLR0913, PLR0917
    entry: Entry,
    remaining_tokens: list[str],
    remaining_value: str,
    evidence: EvidenceMap,
    sources: SourceMap,
    resolved: dict[Tokens, str],
) -> tuple[bool, bool]:
    """
    Try to subtract the longest resolvable span from one entry.

    Returns:
        A (changed, progressed) pair. ``changed`` marks whether the
        entry's remaining tokens/value were mutated this pass.

    """
    total_len = len(remaining_tokens)
    for span_len in range(total_len - 1, 0, -1):
        for start in range(total_len - span_len + 1):
            tokens, value, matched, sub_progressed = _subtract_known_span(entry, remaining_tokens, remaining_value, start, span_len, resolved, evidence, sources)
            if matched:
                remaining_tokens.clear()
                remaining_tokens.extend(tokens)
                remaining_value = value
                return True, sub_progressed
    return False, False


def _bootstrap_pass(entries: list[Entry], evidence: EvidenceMap, sources: SourceMap, resolved: dict[Tokens, str]) -> bool:
    """Run one bootstrap subtraction pass over all entries."""
    progressed = False
    for entry in entries:
        # Keep subtracting the longest known spans until the entry stabilizes.
        while _bootstrap_entry(entry, evidence, sources, resolved):
            progressed = True
    return progressed


def bootstrap_refine(  # noqa: PLR0913, PLR0917
    entries: list[Entry],
    evidence: EvidenceMap,
    sources: SourceMap,
    rounds: int,
    min_confidence: float,
    min_evidence: int,
) -> None:
    """Subtract high-confidence known meanings to expose remaining token groups."""
    for _ in range(rounds):
        resolved = resolved_ngrams_snapshot(evidence, min_confidence, min_evidence)
        if not resolved:
            break

        if not _bootstrap_pass(entries, evidence, sources, resolved):
            break


# ---------------------------------------------------------------------------
# Resolution & report assembly
# ---------------------------------------------------------------------------
def _build_record(ngram: Tokens, counter: Counter, sources: SourceMap, min_confidence: float) -> dict:
    """Build one report record for an ngram evidence counter."""
    total = sum(counter.values())
    best_chunk, best_count = counter.most_common(1)[0]
    confidence = round(best_count / total, 3)

    record: dict[str, object] = {
        "meaning": best_chunk if confidence >= min_confidence else None,
        "confidence": confidence,
        "evidence_count": total,
        "candidates": dict(counter),
        "source_count": len(sources[ngram]),
        "sources_sample": sorted(set(sources[ngram]))[:MAX_SOURCE_SAMPLES],
    }
    if confidence < min_confidence:
        record["note"] = "insufficient consensus across sources; manual review suggested"
    return record


def resolve_all(evidence: EvidenceMap, sources: SourceMap, min_confidence: float) -> tuple[dict, dict]:
    """
    Convert the raw evidence maps into report records.

    Returns:
        A (tokens_result, compounds_result) pair.

    """
    tokens_result: dict = {}
    compounds_result: dict = {}

    for ngram in sorted(evidence.keys(), key=lambda t: (len(t), t)):
        record = _build_record(ngram, evidence[ngram], sources, min_confidence)
        key_str = "_".join(ngram)
        if len(ngram) == 1:
            tokens_result[key_str] = record
            continue

        components = list(ngram)
        splittable = all(comp in tokens_result and tokens_result[comp]["meaning"] for comp in components)
        record["components"] = components
        record["splittable"] = splittable
        if splittable and record["meaning"]:
            concatenation = "".join(tokens_result[c]["meaning"] for c in components)
            record["consistency_check"] = {
                "component_concatenation": concatenation,
                "matches_whole_meaning": concatenation == record["meaning"],
            }
        compounds_result[key_str] = record

    return tokens_result, compounds_result


def find_never_isolated_tokens(entries: list[Entry], tokens_result: dict) -> list[str]:
    """List tokens that never appeared as an isolated single-token ngram."""
    all_tokens = set()
    for entry in entries:
        all_tokens.update(entry.tokens)
    return sorted(t for t in all_tokens if t not in tokens_result)


def find_synonym_groups(entries: list[Entry]) -> list[dict]:
    """Group keys that map to an identical value string."""
    value_map: dict[str, list[Entry]] = defaultdict(list)
    for entry in entries:
        value_map[entry.value].append(entry)

    groups = []
    for value, items in value_map.items():
        if len(items) < MIN_SYNONYM_GROUP:
            continue
        token_sets = [set(entry.tokens) for entry in items]
        shares_tokens = any(token_sets[i] & token_sets[j] for i, j in itertools.combinations(range(len(token_sets)), 2))
        groups.append(
            {
                "value": value,
                "keys": [entry.key for entry in items],
                "keys_share_tokens": shares_tokens,
            }
        )
    return groups


def build_exact_index(entries: list[Entry]) -> dict[str, str]:
    """Build a full key -> value index for exact reverse lookup."""
    return {entry.key: entry.value for entry in entries}


def build_local_index(entries: list[Entry]) -> dict[str, dict]:
    """Build a (domain.local_key) -> majority-vote value index."""
    grouped: dict[str, Counter] = defaultdict(Counter)
    for entry in entries:
        grouped[f"{entry.domain}.{entry.local_key}"][entry.value] += 1

    result = {}
    for lookup_key, counter in grouped.items():
        total = sum(counter.values())
        value, count = counter.most_common(1)[0]
        result[lookup_key] = {
            "meaning": value,
            "confidence": round(count / total, 3),
            "variants": dict(counter),
        }
    return result


def build_combined_ngram_map(tokens_result: dict, compounds_result: dict) -> dict[Tokens, dict]:
    """Merge tokens and compounds into a single Tokens -> record map."""
    combined: dict[Tokens, dict] = {}
    for key_str, record in {**tokens_result, **compounds_result}.items():
        if not record.get("meaning"):
            continue
        combined[tuple(key_str.split("_"))] = {
            "meaning": record["meaning"],
            "confidence": record["confidence"],
        }
    return combined


def analyze_core(
    data: dict[str, str],
    min_confidence: float,
    bootstrap_rounds: int,
    bootstrap_min_confidence: float,
    bootstrap_min_evidence: int,
) -> dict:
    """
    Run the full analyze pipeline on a raw key:value corpus.

    Returns:
        The internal core dict consumed by report/apply builders.

    """
    entries, skipped_keys = build_entries(data)

    evidence: EvidenceMap = defaultdict(Counter)
    sources: SourceMap = defaultdict(list)

    collect_self_evidence(entries, evidence, sources)
    collect_pairwise_evidence(entries, evidence, sources)
    bootstrap_refine(entries, evidence, sources, bootstrap_rounds, bootstrap_min_confidence, bootstrap_min_evidence)

    tokens_result, compounds_result = resolve_all(evidence, sources, min_confidence)

    return {
        "entries": entries,
        "tokens_result": tokens_result,
        "compounds_result": compounds_result,
        "combined_map": build_combined_ngram_map(tokens_result, compounds_result),
        "exact_index": build_exact_index(entries),
        "local_index": build_local_index(entries),
        "skipped_keys": skipped_keys,
    }


def build_analyze_report(core: dict) -> dict:
    """
    Assemble the user-facing analyze report from a core dict.

    Returns:
        The serializable report payload.

    """
    entries = core["entries"]
    tokens_result = core["tokens_result"]
    compounds_result = core["compounds_result"]

    return {
        "meta": {
            "total_entries": len(entries),
            "skipped_keys_count": len(core["skipped_keys"]),
            "resolved_tokens": sum(1 for r in tokens_result.values() if r["meaning"]),
            "ambiguous_tokens": sum(1 for r in tokens_result.values() if not r["meaning"]),
            "resolved_compounds": sum(1 for r in compounds_result.values() if r["meaning"]),
            "tokens_never_isolated": find_never_isolated_tokens(entries, tokens_result),
        },
        "tokens": tokens_result,
        "compounds": compounds_result,
        "exact_index": core["exact_index"],
        "local_index": core["local_index"],
        "synonym_groups": find_synonym_groups(entries),
        "skipped_keys": core["skipped_keys"],
    }


# ---------------------------------------------------------------------------
# Apply mode: reverse translation of a new (untranslated) file
# ---------------------------------------------------------------------------
def load_dictionary_from_report(path: str) -> dict:
    """Reconstruct combined_map / exact_index / local_index from an analyze report."""
    with Path(path).open(encoding="utf-8") as handle:
        report = json.load(handle)
    return {
        "combined_map": build_combined_ngram_map(report.get("tokens", {}), report.get("compounds", {})),
        "exact_index": report.get("exact_index", {}),
        "local_index": report.get("local_index", {}),
    }


def get_dictionary_for_apply(args: argparse.Namespace) -> dict:
    """Load (or freshly analyze) the dictionary needed by apply mode."""
    if args.dictionary:
        return load_dictionary_from_report(args.dictionary)

    source_data = load_input(args.source)
    core = analyze_core(
        source_data,
        min_confidence=args.min_confidence,
        bootstrap_rounds=args.bootstrap_rounds,
        bootstrap_min_confidence=args.bootstrap_min_confidence,
        bootstrap_min_evidence=args.bootstrap_min_evidence,
    )
    return {
        "combined_map": core["combined_map"],
        "exact_index": core["exact_index"],
        "local_index": core["local_index"],
    }


def is_han(text: str) -> bool:
    """Return True if the text contains any Han characters."""
    return bool(HAN_PATTERN.search(text))


def join_segments(segments: list[str]) -> str:
    """Concatenate segments, inserting a space at any Han <-> non-Han boundary."""
    result = ""
    prev_is_han: bool | None = None
    for seg in segments:
        if not seg:
            continue
        cur_is_han = is_han(seg)
        if result and not (prev_is_han and cur_is_han):
            result += " "
        result += seg
        prev_is_han = cur_is_han
    return result


def compose_translation(tokens: Tokens, raw_value: str, combined_map: dict[Tokens, dict], min_confidence: float) -> tuple[str, list[str], list[float]]:
    """
    Greedily segment tokens using the longest known n-gram match first.

    Unresolved tokens fall back to the positionally-aligned word from
    the raw target value (if word count matches token count), otherwise
    to a capitalized literal of the token itself.

    Returns:
        A (translation, unresolved_tokens, confidences) triple.

    """
    words = raw_value.split()
    positional_fallback_valid = len(words) == len(tokens)

    segments: list[str] = []
    unresolved: list[str] = []
    confidences: list[float] = []

    i = 0
    n = len(tokens)
    while i < n:
        matched = False
        for span in range(n - i, 0, -1):
            ngram = tokens[i : i + span]
            record = combined_map.get(ngram)
            if record and record["confidence"] >= min_confidence:
                segments.append(record["meaning"])
                confidences.append(record["confidence"])
                i += span
                matched = True
                break
        if not matched:
            literal = words[i] if positional_fallback_valid else tokens[i].capitalize()
            segments.append(literal)
            unresolved.append(tokens[i])
            i += 1

    return join_segments(segments), unresolved, confidences


def apply_translations(target_data: dict[str, str], dictionary: dict, min_confidence: float) -> tuple[dict[str, str], list[dict]]:
    """
    Translate a target key:value file using a learned dictionary.

    Returns:
        A (result_map, report_entries) pair.

    """
    combined_map = dictionary["combined_map"]
    exact_index = dictionary["exact_index"]
    local_index = dictionary["local_index"]

    result: dict[str, str] = {}
    report: list[dict] = []

    for key, raw_value in target_data.items():
        parsed = tokenize_full_key(key)
        if parsed is None:
            result[key] = raw_value
            report.append({"key": key, "match_type": "passthrough_unsupported_format"})
            continue

        domain, _namespace, local_key, tokens = parsed

        if key in exact_index:
            result[key] = exact_index[key]
            report.append({"key": key, "match_type": "exact_full_key", "confidence": 1.0})
            continue

        local_lookup_key = f"{domain}.{local_key}"
        if local_lookup_key in local_index:
            record = local_index[local_lookup_key]
            result[key] = record["meaning"]
            report.append(
                {
                    "key": key,
                    "match_type": "exact_local_namespace_agnostic",
                    "confidence": record["confidence"],
                }
            )
            continue

        translated, unresolved, confidences = compose_translation(tokens, raw_value, combined_map, min_confidence)
        result[key] = translated
        report.append(
            {
                "key": key,
                "match_type": "composed" if len(unresolved) < len(tokens) else "unresolved_literal",
                "tokens": list(tokens),
                "unresolved_tokens": unresolved,
                "confidence": round(min(confidences), 3) if confidences else 0.0,
            }
        )

    return result, report


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
DEMO_DATASETS = {
    "spawn_egg": {
        "item.minecraft.cow_spawn_egg": "母牛生怪蛋",
        "item.minecraft.ox_spawn_egg": "公牛生怪蛋",
        "item.minecraft.pig_spawn_egg": "豬生怪蛋",
    },
    "material_block": {
        "block.minecraft.grass_block": "草地",
        "block.minecraft.gold_block": "黃金方塊",
        "item.minecraft.gold_ingot": "金錠",
        "item.minecraft.golden_sword": "金劍",
    },
}


def load_input(path: str | None) -> dict[str, str]:
    """Load a flat key:value JSON corpus from a file path or stdin."""
    if path is None:
        raw = sys.stdin.read()
    else:
        with Path(path).open(encoding="utf-8") as handle:
            raw = handle.read()
    return json.loads(raw)


def write_json(payload: object, path: str | None) -> None:
    """
    Write payload as JSON to the given file path.

    When ``path`` is None, the payload is serialized and dropped; callers
    in write-to-stdout contexts should print the returned text instead.
    """
    if not path:
        return
    text = json.dumps(payload, ensure_ascii=False, indent=2)
    with Path(path).open("w", encoding="utf-8") as handle:
        handle.write(text)


def run_analyze(args: argparse.Namespace) -> None:
    """Execute the analyze subcommand."""
    data = DEMO_DATASETS[args.demo] if args.demo else load_input(args.input)
    core = analyze_core(
        data,
        min_confidence=args.min_confidence,
        bootstrap_rounds=args.bootstrap_rounds,
        bootstrap_min_confidence=args.bootstrap_min_confidence,
        bootstrap_min_evidence=args.bootstrap_min_evidence,
    )
    write_json(build_analyze_report(core), args.output)


def run_apply(args: argparse.Namespace) -> None:
    """Execute the apply subcommand."""
    dictionary = get_dictionary_for_apply(args)
    target_data = load_input(args.target)
    result, report = apply_translations(target_data, dictionary, args.min_confidence)
    write_json(result, args.output)
    if args.report:
        write_json(report, args.report)


def main() -> None:
    """Parse CLI arguments and dispatch to the selected subcommand."""
    parser = argparse.ArgumentParser(description="Analyze block/item localization keys, or apply a learned dictionary to a new file.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    analyze_parser = subparsers.add_parser("analyze", help="Decompose key:value pairs into token-level meanings.")
    analyze_parser.add_argument("input", nargs="?", help="Path to input JSON file (defaults to stdin).")
    analyze_parser.add_argument("-o", "--output", help="Path to output JSON file (defaults to stdout).")
    analyze_parser.add_argument("--min-confidence", type=float, default=DEFAULT_MIN_CONFIDENCE)
    analyze_parser.add_argument("--bootstrap-rounds", type=int, default=DEFAULT_BOOTSTRAP_ROUNDS)
    analyze_parser.add_argument("--bootstrap-min-confidence", type=float, default=DEFAULT_BOOTSTRAP_MIN_CONFIDENCE)
    analyze_parser.add_argument("--bootstrap-min-evidence", type=int, default=DEFAULT_BOOTSTRAP_MIN_EVIDENCE)
    analyze_parser.add_argument("--demo", choices=sorted(DEMO_DATASETS))

    apply_parser = subparsers.add_parser("apply", help="Translate a new file using a learned dictionary.")
    dict_source = apply_parser.add_mutually_exclusive_group(required=True)
    dict_source.add_argument("--dictionary", help="Path to a JSON file previously produced by 'analyze'.")
    dict_source.add_argument("--source", help="Path to a raw source corpus JSON to analyze on the fly.")
    apply_parser.add_argument("target", help="Path to the target JSON file containing keys to translate.")
    apply_parser.add_argument("-o", "--output", required=True, help="Path to write the translated flat JSON.")
    apply_parser.add_argument("--report", help="Optional path to write a detailed diagnostic report JSON.")
    apply_parser.add_argument("--min-confidence", type=float, default=DEFAULT_APPLY_MIN_CONFIDENCE)
    apply_parser.add_argument("--bootstrap-rounds", type=int, default=DEFAULT_BOOTSTRAP_ROUNDS)
    apply_parser.add_argument("--bootstrap-min-confidence", type=float, default=DEFAULT_BOOTSTRAP_MIN_CONFIDENCE)
    apply_parser.add_argument("--bootstrap-min-evidence", type=int, default=DEFAULT_BOOTSTRAP_MIN_EVIDENCE)

    args = parser.parse_args()
    if args.command == "analyze":
        run_analyze(args)
    elif args.command == "apply":
        run_apply(args)


if __name__ == "__main__":
    main()
