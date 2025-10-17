import {
  defaultGroupNameForToken,
  NormalizedRegexConfig,
  RegexConfig,
  normalizeConfig,
  MatchMode,
  LengthConstraint,
} from "../config/schema";
import { EngineCapabilities, getEngineCapabilities } from "../engines";
import { escapeRegexLiteral } from "../util/escape";

export type RegexStrictness = "strict" | "standard" | "loose";

export interface RegexCandidate {
  pattern: string;
  flags: string;
  engine: NormalizedRegexConfig["engine"];
  strictness: RegexStrictness;
  notes?: string;
}

export interface RegexRetrievalResult {
  primary: RegexCandidate;
  variants: RegexCandidate[];
}

type QuantifierMode = "configured" | "unbounded";

type WrapCaptureOptions = {
  forceMode?: NormalizedRegexConfig["capture"];
  groupName?: string;
};

type WrapCaptureResult = {
  pattern: string;
  usedMode: NormalizedRegexConfig["capture"];
  note?: string;
};

export function buildRegexFromConfig(
  config: RegexConfig
): RegexRetrievalResult {
  const normalized = normalizeConfig(config);
  const capabilities = getEngineCapabilities(normalized.engine);
  const flags = deriveFlags(normalized);

  const prefixPattern = normalized.prefix
    ? escapeRegexLiteral(normalized.prefix)
    : "";
  const suffixPattern = normalized.suffix
    ? escapeRegexLiteral(normalized.suffix)
    : "";

  const configuredToken = buildTokenPattern(normalized, "configured");
  const primaryCapture = wrapCapture(configuredToken, normalized, capabilities);

  const primaryPattern = composePattern({
    prefix: prefixPattern,
    suffix: suffixPattern,
    capture: primaryCapture.pattern,
    matchMode: normalized.matchMode,
    prefixWhitespace: normalized.allowWhitespace,
    suffixWhitespace: normalized.allowWhitespace,
  });

  const primary: RegexCandidate = {
    pattern: primaryPattern,
    flags,
    engine: normalized.engine,
    strictness: "strict",
    notes: primaryCapture.note,
  };

  const variants = buildVariants({
    normalized,
    capabilities,
    flags,
    prefixPattern,
    suffixPattern,
    configuredToken,
    primary,
  });

  return { primary, variants };
}

function buildVariants(args: {
  normalized: NormalizedRegexConfig;
  capabilities: EngineCapabilities;
  flags: string;
  prefixPattern: string;
  suffixPattern: string;
  configuredToken: string;
  primary: RegexCandidate;
}): RegexCandidate[] {
  const {
    normalized,
    capabilities,
    flags,
    prefixPattern,
    suffixPattern,
    configuredToken,
    primary,
  } = args;

  const variants: RegexCandidate[] = [];
  const seen = new Set<string>([candidateKey(primary)]);

  const pushVariant = (candidate: RegexCandidate) => {
    const key = candidateKey(candidate);
    if (seen.has(key)) {
      return;
    }
    seen.add(key);
    variants.push(candidate);
  };

  const unboundedToken = buildTokenPattern(normalized, "unbounded");

  if (unboundedToken !== configuredToken) {
    const capture = wrapCapture(unboundedToken, normalized, capabilities);
    const pattern = composePattern({
      prefix: prefixPattern,
      suffix: suffixPattern,
      capture: capture.pattern,
      matchMode: normalized.matchMode,
      prefixWhitespace: normalized.allowWhitespace,
      suffixWhitespace: normalized.allowWhitespace,
    });
    pushVariant({
      pattern,
      flags,
      engine: normalized.engine,
      strictness: "standard",
      notes: capture.note ?? "Unbounded quantifier variant",
    });
  }

  const whitespaceCapture = wrapCapture(unboundedToken, normalized, capabilities);
  const whitespacePattern = composePattern({
    prefix: prefixPattern,
    suffix: suffixPattern,
    capture: whitespaceCapture.pattern,
    matchMode: normalized.matchMode,
    prefixWhitespace: true,
    suffixWhitespace: true,
  });
  pushVariant({
    pattern: whitespacePattern,
    flags,
    engine: normalized.engine,
    strictness: "loose",
    notes: whitespaceCapture.note ?? "Whitespace tolerant variant",
  });

  const namedCapture = wrapCapture(unboundedToken, normalized, capabilities, {
    forceMode: "namedGroup",
    groupName:
      normalized.groupName ?? defaultGroupNameForToken(normalized.token),
  });
  if (namedCapture.usedMode === "namedGroup") {
    const namedPattern = composePattern({
      prefix: prefixPattern,
      suffix: suffixPattern,
      capture: namedCapture.pattern,
      matchMode: normalized.matchMode,
      prefixWhitespace: normalized.allowWhitespace,
      suffixWhitespace: normalized.allowWhitespace,
    });
    pushVariant({
      pattern: namedPattern,
      flags,
      engine: normalized.engine,
      strictness: "standard",
      notes: `Named capture group '${
        normalized.groupName ?? defaultGroupNameForToken(normalized.token)
      }' variant`,
    });
  }

  const hasPrefix = Boolean(normalized.prefix);
  const hasSuffix = Boolean(normalized.suffix);

  if (
    normalized.matchMode === "contains" &&
    hasPrefix &&
    hasSuffix &&
    capabilities.lookbehind
  ) {
    const lookbehind = `(?<=${prefixPattern})`;
    const lookahead = `(?=${suffixPattern})`;
    const lookaroundPattern = `${lookbehind}${unboundedToken}${lookahead}`;
    pushVariant({
      pattern: lookaroundPattern,
      flags,
      engine: normalized.engine,
      strictness: "standard",
      notes: "Lookaround capture variant",
    });
  }

  if (normalized.lookaround === "lookbehind" && hasPrefix && capabilities.lookbehind) {
    const pattern = `(?<=${prefixPattern})${unboundedToken}`;
    pushVariant({
      pattern,
      flags,
      engine: normalized.engine,
      strictness: "standard",
      notes: "Lookbehind capture variant",
    });
  }

  if (normalized.lookaround === "lookahead" && hasSuffix) {
    const pattern = `${unboundedToken}(?=${suffixPattern})`;
    pushVariant({
      pattern,
      flags,
      engine: normalized.engine,
      strictness: "standard",
      notes: "Lookahead capture variant",
    });
  }

  if (
    normalized.capture === "lookaroundCapture" &&
    hasPrefix &&
    hasSuffix &&
    capabilities.lookbehind
  ) {
    const pattern = `(?<=${prefixPattern})${unboundedToken}(?=${suffixPattern})`;
    pushVariant({
      pattern,
      flags,
      engine: normalized.engine,
      strictness: "standard",
      notes: "Lookaround-only capture variant",
    });
  }

  return variants;
}

