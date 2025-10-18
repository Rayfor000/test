import logging
import os
from collections import defaultdict
from typing import Dict, List, Tuple

from .config import BatchOptions, GlocalConfig, Rule, TranslationTask
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
                gemini_translator = translators["gemini"]
                if isinstance(gemini_translator, GeminiTranslator):
                    logging.info(f"Gemini provider initialized with default model '{gemini_translator.model_name}'.")
            except Exception as e:
                logging.error(f"Failed to initialize Gemini provider: {e}")
        else:
            logging.warning("Gemini provider is configured but no API key was found in GEMINI_API_KEY environment variable or config.")

    # Always initialize Google as a fallback
    translators["google"] = GoogleTranslator()
    logging.info("Google (deep-translator) initialized as default fallback.")

    return translators


def _check_rule_match(text: str, rule: Rule) -> Tuple[bool, str | None]:
    """Checks if a text matches a given rule."""
    # Check for 'exact' match
    if rule.match.exact:
        conditions = [rule.match.exact] if isinstance(rule.match.exact, str) else rule.match.exact
        if text in conditions:
            return True, text

    # Check for 'contains' match
    if rule.match.contains:
        conditions = [rule.match.contains] if isinstance(rule.match.contains, str) else rule.match.contains
        for c in conditions:
            if c in text:
                return True, c

    return False, None


def _handle_rule_action(text: str, matches: List[TextMatch], rule: Rule) -> Tuple[str, bool]:
    """Handles a single rule action (skip, replace, modify) for a text."""
    is_handled = False
    original_text = text
    match_found, matched_value = _check_rule_match(text, rule)

    if not match_found:
        return text, is_handled

    action = rule.action.action
    if action == "skip":
        for match in matches:
            match.provider = "skipped"
        is_handled = True
    elif action == "replace":
        for match in matches:
            match.translated_text = rule.action.value
            match.provider = "rule"
        is_handled = True
    elif action == "modify" and rule.action.value and matched_value:
        text = text.replace(matched_value, rule.action.value)
        logging.debug(f"Text modified by rule: '{original_text}' -> '{text}'")
        # Not handled, as modify can be chained

    return text, is_handled


def _apply_translation_rules(unique_texts: Dict[str, List[TextMatch]], task: TranslationTask) -> Tuple[Dict[str, List[TextMatch]], int]:
    """Applies translation rules with a "firewall" logic.
    It iterates through rules for each text and stops at the first handling action.
    """
    skipped_count = 0
    texts_to_translate_api: Dict[str, List[TextMatch]] = {}

    for original_text, matches in unique_texts.items():
        text = original_text
        is_handled = False

        for rule in task.rules:
            text, is_handled = _handle_rule_action(text, matches, rule)
            if is_handled:
                break

        if is_handled:
            skipped_count += 1
        else:
            # If text was modified, map original matches to the new text key
            if text != original_text:
                texts_to_translate_api.setdefault(text, []).extend(matches)
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


def _select_provider(task: TranslationTask, translators: Dict[str, BaseTranslator]) -> str:
    """Selects the translation provider based on task and availability."""
    # 1. Use task-specific translator if available and initialized.
    if task.translator and task.translator in translators:
        return task.translator
    # 2. Otherwise, fall back to a default provider.
    if "gemini" in translators:
        return "gemini"  # Prefer Gemini if available.
    return "google"  # Ultimate fallback.


def _translate_batch(
    translator: BaseTranslator,
    batch: List[str],
    task: TranslationTask,
    debug: bool,
    provider_name: str,
):
    """Helper to translate a single batch and handle errors."""
    try:
        return translator.translate(
            texts=batch,
            target_language=task.target_lang,
            source_language=task.source_lang,
            debug=debug,
            prompts=task.prompts,
        )
    except Exception as e:
        logging.error(f"Error translating batch with {provider_name}: {e}")
        return None


def _update_matches_on_success(
    batch: List[str],
    translated_results: list,
    texts_to_translate_api: Dict[str, List[TextMatch]],
    provider_name: str,
):
    """Updates TextMatch objects on successful translation."""
    for original_text, result in zip(batch, translated_results):
        for match in texts_to_translate_api[original_text]:
            match.translated_text = result.translated_text
            match.provider = provider_name
            if result.tokens_used is not None:
                match.tokens_used = (match.tokens_used or 0) + result.tokens_used


def _update_matches_on_failure(
    batch: List[str],
    texts_to_translate_api: Dict[str, List[TextMatch]],
    provider_name: str,
):
    """Updates TextMatch objects on translation failure."""
    for original_text in batch:
        for match in texts_to_translate_api[original_text]:
            match.provider = f"error_{provider_name}"


def _translate_and_update_matches(
    translator: BaseTranslator,
    batches: List[List[str]],
    texts_to_translate_api: Dict[str, List[TextMatch]],
    task: TranslationTask,
    config: GlocalConfig,
    provider_name: str,
):
    """Translates batches and updates the corresponding TextMatch objects."""
    for i, batch in enumerate(batches):
        if not batch:
            continue

        logging.info(f"Translating batch {i + 1}/{len(batches)} ({len(batch)} unique texts) using '{provider_name}'.")

        translated_results = _translate_batch(translator, batch, task, config.debug_options.enabled, provider_name)

        if translated_results:
            _update_matches_on_success(batch, translated_results, texts_to_translate_api, provider_name)
        else:
            _update_matches_on_failure(batch, texts_to_translate_api, provider_name)


def process_matches(
    matches: List[TextMatch],
    translators: Dict[str, BaseTranslator],
    task: TranslationTask,
    config: GlocalConfig,
) -> int:
    """Processes all text matches for a given task, from bucketing to translation."""
    if not matches:
        return 0

    unique_texts: Dict[str, List[TextMatch]] = defaultdict(list)
    for match in matches:
        unique_texts[match.original_text].append(match)
    logging.info(f"Found {len(unique_texts)} unique text strings to process.")

    texts_to_translate_api, skipped_count = _apply_translation_rules(unique_texts, task)

    if not texts_to_translate_api:
        logging.info("All texts were handled by rules. No API call needed.")
        return skipped_count

    provider_name = _select_provider(task, translators)
    logging.info(f"Translator for task '{task.name}': '{provider_name}' (Task-specific: {task.translator or 'Not set'}).")

    translator = translators[provider_name]
    provider_settings = config.providers.get(provider_name)
    batch_options = provider_settings.batch_options if provider_settings else BatchOptions()

    batches = _create_batches(list(texts_to_translate_api.keys()), batch_options)

    _translate_and_update_matches(translator, batches, texts_to_translate_api, task, config, provider_name)

    return skipped_count
