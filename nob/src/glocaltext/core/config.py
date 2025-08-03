# glocaltext/core/config.py

"""
Handles loading and validation of user configuration files (`i18n-rules.yaml`, `l10n-rules.yaml`)
using Pydantic models.
"""

import yaml
from pathlib import Path
from typing import List, Optional, Literal, Dict

from pydantic import BaseModel, Field


class BaseConfig(BaseModel):
    @classmethod
    def from_yaml(cls, path: Path):
        if not path.is_file():
            raise FileNotFoundError(f"Configuration file not found at: {path}")
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return cls(**data)


# ======================================================================================
# Models for i18n-rules.yaml
# ======================================================================================


class ExtractionRule(BaseModel):
    """Defines a regex pattern for extracting a string."""

    pattern: str
    capture_group: int = 1


class I18nSource(BaseModel):
    """Specifies which files to include and exclude for i18n."""

    include: List[str]
    exclude: List[str] = []


class I18nConfig(BaseConfig):
    """Configuration for the internationalization (i18n) process."""

    source: I18nSource
    capture_rules: List[ExtractionRule]
    ignore_rules: List[ExtractionRule] = Field(default_factory=list)


# ======================================================================================
# Models for l10n-rules.yaml
# ======================================================================================


class TranslationSettings(BaseModel):
    """General settings for the localization (l10n) process."""

    source_lang: str
    target_lang: List[str]
    provider: Literal["google", "gemini", "openai", "ollama"]


class GeminiPrompts(BaseModel):
    """Prompt templates for the Gemini provider."""

    system: str
    contxt: str


class GeminiConfig(BaseModel):
    """Configuration specific to the Gemini provider."""

    model: str
    api_key: Optional[str] = None
    prompts: Optional[GeminiPrompts] = None


class OpenAIPrompts(BaseModel):
    """Prompt templates for the OpenAI provider."""

    system: str
    contxt: str


class OpenAIConfig(BaseModel):
    """Configuration specific to the OpenAI provider."""

    model: str
    base_url: str
    api_key: str
    prompts: OpenAIPrompts


class OllamaConfig(BaseModel):
    """Configuration specific to the Ollama provider."""

    model: str
    base_url: str = "http://localhost:11434"


class ProviderConfigs(BaseModel):
    """Container for all supported translation provider configurations."""

    gemini: Optional[GeminiConfig] = None
    openai: Optional[OpenAIConfig] = None
    ollama: Optional[OllamaConfig] = None


class L10nConfig(BaseConfig):
    """Configuration for the localization (l10n) process."""

    translation_settings: TranslationSettings
    provider_configs: Optional[ProviderConfigs] = Field(default_factory=ProviderConfigs)
    glossary: Optional[Dict[str, str]] = None
    glossary_file: Optional[str] = None
    protection_rules: List[str] = Field(default_factory=list)


# ======================================================================================
# Main Config Container
# ======================================================================================


class Config(BaseModel):
    """Top-level container for all loaded configurations."""

    i18n: I18nConfig
    l10n: L10nConfig
