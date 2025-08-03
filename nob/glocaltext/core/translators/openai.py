import time
import openai
import logging
import functools
from typing import List, Optional, Dict, Any

from .base import Translator
from glocaltext.core.config import OpenAIConfig

logger = logging.getLogger(__name__)


def rate_limit_retry(max_retries=10, base_delay=2):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except openai.RateLimitError as e:
                    if attempt < max_retries - 1:
                        delay = base_delay * (2**attempt)
                        logger.warning(
                            f"Rate limit exceeded. Retrying in {delay} seconds..."
                        )
                        time.sleep(delay)
                    else:
                        logger.error("Max retries exceeded for rate limit.")
                        raise e
            return None

        return wrapper

    return decorator


class OpenAITranslator(Translator):
    def __init__(self, config: OpenAIConfig):
        self.config = config
        logger.debug(f"Initializing OpenAITranslator with model '{config.model}'")
        self.client = openai.OpenAI(base_url=config.base_url, api_key=config.api_key)

    def _build_system_prompt(
        self,
        target_language: str,
        glossary: Optional[Dict[str, str]],
    ) -> str:
        """Builds the system prompt for the OpenAI API."""

        system_prompt = (
            f"You are a professional translator. Your task is to translate to {target_language}. "
            "You must follow these rules strictly:\n"
            "1. ONLY return the translated text. \n"
            "2. Do NOT include the original text.\n"
            "3. Do NOT include any explanations, options, or additional formatting.\n"
        )

        if glossary:
            glossary_str = ", ".join(f'"{k}": "{v}"' for k, v in glossary.items())
            system_prompt += f"4. Adhere to this glossary: {glossary_str}\n"

        return system_prompt

    @rate_limit_retry()
    def _translate_single_text(
        self,
        text: str,
        system_prompt: str,
        source_language: str,
    ) -> str:
        """Helper function to translate a single piece of text."""
        user_prompt = f'Translate the following text from {source_language}: "{text}"'

        logger.debug(f"Sending request to OpenAI API. Prompt: {user_prompt}")

        response = self.client.chat.completions.create(
            model=self.config.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
        )
        logger.debug(
            f"Received response from OpenAI API: {response.choices[0].message.content}"
        )
        return response.choices[0].message.content.strip()

    def translate(
        self,
        texts: List[str],
        target_language: str,
        source_language: str,
        glossary: Optional[Dict[str, str]] = None,
    ) -> List[str]:
        """
        Translates a list of texts using the OpenAI API.
        """

        system_prompt = self._build_system_prompt(target_language, glossary)
        logger.debug(f"System prompt: {system_prompt}")

        translated_texts = []
        for text in texts:
            logger.debug(
                f"Translating with OpenAI to '{target_language}': '{text[:50]}...'"
            )
            time.sleep(1)  # Add a 1-second delay to avoid rate limiting

            try:
                translated_text = self._translate_single_text(
                    text, system_prompt, source_language
                )
                translated_texts.append(translated_text)
            except openai.APIError as e:
                logger.error(f"OpenAI API error for text '{text[:50]}...': {e}")
                translated_texts.append(text)
            except Exception as e:
                logger.error(
                    f"An unexpected error occurred during OpenAI translation for text '{text[:50]}...': {e}"
                )
                translated_texts.append(text)

        return translated_texts
