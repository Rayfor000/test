import logging
from typing import List, Optional, Dict
from deep_translator import GoogleTranslator
from .base import Translator

logger = logging.getLogger(__name__)


class DeepTranslator(Translator):
    def __init__(self):
        logger.debug("Initializing DeepTranslator (Google).")

    def translate(
        self,
        texts: List[str],
        target_language: str,
        source_language: str,
        glossary: Optional[Dict[str, str]] = None,
    ) -> List[str]:

        # DeepTranslator does not support glossaries, so we log a warning if one is provided.
        if glossary:
            logger.warning(
                "DeepTranslator does not support glossaries. The glossary will be ignored."
            )

        translated_texts = []
        for text in texts:
            logger.debug(f"Sending request to Google Translate. Text: {text}")
            try:
                translated_text = GoogleTranslator(
                    source=source_language, target=target_language
                ).translate(text)
                logger.debug(
                    f"Received response from Google Translate: {translated_text}"
                )
                translated_texts.append(translated_text)
            except Exception as e:
                logger.error(
                    f"Google Translate failed for text: '{text[:50]}...'. Error: {e}"
                )
                # In case of an error for one text, append the original text
                translated_texts.append(text)
        return translated_texts
