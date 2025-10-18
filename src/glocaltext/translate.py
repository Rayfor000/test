import logging
import os
from collections import defaultdict
from typing import Dict, List, Tuple

from .config import BatchOptions, GlocalConfig, TranslationTask
from .models import TextMatch
from .translators.base import BaseTranslator
from .translators.gemini_translator import GeminiTranslator
from .translators.google_translator import GoogleTranslator


def initialize_translators(config: GlocalConfig) -> Dict[str, BaseTranslator]:
    """Initializes all available translation providers based on the config."""
    translators: Dict[str, BaseTranslator] = {}

    # Initialize Gemini if configured
    gemini_settings = config.providers.get("gemini")
    if gemini_settings:
        # Prioritize API key from environment, then from config
        api_key = os.environ.get("GEMINI_API_KEY") or gemini_settings.api_key
        if api_key:
            try:
                # The model_name here is the GLOBAL default.
                translators["gemini"] = GeminiTranslator(
                    api_key=api_key,
                    model_name=gemini_settings.model or "gemini-1.0-pro",
                )
                logging.info(
                    f"Gemini provider initialized with default model '{translators['gemini'].model_name}'."
                )
            except Exception as e:
                logging.error(f"Failed to initialize Gemini provider: {e}")
        else:
            logging.warning(
                "Gemini provider is configured but no API key was found in GEMINI_API_KEY environment variable or config."
            )

    # Always initialize Google as a fallback
    translators["google"] = GoogleTranslator()
    logging.info("Google (deep-translator) initialized as default fallback.")

    return translators


def _apply_translation_rules(
    unique_texts: Dict[str, List[TextMatch]], task: TranslationTask
) -> Tuple[Dict[str, List[TextMatch]], int]:
    """
    Applies translation rules with a "firewall" logic.
    It iterates through rules for each text and stops at the first match.
    """
    skipped_count = 0
    texts_to_translate_api: Dict[str, List[TextMatch]] = {}

    for text, matches in unique_texts.items():
        is_handled = False
        original_text = text  # Preserve the original text key
        for rule in task.rules:
            match_found = False
            matched_value = None

            # Check for 'exact' match
            if rule.match.exact:
                conditions = (
                    [rule.match.exact]
                    if isinstance(rule.match.exact, str)
                    else rule.match.exact
                )
                if text in conditions:
                    match_found = True
                    matched_value = text

            # Check for 'contains' match if no 'exact' match was found
            if not match_found and rule.match.contains:
                conditions = (
                    [rule.match.contains]
                    if isinstance(rule.match.contains, str)
                    else rule.match.contains
                )
                for c in conditions:
                    if c in text:
                        match_found = True
                        matched_value = c
                        break

            if match_found:
                if rule.action.action == "skip":
                    for match in matches:
                        match.provider = "skipped"
                    skipped_count += 1
                    is_handled = True
                    break

                elif rule.action.action == "replace":
                    for match in matches:
                        match.translated_text = rule.action.value
                        match.provider = "rule"
                    is_handled = True
                    break

                elif rule.action.action == "modify":
                    if rule.action.value is not None and matched_value is not None:
                        text = text.replace(matched_value, rule.action.value)
                        logging.debug(
                            f"Text modified by rule: '{original_text}' -> '{text}'"
                        )
                    # Do not set is_handled or break; allow further rules to process

        if not is_handled:
            if text != original_text:
                # If text was modified, move the matches to the new text key
                if text in texts_to_translate_api:
                    texts_to_translate_api[text].extend(matches)
                else:
                    texts_to_translate_api[text] = matches
            else:
                texts_to_translate_api[text] = matches

    return texts_to_translate_api, skipped_count


def _create_batches(texts: List[str], batch_options: BatchOptions) -> List[List[str]]:
    """Splits a list of texts into batches based on size."""
    if not batch_options.enabled or not texts:
        return [texts] if texts else []

    batches: List[List[str]] = []
    for i in range(0, len(texts), batch_options.batch_size):
        batches.append(texts[i : i + batch_options.batch_size])
    return batches


def process_matches(
    matches: List[TextMatch],
    translators: Dict[str, BaseTranslator],
    task: TranslationTask,
    config: GlocalConfig,
) -> int:
    """
    Processes all text matches for a given task, from bucketing to translation.
    """
    if not matches:
        return 0

    unique_texts: Dict[str, List[TextMatch]] = defaultdict(list)
    for match in matches:
        unique_texts[match.original_text].append(match)
    logging.info(f"Found {len(unique_texts)} unique text strings to process.")

    texts_to_translate_api, skipped_count = _apply_translation_rules(unique_texts, task)

    if not texts_to_translate_api:
        logging.info(
            "All texts were handled by manual or skipped translations. No API call needed."
        )
        return skipped_count

    # Determine which provider to use with a clear priority order.
    provider_name = None

    # 1. Use task-specific translator if available and initialized.
    if task.translator and task.translator in translators:
        provider_name = task.translator
    # 2. Otherwise, fall back to a default provider.
    elif "gemini" in translators:
        provider_name = "gemini"  # Prefer Gemini if available.
    else:
        provider_name = "google"  # Ultimate fallback.

    logging.info(
        f"Translator for task '{task.name}': '{provider_name}' (Task-specific: {task.translator or 'Not set'})."
    )

    translator = translators[provider_name]
    provider_settings = config.providers.get(provider_name)
    batch_options = (
        provider_settings.batch_options if provider_settings else BatchOptions()
    )

    texts_for_batching = list(texts_to_translate_api.keys())

    # Create batches using the new helper function
    batches = _create_batches(texts_for_batching, batch_options)

    for i, batch in enumerate(batches):
        if not batch:
            continue
        logging.info(
            f"Translating batch {i + 1}/{len(batches)} ({len(batch)} unique texts) using '{provider_name}'."
        )
        try:
            # Correctly call the translate method
            translated_results = translator.translate(
                texts=batch,
                target_language=task.target_lang,
                source_language=task.source_lang,
                debug=config.debug_options.enabled,
                prompts=task.prompts,
            )

            # Correctly process the list of results
            for original_text, result in zip(batch, translated_results):
                if original_text in texts_to_translate_api:
                    for match in texts_to_translate_api[original_text]:
                        match.translated_text = result.translated_text
                        match.provider = provider_name
                        if result.tokens_used is not None:
                            match.tokens_used = (
                                match.tokens_used or 0
                            ) + result.tokens_used

        except Exception as e:
            logging.error(f"Error translating batch {i + 1} with {provider_name}: {e}")
            # Optionally, mark these matches as failed
            for original_text in batch:
                if original_text in texts_to_translate_api:
                    for match in texts_to_translate_api[original_text]:
                        match.provider = f"error_{provider_name}"

    return skipped_count
