import logging
import re
import xxhash
from pathlib import Path

from glocaltext.core.config import L10nConfig
from glocaltext.core.cache import TranslationCache
from glocaltext.core.i18n import I18nProcessor

logger = logging.getLogger(__name__)


class SyncProcessor:
    """
    Handles syncing changes from the 'localized' directory back to the translation cache.
    """

    def __init__(
        self,
        config: L10nConfig,
        cache: TranslationCache,
        i18n_processor: I18nProcessor,
        project_path: Path,
    ):
        self.config = config
        self.cache = cache
        self.i18n_processor = i18n_processor
        self.project_path = project_path
        self.localized_path = project_path / ".ogos" / "localized"
        logger.debug("SyncProcessor initialized")

    def run(self):
        """
        Scans the localized directories and updates the cache with manual changes.
        """
        logger.info("Starting sync process...")
        if not self.localized_path.exists():
            logger.warning("Localized directory not found. Nothing to sync.")
            return

        for lang_dir in self.localized_path.iterdir():
            if lang_dir.is_dir():
                lang_code = lang_dir.name
                logger.info(f"Syncing language: {lang_code}")
                self._sync_language_dir(lang_dir, lang_code)

        logger.info("Sync process finished. Translation cache has been updated.")

    def _sync_language_dir(self, lang_dir: Path, lang_code: str):
        """
        Syncs a single language directory.
        """
        logger.debug(f"Scanning directory: {lang_dir}")
        for localized_file in lang_dir.rglob("*"):
            if localized_file.is_file():
                logger.debug(f"Found localized file: {localized_file}")
                try:
                    relative_path = localized_file.relative_to(lang_dir)
                    source_file = self.project_path.joinpath(relative_path)

                    logger.debug(f"  - Relative path: {relative_path}")
                    logger.debug(
                        f"  - Checking for source file at: {source_file.resolve()}"
                    )

                    if source_file.exists():
                        logger.debug(f"  - Source file found. Proceeding to compare.")
                        self._compare_and_update(source_file, localized_file, lang_code)
                    else:
                        logger.warning(
                            f"  - Source file NOT found. Skipping sync for this file."
                        )

                except Exception as e:
                    logger.error(
                        f"Error syncing file {localized_file}: {e}", exc_info=True
                    )

    def _compare_and_update(
        self, source_file: Path, localized_file: Path, lang_code: str
    ):
        """
        Compares a source file with its localized version and updates the cache.
        """
        logger.debug(
            f"Comparing {source_file} with {localized_file} for language '{lang_code}'"
        )

        source_strings = self.i18n_processor.extract_raw_strings_from_file(source_file)
        localized_strings = self.i18n_processor.extract_raw_strings_from_file(
            localized_file
        )

        logger.debug(f"  - Source strings: {source_strings}")
        logger.debug(f"  - Localized strings: {localized_strings}")

        if len(source_strings) != len(localized_strings):
            logger.warning(
                f"File structure mismatch between {source_file} and {localized_file}. "
                f"Found {len(source_strings)} strings in source and {len(localized_strings)} in localized. "
                "Cannot sync this file."
            )
            return

        update_count = 0
        for source_text, localized_text in zip(source_strings, localized_strings):
            if source_text == localized_text:
                continue

            normalized_text = re.sub(r"\{.*?\}", "{}", source_text)
            hash_id = xxhash.xxh64(normalized_text.encode("utf-8")).hexdigest()

            cached_translation = self.cache.get_translation(hash_id, lang_code)

            logger.debug(
                f"  - Checking string: '{source_text[:30]}...' (Hash: {hash_id})"
            )
            logger.debug(f"    - Cached translation: '{cached_translation}'")
            logger.debug(f"    - Localized text:     '{localized_text}'")

            if cached_translation != localized_text:
                logger.info(f"  - Change detected! Syncing to cache.")
                self.cache.update_manual_override(hash_id, lang_code, localized_text)
                update_count += 1
            else:
                logger.debug("    - No difference found. Skipping.")

        if update_count > 0:
            logger.info(
                f"Synced {update_count} manual changes from {localized_file} to cache."
            )
