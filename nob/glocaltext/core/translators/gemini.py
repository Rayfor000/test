import os
import logging
from typing import List, Optional, Dict

from google import genai
from google.genai import types
from google.genai.errors import APIError

from glocaltext.core.config import GeminiConfig
from glocaltext.core.translators.base import Translator

logger = logging.getLogger(__name__)


class GeminiTranslator(Translator):
    """A translator that uses the Google Gemini API."""

    def __init__(self, config: GeminiConfig):
        """
        Initializes the Gemini translator.
        """
        self.config = config
        logger.debug("Initializing GeminiTranslator.")
        api_key = self.config.api_key or os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError(
                "GEMINI_API_KEY is not set in config or environment variables."
            )

        self.client = genai.Client(api_key=api_key)
        logger.debug(f"Gemini client initialized for model '{self.config.model}'.")

    def _build_prompt(
        self,
        text: str,
        target_language: str,
        source_language: str,
        glossary: Optional[Dict[str, str]],
    ) -> str:
        """Builds the prompt for the Gemini API."""

        prompt = (
            f"You are a professional translator. Your task is to translate the given text from {source_language} to {target_language}. "
            "You must follow these rules strictly:\n"
            "1. ONLY return the translated text. \n"
            "2. Do NOT include the original text.\n"
            "3. Do NOT include any explanations, options, or additional formatting.\n"
        )
        if glossary:
            glossary_str = ", ".join(f'"{k}": "{v}"' for k, v in glossary.items())
            prompt += f"4. Adhere to this glossary: {glossary_str}\n"

        prompt += f'\nTranslate this text: "{text}"'
        return prompt

    def translate(
        self,
        texts: List[str],
        target_language: str,
        source_language: str,
        glossary: Optional[Dict[str, str]] = None,
    ) -> List[str]:
        """
        Translates a list of texts using the Gemini API.
        """
        translated_texts = []
        for text in texts:
            logger.debug(f"Translating text to '{target_language}': '{text[:50]}...'")

            prompt = self._build_prompt(
                text, target_language, source_language, glossary
            )
            logger.debug(f"Sending request to Gemini API. Prompt: {prompt}")

            try:
                response = self.client.models.generate_content(
                    model=self.config.model,
                    contents=[prompt],
                    config=types.GenerateContentConfig(
                        temperature=0.2,  # Lower temperature for more deterministic translations
                    ),
                )

                logger.debug(f"Received response from Gemini API: {response.text}")
                translated_text = response.text.strip()
                translated_texts.append(translated_text)

            except APIError as e:
                logger.error(f"Gemini API call failed for text '{text[:50]}...': {e}")
                translated_texts.append(text)  # Append original text on failure
            except Exception as e:
                logger.error(
                    f"An unexpected error occurred during Gemini translation for text '{text[:50]}...': {e}"
                )
                translated_texts.append(text)  # Append original text on failure

        return translated_texts