function candidateKey(candidate: RegexCandidate): string {
  return `${candidate.engine}::${candidate.flags}::${candidate.pattern}`;
}

function composePattern(args: {
  prefix: string;
  suffix: string;
  capture: string;
  matchMode: MatchMode;
  prefixWhitespace: boolean;
  suffixWhitespace: boolean;
}): string {
  const { prefix, suffix, capture, matchMode, prefixWhitespace, suffixWhitespace } =
    args;

  const prefixSegment = prefixWhitespace
    ? prefix
      ? `${prefix}\\s*`
      : "\\s*"
    : prefix;
  const suffixSegment = suffixWhitespace
    ? suffix
      ? `\\s*${suffix}`
      : "\\s*"
    : suffix;
  const body = `${prefixSegment}${capture}${suffixSegment}`;
  return applyMatchMode(body, matchMode);
}

function applyMatchMode(body: string, matchMode: MatchMode): string {
  if (matchMode === "full" || matchMode === "line") {
    return `^${body}$`;
  }
  return body;
}

function wrapCapture(
  core: string,
  normalized: NormalizedRegexConfig,
  capabilities: EngineCapabilities,
  options: WrapCaptureOptions = {}
): WrapCaptureResult {
  const mode = options.forceMode ?? normalized.capture;

  switch (mode) {
    case "namedGroup": {
      const groupName =
        options.groupName ??
        normalized.groupName ??
        defaultGroupNameForToken(normalized.token);
      if (capabilities.namedGroups) {
        return {
          pattern: `(?<${groupName}>${core})`,
          usedMode: "namedGroup",
        };
      }
      if (normalized.safeMode) {
        return {
          pattern: `(${core})`,
          usedMode: "group",
          note: `Named groups not supported by engine ${normalized.engine}; downgraded to capturing group`,
        };
      }
      return {
        pattern: `(?<${groupName}>${core})`,
        usedMode: "namedGroup",
      };
    }
    case "nonCapturing":
      return {
        pattern: `(?:${core})`,
        usedMode: "nonCapturing",
      };
    case "lookaroundCapture":
      return {
        pattern: `(${core})`,
        usedMode: "group",
        note: "Lookaround capture requested; falling back to capturing group",
      };
    case "group":
    default:
      return {
        pattern: `(${core})`,
        usedMode: "group",
      };
  }
}

function deriveFlags(normalized: NormalizedRegexConfig): string {
  const flagSet = new Set(normalized.flags.split("").filter(Boolean));
  if (normalized.charset === "unicode") {
    flagSet.add("u");
  }
  if (normalized.matchMode === "line") {
    flagSet.add("m");
  }
  return Array.from(flagSet).sort().join("");
}

function buildTokenPattern(
  normalized: NormalizedRegexConfig,
  mode: QuantifierMode
): string {
  switch (normalized.token) {
    case "digits":
      return applyQuantifier("\\d", normalized.length, normalized.quantifierTightness, mode);
    case "word":
      return applyQuantifier("\\w", normalized.length, normalized.quantifierTightness, mode);
    case "alnum":
      return applyQuantifier("[A-Za-z0-9]", normalized.length, normalized.quantifierTightness, mode);
    case "customClass":
      return applyQuantifier(
        normalized.customClass ?? ".",
        normalized.length,
        normalized.quantifierTightness,
        mode
      );
    case "number":
      return "[-+]?\\d+(?:\\.\\d+)?";
    default:
      return applyQuantifier(".", normalized.length, normalized.quantifierTightness, mode);
  }
}

function applyQuantifier(
  base: string,
  length: LengthConstraint | undefined,
  tightness: NormalizedRegexConfig["quantifierTightness"],
  mode: QuantifierMode
): string {
  if (mode === "unbounded") {
    return `${base}+`;
  }

  if (length?.exact !== undefined) {
    return `${base}{${length.exact}}`;
  }

  const hasMin = length?.min !== undefined;
  const hasMax = length?.max !== undefined;

  if (hasMin && hasMax) {
    return `${base}{${length!.min},${length!.max}}`;
  }

  if (hasMin) {
    return `${base}{${length!.min},}`;
  }

  if (hasMax) {
    return `${base}{0,${length!.max}}`;
  }

  if (tightness === "loose") {
    return `${base}*`;
  }

  return `${base}+`;
}
