# Implementation for the Google Translate API using deep-translator
from typing import Dict, List
from .base import BaseTranslator
from ..models import TranslationResult
from deep_translator import GoogleTranslator as DeepGoogleTranslator


class GoogleTranslator(BaseTranslator):
    """
    Translator using the Google Translate API via the 'deep-translator' library.
    This does not require an API key for basic usage.
    """

    def __init__(self):
        """Initializes the Google Translator."""
        # deep-translator handles the client setup internally.
        pass

    def translate(
        self,
        texts: List[str],
        target_language: str,
        source_language: str | None = "auto",
        debug: bool = False,
        prompts: Dict[str, str] | None = None,
    ) -> List[TranslationResult]:
        """
        Translate a list of texts using deep-translator.

        Args:
            texts: A list of strings to translate.
            target_language: The target language code (e.g., 'zh-TW').
            source_language: The source language code (e.g., 'en'). Defaults to 'auto'.
            prompts: This argument is ignored by this translator.
            debug: This provider does not support debug mode. This argument is ignored.

        Returns:
            A list of TranslationResult objects.
        """
        if not texts:
            return []

        try:
            # deep-translator can handle batch translation in a single call.
            translated_texts = DeepGoogleTranslator(
                source=source_language or "auto", target=target_language
            ).translate_batch(texts)

            return [TranslationResult(translated_text=t) for t in translated_texts]

        except Exception as e:
            raise ConnectionError(f"deep-translator (Google) request failed: {e}")
