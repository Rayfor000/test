export type MatchMode = "contains" | "line" | "full";
export type LookaroundMode = "none" | "lookahead" | "lookbehind";
export type CaptureMode =
  | "group"
  | "namedGroup"
  | "nonCapturing"
  | "lookaroundCapture";
export type TokenType =
  | "digits"
  | "number"
  | "word"
  | "alnum"
  | "customClass";
export interface LengthConstraint {
  exact?: number;
  min?: number;
  max?: number;
}
export type CharsetOption = "ascii" | "unicode";
export type QuantifierTightness = "strict" | "normal" | "loose";
export type EngineType = "JS" | "PCRE";

export interface RegexConfig {
  matchMode?: MatchMode;
  prefix?: string;
  suffix?: string;
  lookaround?: LookaroundMode;
  capture?: CaptureMode;
  groupName?: string;
  token?: TokenType;
  customClass?: string;
  length?: LengthConstraint;
  allowWhitespace?: boolean;
  charset?: CharsetOption;
  quantifierTightness?: QuantifierTightness;
  engine?: EngineType;
  flags?: string;
  safeMode?: boolean;
}

export type NormalizedRegexConfig = RegexConfig & {
  matchMode: MatchMode;
  lookaround: LookaroundMode;
  capture: CaptureMode;
  token: TokenType;
  allowWhitespace: boolean;
  charset: CharsetOption;
  quantifierTightness: QuantifierTightness;
  engine: EngineType;
  flags: string;
  safeMode: boolean;
};

const DEFAULTS: Required<
  Pick<
    RegexConfig,
    | "matchMode"
    | "lookaround"
    | "capture"
    | "token"
    | "allowWhitespace"
    | "charset"
    | "quantifierTightness"
    | "engine"
    | "flags"
    | "safeMode"
  >
> = {
  matchMode: "full",
  lookaround: "none",
  capture: "group",
  token: "digits",
  allowWhitespace: false,
  charset: "ascii",
  quantifierTightness: "normal",
  engine: "JS",
  flags: "",
  safeMode: true,
};

export function defaultGroupNameForToken(token: TokenType): string {
  switch (token) {
    case "digits":
      return "num";
    case "number":
      return "number";
    case "word":
      return "word";
    case "alnum":
      return "alnum";
    case "customClass":
    default:
      return "value";
  }
}

export function normalizeConfig(config: RegexConfig): NormalizedRegexConfig {
  const matchMode = config.matchMode ?? DEFAULTS.matchMode;
  const lookaround = config.lookaround ?? DEFAULTS.lookaround;
  const capture = config.capture ?? DEFAULTS.capture;
  const token = config.token ?? DEFAULTS.token;
  const allowWhitespace = config.allowWhitespace ?? DEFAULTS.allowWhitespace;
  const charset = config.charset ?? DEFAULTS.charset;
  const quantifierTightness =
    config.quantifierTightness ?? DEFAULTS.quantifierTightness;
  const engine = config.engine ?? DEFAULTS.engine;
  const safeMode = config.safeMode ?? DEFAULTS.safeMode;

  const flagsInput = config.flags ?? DEFAULTS.flags;
  const flagSet = new Set(flagsInput.split("").filter(Boolean));
  const flags = Array.from(flagSet).join("");

  const normalized: NormalizedRegexConfig = {
    ...config,
    matchMode,
    lookaround,
    capture,
    token,
    allowWhitespace,
    charset,
    quantifierTightness,
    engine,
    flags,
    safeMode,
  };

  if (normalized.capture === "namedGroup" && !normalized.groupName) {
    normalized.groupName = defaultGroupNameForToken(token);
  }

  return normalized;
}
