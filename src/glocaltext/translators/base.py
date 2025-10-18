# Defines the base class for all translators
from abc import ABC, abstractmethod
from typing import Dict, List

from ..models import TranslationResult


class BaseTranslator(ABC):
    """Abstract base class for all translator implementations."""

    @abstractmethod
    def translate(
        self,
        texts: List[str],
        target_language: str,
        source_language: str | None = None,
        debug: bool = False,
        prompts: Dict[str, str] | None = None,
    ) -> List[TranslationResult]:
        """Translates a list of texts.

        Args:
            texts: A list of strings to be translated.
            target_language: The target language code.
            source_language: The source language code (optional).
            debug: If True, enables debug logging.
            prompts: A dictionary of prompts to use for this translation.

        Returns:
            A list of TranslationResult objects.

        """
        raise NotImplementedError
