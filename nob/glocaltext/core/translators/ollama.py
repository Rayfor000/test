import requests
import logging
from typing import List, Optional, Dict

from .base import Translator
from glocaltext.core.config import OllamaConfig

logger = logging.getLogger(__name__)


class OllamaTranslator(Translator):
    def __init__(self, config: OllamaConfig):
        self.config = config
        logger.debug(
            f"Initializing OllamaTranslator with model '{config.model}' at '{config.base_url}'"
        )

    def _build_prompt(
        self,
        text: str,
        target_language: str,
        source_language: str,
        glossary: Optional[Dict[str, str]],
    ) -> str:
        """Builds the prompt for the Ollama API."""

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
        Translates a list of texts using Ollama.
        """
        translated_texts = []
        full_url = f"{self.config.base_url}/api/generate"

        for text in texts:
            logger.debug(
                f"Translating with Ollama to '{target_language}': '{text[:50]}...'"
            )

            prompt = self._build_prompt(
                text, target_language, source_language, glossary
            )
            payload = {"model": self.config.model, "prompt": prompt, "stream": False}

            logger.debug(f"Sending request to Ollama. Prompt: {prompt}")

            try:
                response = requests.post(full_url, json=payload)
                response.raise_for_status()
                response_json = response.json()
                logger.debug(f"Received response from Ollama: {response_json}")
                translated_text = response_json.get("response", "").strip()
                translated_texts.append(translated_text)
            except requests.exceptions.RequestException as e:
                logger.error(
                    f"Ollama API request failed for text '{text[:50]}...': {e}"
                )
                translated_texts.append(text)
            except Exception as e:
                logger.error(
                    f"An unexpected error occurred during Ollama translation for text '{text[:50]}...': {e}"
                )
                translated_texts.append(text)

        return translated_texts
