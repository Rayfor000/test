import { describe, expect, it } from "vitest";
import { buildRegexFromConfig } from "../src/retrieve";
import type { RegexConfig } from "../src/config/schema";

describe("retrieve Txt digits case", () => {
  it("builds expected variants for Txt(123)", () => {
    const config: RegexConfig = {
      prefix: "Txt(",
      suffix: ")",
      token: "digits",
      length: { exact: 3 },
      capture: "group",
      matchMode: "full",
      engine: "JS",
    };

    const result = buildRegexFromConfig(config);

    expect(result.primary.pattern).toBe("^Txt\\((\\d{3})\\)$");

    const variantPatterns = result.variants.map((variant) => variant.pattern);

    expect(variantPatterns).toContain("^Txt\\((\\d+)\\)$");
    expect(variantPatterns).toContain("^Txt\\(\\s*(\\d+)\\s*\\)$");

    const namedGroupVariant = variantPatterns.find((pattern) =>
      pattern.includes("(?<")
    );
    if (namedGroupVariant) {
      expect(namedGroupVariant).toBe("^Txt\\((?<num>\\d+)\\)$");
    }

    if (config.matchMode === "contains") {
      expect(variantPatterns).toContain("(?<=Txt\\()\\d+(?=\\))");
    }
  });
});
