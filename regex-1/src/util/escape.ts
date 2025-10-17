const REGEX_SPECIAL_CHARACTERS = /[.*+?^${}()|[\]\\]/g;

export function escapeRegexLiteral(value: string): string {
  return value.replace(REGEX_SPECIAL_CHARACTERS, "\\$&");
}

export default escapeRegexLiteral;
