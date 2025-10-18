# Implementation for the Gemini AI API using the latest google-genai SDK
import json
import logging
import os
import time
from typing import Dict, List, Optional

from google import genai
from google.genai import types

from ..models import TranslationResult
from .base import BaseTranslator

# --- Constants ---
PROMPT_TEMPLATE = """
You are a professional translation engine. Your task is to translate a list of texts from {source_lang} to {target_lang}.

You MUST adhere to the following rules:
1.  Respond with ONLY a single, valid JSON array of strings. Each string in the array is a translation of the corresponding text in the input.
2.  The JSON array MUST have the exact same number of elements as the input `texts_to_translate` array.
3.  If a translation is impossible, return the original text for that item.
4.  Pay close attention to the `manual_translations` provided. These are verified human translations and MUST be used as the single source of truth.

---
[MANUAL TRANSLATIONS START]
{manual_translations_json}
[MANUAL TRANSLATIONS END]
---

Translate the following JSON array of texts:

[TEXTS START]
{texts_json_array}
[TEXTS END]
"""


# Model-specific configurations including rate limits (RPM/TPM) and batch sizes.
GEMINI_MODEL_CONFIGS = {"gemma-3n-e4b-it": {"rpm": 30, "tpm": 15000, "batch_size": 10}}


class GeminiTranslator(BaseTranslator):
    """Translator using the official Google GenAI SDK."""

    def __init__(self, api_key: Optional[str], model_name: str = "gemini-1.0-pro"):
        """Initializes the Gemini Translator.

        It follows a specific priority for API key resolution:
        1. Use the api_key explicitly provided in the configuration.
        2. If not provided, fall back to the `GEMINI_API_KEY` environment variable.

        Args:
            api_key: The API key from the config file (can be None).
            model_name: The name of the Gemini model to use.

        Raises:
            ValueError: If no API key is found in the config or environment variables.
            ConnectionError: If the client fails to initialize.

        """
        final_api_key = api_key or os.getenv("GEMINI_API_KEY")

        if not final_api_key:
            raise ValueError("Gemini API key not found. Please provide it in config.yaml or set the GEMINI_API_KEY environment variable.")

        try:
            self.client = genai.Client(api_key=final_api_key)
            self.model_name = model_name
        except Exception as e:
            raise ConnectionError(f"Failed to initialize Gemini client: {e}")

    def translate(
        self,
        texts: List[str],
        target_language: str,
        source_language: str | None = None,
        debug: bool = False,
        prompts: Dict[str, str] | None = None,
    ) -> List[TranslationResult]:
        """Translate a list of texts using the GenAI SDK's generative model.
        This method orchestrates the translation process by building a prompt,
        calling the API, and processing the response.
        """
        if not texts:
            return []

        prompt = ""
        try:
            # 1. Build the prompt and get system instructions
            prompt, system_instruction = self._build_prompt(texts, target_language, source_language, prompts)

            # 2. Calculate prompt tokens and log if debugging
            prompt_tokens = self._count_tokens(prompt)
            if debug:
                logging.info(f"[DEBUG] Gemini Request:\n- Model: {self.model_name}\n- Prompt Tokens: {prompt_tokens}\n- Prompt Body (first 200 chars): {prompt[:200]}...")

            # 3. Call the Gemini API
            start_time = time.time()
            config = types.GenerateContentConfig(
                response_mime_type="application/json",
                system_instruction=system_instruction,
            )
            response = self.client.models.generate_content(model=self.model_name, contents=prompt, config=config)
            duration = time.time() - start_time

            # 4. Calculate response tokens and log
            response_text = response.text or ""
            response_tokens = self._count_tokens(response.candidates[0].content) if response.candidates and response.candidates[0].content else 0
            total_tokens = prompt_tokens + response_tokens

            if debug:
                logging.info(f"[DEBUG] Gemini Response:\n- Duration: {duration:.2f}s\n- Completion Tokens: {response_tokens}\n- Total Tokens: {total_tokens}\n- Response Text (first 200 chars): {response_text[:200]}...")

            # 5. Parse and validate the structured response
            translated_texts = self._parse_and_validate_response(response_text, len(texts))

            # 6. Package results into TranslationResult objects
            return self._package_results(translated_texts, total_tokens)

        except Exception as e:
            logging.error(f"Gemini API request failed: {e}. Returning original texts.")
            if prompt:
                logging.debug(f"Failed prompt for Gemini: \n{prompt}")
            return [TranslationResult(translated_text=text) for text in texts]

    def _build_prompt(
        self,
        texts: List[str],
        target_language: str,
        source_language: Optional[str],
        prompts: Optional[Dict[str, str]],
    ) -> tuple[str, Optional[str]]:
        """Builds the prompt and extracts the system instruction."""
        manual_translations_json = "{}"  # Deprecated
        texts_json_array = json.dumps(texts, ensure_ascii=False)

        user_prompt_template = prompts.get("user", PROMPT_TEMPLATE) if prompts else PROMPT_TEMPLATE

        prompt = user_prompt_template.format(
            source_lang=source_language or "the original language",
            target_lang=target_language,
            manual_translations_json=manual_translations_json,
            texts_json_array=texts_json_array,
            text=texts_json_array,
        )
        system_instruction = prompts.get("system") if prompts else None
        return prompt, system_instruction

    def _count_tokens(self, content: str | types.ContentDict | types.Content) -> int:
        """Counts the tokens for the given content, handling potential errors."""
        if not content:
            return 0
        try:
            response = self.client.models.count_tokens(model=self.model_name, contents=content)
            return response.total_tokens or 0
        except Exception as e:
            logging.warning(f"Token counting failed: {e}. Returning 0.")
            return 0

    def _package_results(self, translated_texts: List[str], total_tokens: int) -> List[TranslationResult]:
        """Packages the translated texts into TranslationResult objects."""
        num_texts = len(translated_texts)
        if not num_texts:
            return []

        tokens_per_text = total_tokens // num_texts
        results = [TranslationResult(translated_text=text, tokens_used=tokens_per_text or 0) for text in translated_texts]

        remainder = total_tokens % num_texts
        if results and results[-1].tokens_used is not None:
            results[-1].tokens_used += remainder

        return results

    def _parse_and_validate_response(self, response_text: str, expected_count: int) -> List[str]:
        """Parses the JSON response from Gemini and validates its structure."""
        try:
            cleaned_text = response_text.strip().removeprefix("```json").removesuffix("```").strip()

            data = json.loads(cleaned_text)
            if not isinstance(data, list):
                raise ValueError("Response is not a JSON list.")

            if len(data) != expected_count:
                raise ValueError(f"Response list length ({len(data)}) does not match expected length ({expected_count}).")

            return [str(item) for item in data]

        except ValueError as e:
            if isinstance(e, json.JSONDecodeError):
                logging.warning("Failed to parse Gemini response as JSON. Assuming plain text response for the whole batch.")
                return [response_text.strip()] * expected_count

            logging.error(f"Failed to parse or validate Gemini response: {e}")
            logging.debug(f"Invalid Gemini response text: {response_text}")
            return [""] * expected_count
