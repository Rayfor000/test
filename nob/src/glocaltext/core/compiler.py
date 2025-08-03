import pathlib
import shutil
import typing
from typing import Set
import logging
from collections import defaultdict

from glocaltext.core.config import L10nConfig
from glocaltext.core.i18n import I18nProcessor
from glocaltext.core.cache import TranslationCache

Path = pathlib.Path
Dict = typing.Dict
List = typing.List

logger = logging.getLogger(__name__)


class Compiler:
    """
    Compiles translated strings back into a mirrored directory structure,
    ensuring all source files are present in the output.
    """

    def __init__(
        self,
        config: L10nConfig,
        cache: TranslationCache,
        i18n_processor: I18nProcessor,
    ):
        """
        Initializes the Compiler.

        Args:
            config: The localization configuration.
            cache: The TranslationCache object containing all translations.
            i18n_processor: The I18nProcessor instance to get file lists and source text from.
        """
        self.config = config
        self.cache = cache
        self.i18n_processor = i18n_processor
        logger.debug("Compiler initialized")

    def run(self, project_path: Path):
        """
        Executes the compilation process, creating a full directory mirror.

        Args:
            project_path: The root path of the project.
        """
        logger.debug("Starting compiler run...")
        localized_path = project_path / ".ogos" / "localized"
        logger.debug(f"Output directory set to: {localized_path}")

        # 1. Group translations by language
        lang_to_translations = defaultdict(dict)
        for hash_id, cache_entry in self.cache.cache.items():
            source_text = cache_entry.source_text
            for lang_code, translation_value in cache_entry.translations.items():
                lang_to_translations[lang_code][
                    source_text
                ] = translation_value.get_translation()

        # 2. Iterate through each language with available translations and compile
        for lang_code, translations in lang_to_translations.items():
            localized_lang_path = localized_path / lang_code
            logger.info(f"Processing language: {lang_code}")

            # Clean and create the language-specific output directory
            if localized_lang_path.exists():
                shutil.rmtree(localized_lang_path)
            localized_lang_path.mkdir(parents=True, exist_ok=True)

            # Copy the entire project, excluding the .ogos directory
            shutil.copytree(
                project_path,
                localized_lang_path,
                dirs_exist_ok=True,
                ignore=shutil.ignore_patterns(".ogos"),
            )
            logger.debug(f"Copied project structure to {localized_lang_path}")

            # 3. Apply translations
            for source_file_path in self.i18n_processor.get_processed_files():
                if not source_file_path.is_file():
                    continue
                try:
                    relative_path = source_file_path.relative_to(project_path.resolve())
                    target_file_path = localized_lang_path / relative_path

                    logger.debug(f"  Applying translations to '{target_file_path}'")
                    content = target_file_path.read_text(encoding="utf-8")
                    replacements_made = 0

                    for source_text, translation in translations.items():
                        if source_text in content:
                            content = content.replace(source_text, translation)
                            replacements_made += 1

                    if replacements_made > 0:
                        target_file_path.write_text(content, encoding="utf-8")
                        logger.debug(
                            f"  Finished writing file with {replacements_made} replacements."
                        )

                except (FileNotFoundError, UnicodeDecodeError, ValueError) as e:
                    logger.error(
                        f"Error processing file {source_file_path} for language {lang_code}: {e}"
                    )
                    continue
        logger.info("Compiler run finished.")
