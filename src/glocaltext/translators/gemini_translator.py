# Implementation for the Gemini AI API using the latest google-genai SDK
import json
import os
import time
from typing import Dict, List, Optional
from .base import BaseTranslator
from ..models import TranslationResult
from google import genai
from google.genai import types
import logging

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
        """
        Initializes the Gemini Translator.

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
            raise ValueError(
                "Gemini API key not found. Please provide it in config.yaml or set the GEMINI_API_KEY environment variable."
            )

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
        """
        Translate a list of texts using the GenAI SDK's generative model.
        This method is designed for batch translation and uses a structured prompt
        to ensure JSON output and respect provided manual translations.
        """
        if not texts:
            return []

        prompt = ""
        try:
            # Build the prompt, allowing for overrides
            manual_translations_json = "{}"  # This is deprecated, handled by rules now
            texts_json_array = json.dumps(texts, ensure_ascii=False)

            # Allow for user-defined prompts, falling back to the default.
            user_prompt_template = (
                prompts.get("user", PROMPT_TEMPLATE) if prompts else PROMPT_TEMPLATE
            )

            prompt = user_prompt_template.format(
                source_lang=source_language or "the original language",
                target_lang=target_language,
                manual_translations_json=manual_translations_json,
                texts_json_array=texts_json_array,
                text=texts_json_array,  # For prompts that use '{text}'
            )

            # Prepare the request payload
            system_instruction = prompts.get("system") if prompts else None

            # 2. Calculate prompt tokens
            prompt_tokens_response = self.client.models.count_tokens(
                model=self.model_name, contents=prompt
            )
            prompt_tokens = prompt_tokens_response.total_tokens or 0

            if debug:
                logging.info(
                    f"[DEBUG] Gemini Request:\n- Model: {self.model_name}\n- Prompt Tokens: {prompt_tokens}\n- Prompt Body (first 200 chars): {prompt[:200]}..."
                )

            # 3. Call the Gemini API
            start_time = time.time()
            
            config = types.GenerateContentConfig(
                response_mime_type="application/json",
                system_instruction=system_instruction
            )

            response = self.client.models.generate_content(
                model=self.model_name, contents=prompt, config=config
            )
            duration = time.time() - start_time
            
            # 4. Calculate response tokens (and handle potential None)
            response_text = response.text or ""
            response_tokens = 0
            if response_text and response.candidates and response.candidates[0].content:
                response_tokens_response = self.client.models.count_tokens(
                    model=self.model_name, contents=response.candidates[0].content
                )
                response_tokens = response_tokens_response.total_tokens or 0

            total_tokens = prompt_tokens + response_tokens

            if debug:
                logging.info(
                    f"[DEBUG] Gemini Response:\n- Duration: {duration:.2f}s\n- Completion Tokens: {response_tokens}\n- Total Tokens: {total_tokens}\n- Response Text (first 200 chars): {response_text[:200]}..."
                )

            # 5. Parse and validate the response
            translated_texts = self._parse_and_validate_response(
                response_text, len(texts)
            )

            # 6. Create TranslationResult objects
            tokens_per_text = total_tokens // len(texts) if texts else 0

            results = []
            for translated_text in translated_texts:
                results.append(
                    TranslationResult(
                        translated_text=translated_text,
                        tokens_used=tokens_per_text,
                    )
                )

            if results:
                remainder = total_tokens % len(texts) if texts else 0
                results[-1].tokens_used += remainder

            return results

        except Exception as e:
            logging.error(f"Gemini API request failed: {e}. Returning original texts.")
            if prompt:
                logging.debug(f"Failed prompt for Gemini: \n{prompt}")
            return [TranslationResult(translated_text=text) for text in texts]

    def _parse_and_validate_response(
        self, response_text: str, expected_count: int
    ) -> List[str]:
        """
        Parses the JSON response from Gemini and validates its structure.
        """
        try:
            cleaned_text = (
                response_text.strip()
                .removeprefix("```json")
                .removesuffix("```")
                .strip()
            )

            data = json.loads(cleaned_text)
            if not isinstance(data, list):
                raise ValueError("Response is not a JSON list.")

            if len(data) != expected_count:
                raise ValueError(
                    f"Response list length ({len(data)}) does not match expected length ({expected_count})."
                )

            return [str(item) for item in data]

        except (ValueError, json.JSONDecodeError) as e:
            if isinstance(e, json.JSONDecodeError):
                logging.warning(
                    "Failed to parse Gemini response as JSON. Assuming plain text response for the whole batch."
                )
                return [response_text.strip()] * expected_count

            logging.error(f"Failed to parse or validate Gemini response: {e}")
            logging.debug(f"Invalid Gemini response text: {response_text}")
            return [""] * expected_count
