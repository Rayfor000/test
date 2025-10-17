import { EngineType } from "../config/schema";

export interface EngineCapabilities {
  namedGroups: boolean;
  lookbehind: boolean;
}

const DEFAULT_CAPABILITIES: EngineCapabilities = {
  namedGroups: false,
  lookbehind: false,
};

export const ENGINE_CAPABILITIES: Record<EngineType, EngineCapabilities> = {
  JS: {
    namedGroups: true,
    lookbehind: true,
  },
  PCRE: {
    namedGroups: true,
    lookbehind: true,
  },
};

export function getEngineCapabilities(engine: EngineType): EngineCapabilities {
  return ENGINE_CAPABILITIES[engine] ?? DEFAULT_CAPABILITIES;
}
