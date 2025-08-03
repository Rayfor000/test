# glocaltext/core/l10n.py

"""
The L10nProcessor orchestrates the entire localization (l10n) process.
"""
import logging
from typing import Dict, Set, List, Tuple

from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt
from rich.style import Style
from rich.text import Text

from glocaltext.core.config import L10nConfig
from glocaltext.core.i18n import I18nProcessor, ExtractedString
from glocaltext.core.cache import TranslationCache, CacheEntry, TranslationValue
from glocaltext.core.translators.base import Translator
from glocaltext.core.translators.gemini import GeminiTranslator
from glocaltext.core.translators.deep_translator import DeepTranslator
from glocaltext.core.translators.openai import OpenAITranslator
from glocaltext.core.translators.ollama import OllamaTranslator

logger = logging.getLogger(__name__)


class L10nProcessor:
    """
    The central coordinator for the localization process.
    """

    def __init__(
        self,
        config: L10nConfig,
        cache: TranslationCache,
        i18n_processor: I18nProcessor,
    ):
        """
        Initializes the L10nProcessor.

        Args:
            config: The localization configuration.
            cache: The translation cache.
            i18n_processor: The I18nProcessor instance to access extracted string data.
        """
        self.config = config
        self.cache = cache
        self.i18n_processor = i18n_processor
        self.console = Console()
        logger.debug("L10nProcessor initialized")

        # Translator Factory
        provider = self.config.translation_settings.provider
        provider_configs = self.config.provider_configs
        logger.debug(f"Translation provider specified: '{provider}'")

        if provider == "gemini":
            if not provider_configs or not provider_configs.gemini:
                raise ValueError("Gemini provider config is missing.")
            self.translator: Translator = GeminiTranslator(
                config=provider_configs.gemini
            )
        elif provider == "openai":
            if not provider_configs or not provider_configs.openai:
                raise ValueError("OpenAI provider config is missing.")
            self.translator: Translator = OpenAITranslator(
                **provider_configs.openai.dict()
            )
        elif provider == "google":
            self.translator: Translator = DeepTranslator()
        elif provider == "ollama":
            if not provider_configs or not provider_configs.ollama:
                raise ValueError("Ollama provider config is missing.")
            self.translator: Translator = OllamaTranslator(
                **provider_configs.ollama.dict()
            )
        else:
            raise ValueError(f"Unknown translation provider: {provider}")
        logger.debug(f"Translator '{self.translator.__class__.__name__}' initialized.")

    def _prompt_for_conflict_resolution(
        self,
        old_text: str,
        new_text: str,
        existing_translations: Dict[str, TranslationValue],
    ) -> str:
        """
        Displays an interactive prompt to the user to resolve a source text conflict.
        """
        self.console.print(
            Panel(
                "[bold yellow]Source String Conflict Detected[/bold yellow]",
                expand=False,
            )
        )

        old_panel = Panel(
            Text(old_text, style="red"), title="Old Source Text", border_style="red"
        )
        new_panel = Panel(
            Text(new_text, style="green"), title="New Source Text", border_style="green"
        )

        self.console.print(old_panel)
        self.console.print(new_panel)

        if existing_translations:
            trans_text = Text()
            for lang, trans_val in existing_translations.items():
                trans_text.append(
                    f"  [bold]{lang}:[/bold] {trans_val.get_translation()}\n"
                )
            self.console.print(
                Panel(trans_text, title="Existing Translations", border_style="cyan")
            )

        choice = Prompt.ask(
            "[bold]Choose an action:[/bold]\n"
            "  1. [green]Translate[/green] the new text (recommended)\n"
            "  2. [yellow]Keep[/yellow] the old translations with the new text\n"
            "  3. [red]Skip[/red] and do nothing for now",
            choices=["1", "2", "3"],
            default="1",
        )
        return {"1": "translate", "2": "keep", "3": "skip"}[choice]

    def _prompt_for_general_conflict_resolution(self, file_path: str) -> str:
        """
        Displays an interactive prompt for a general file conflict.
        """
        self.console.print(
            Panel(
                f"[bold red]Conflict Detected for:[/bold red]\n{file_path}",
                expand=False,
            )
        )
        choice = Prompt.ask(
            "[bold]Choose how to resolve:[/bold]\n"
            "  1. [green]Use Source[/green] version (re-translates the file)\n"
            "  2. [yellow]Use Localized[/yellow] version (updates translations with your changes)",
            choices=["1", "2"],
            default="1",
        )
        return {"1": "source", "2": "localized"}[choice]

    def process_and_translate(
        self, all_strings: Dict[str, ExtractedString], force_translation: bool = False
    ):
        """
        Processes all extracted strings, handles conflicts, and translates new/updated ones.
        """
        logger.debug(
            f"Starting localization process for {len(all_strings)} unique strings."
        )

        def _ensure_source_lang_in_cache():
            """Ensure source language is in cache for all strings."""
            source_lang = self.config.translation_settings.source_lang
            for hash_id, extracted_string in all_strings.items():
                cached_entry = self.cache.get(hash_id)
                if not cached_entry:
                    cached_entry = CacheEntry(source_text=extracted_string.text)
                    self.cache.set(hash_id, cached_entry)

                if source_lang not in cached_entry.translations:
                    logger.debug(f"Adding source language entry for {hash_id}")
                    source_translation = TranslationValue(
                        original_translation=extracted_string.text,
                        current_translation=extracted_string.text,
                    )
                    cached_entry.translations[source_lang] = source_translation
                    self.cache.set(hash_id, cached_entry)

        _ensure_source_lang_in_cache()
        strings_to_translate: List[Tuple[str, str]] = []  # (hash_id, text)

        for hash_id, extracted_string in all_strings.items():
            new_source_text = extracted_string.text
            cached_entry = self.cache.get(hash_id)

            if force_translation:
                logger.debug(f"Forcing translation for {hash_id} due to --force flag.")
                strings_to_translate.append((hash_id, new_source_text))
                if not cached_entry:
                    self.cache.set(hash_id, CacheEntry(source_text=new_source_text))
                elif cached_entry.source_text != new_source_text:
                    cached_entry.source_text = new_source_text  # Update source text
                    self.cache.set(hash_id, cached_entry)
                continue

            if not cached_entry:
                logger.debug(
                    f"New string found ({hash_id}). Adding to translation queue."
                )
                self.cache.set(hash_id, CacheEntry(source_text=new_source_text))
                strings_to_translate.append((hash_id, new_source_text))

            elif cached_entry.source_text != new_source_text:
                logger.warning(
                    f"Conflict detected for hash {hash_id}. Old and new source text differ."
                )
                action = self._prompt_for_conflict_resolution(
                    cached_entry.source_text, new_source_text, cached_entry.translations
                )

                if action == "translate":
                    logger.debug(f"User chose to translate new text for {hash_id}.")
                    cached_entry.source_text = new_source_text
                    cached_entry.translations = {}  # Clear old translations
                    self.cache.set(hash_id, cached_entry)
                    strings_to_translate.append((hash_id, new_source_text))
                elif action == "keep":
                    logger.debug(f"User chose to keep old translations for {hash_id}.")
                    cached_entry.source_text = (
                        new_source_text  # Update source text, keep translations
                    )
                    self.cache.set(hash_id, cached_entry)
                else:  # skip
                    logger.debug(f"User chose to skip {hash_id}.")

            else:  # Source text is unchanged
                # Check if there are any missing languages for this existing string
                missing_langs = set(self.config.translation_settings.target_lang) - set(
                    cached_entry.translations.keys()
                )
                if missing_langs:
                    logger.debug(
                        f"Found existing string {hash_id} with missing languages: {missing_langs}."
                    )
                    strings_to_translate.append((hash_id, new_source_text))

        if not strings_to_translate:
            logger.info("No new or updated strings to translate.")
            return

        logger.info(f"Translating {len(strings_to_translate)} strings...")

        for lang_code in self.config.translation_settings.target_lang:
            logger.debug(f"  -> Translating to '{lang_code}'")

            texts_for_lang = []
            hash_map = {}
            idx = 0
            for hash_id, text in strings_to_translate:
                # Only translate if the language is missing for this hash
                cached_entry = self.cache.get(hash_id)
                if not cached_entry or lang_code not in cached_entry.translations:
                    texts_for_lang.append(text)
                    hash_map[idx] = hash_id
                    idx += 1

            if not texts_for_lang:
                logger.debug(
                    f"    - All strings already have a '{lang_code}' translation. Skipping."
                )
                continue

            try:
                translations = self.translator.translate(
                    texts=texts_for_lang,
                    source_language=self.config.translation_settings.source_lang,
                    target_language=lang_code,
                    glossary=self.config.glossary,
                )

                for i, translation_text in enumerate(translations):
                    if translation_text:
                        hash_id = hash_map[i]
                        cached_entry = self.cache.get(hash_id)
                        if cached_entry:
                            logger.debug(
                                f"    - Translation successful for {hash_id}: '{translation_text[:50]}...'"
                            )
                            new_trans_value = TranslationValue(
                                original_translation=translation_text,
                                current_translation=translation_text,
                            )
                            cached_entry.translations[lang_code] = new_trans_value
                            self.cache.set(hash_id, cached_entry)
                    else:
                        hash_id = hash_map[i]
                        logger.warning(
                            f"    - Translation returned empty result for hash {hash_id} to {lang_code}."
                        )

            except Exception as e:
                logger.error(f"Failed to translate batch for {lang_code}: {e}")
