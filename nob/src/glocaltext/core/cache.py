import json
import logging
from pathlib import Path
from typing import Any, Dict, Optional, Tuple, Set
from datetime import datetime, timezone
from pydantic import BaseModel, Field, ValidationError

# This needs to be imported for the new methods
from glocaltext.core.i18n import ExtractedString

logger = logging.getLogger(__name__)


class TranslationValue(BaseModel):
    """
    Represents the translation details for a single language,
    including the original machine translation and an optional manual override.
    """

    original_translation: str = Field(
        ...,
        description="The immutable, original machine translation received from the provider.",
    )
    current_translation: str = Field(
        ...,
        description="The current translation, which may be the original or an updated machine translation.",
    )
    manual_override: Optional[str] = Field(
        None,
        description="A manual translation provided by a user, which takes precedence.",
    )
    last_updated: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Timestamp of the last modification (machine or manual).",
    )

    def get_translation(self) -> str:
        """
        Returns the definitive translation, prioritizing manual override.
        """
        return (
            self.manual_override
            if self.manual_override is not None
            else self.current_translation
        )


class CacheEntry(BaseModel):
    """
    Represents a single entry in the translation cache, keyed by a content hash.
    It stores the original source text and a dictionary of its translations.
    """

    source_text: str = Field(..., description="The original source text.")
    translations: Dict[str, TranslationValue] = Field(
        default_factory=dict,
        description="A dictionary mapping language codes to their translation values.",
    )

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
        }


class TranslationCache:
    """
    Manages a JSON-based cache for translations to avoid redundant API calls.
    The cache structure is: {hash_id: CacheEntry}
    """

    def __init__(self, cache_file_path: Path):
        """
        Initializes the TranslationCache.

        Args:
            cache_file_path: The direct path to the cache JSON file.
        """
        self.artifacts_path = cache_file_path.parent
        self.translations_path = self.artifacts_path / "translations"
        self.state_path = self.artifacts_path / "state.json"

        # Ensure the directories exist.
        self.artifacts_path.mkdir(parents=True, exist_ok=True)
        self.translations_path.mkdir(parents=True, exist_ok=True)

        logger.debug(f"Artifacts path initialized to: {self.artifacts_path}")
        self.cache: Dict[str, CacheEntry] = {}
        self.load()

    def load(self):
        """
        Loads the cache from the JSON file if it exists.
        Handles potential errors and validates the cache structure.
        """
        logger.debug(f"Attempting to load cache from {self.translations_path}")
        if not self.translations_path.exists():
            logger.debug(
                "Translations directory does not exist. Starting with an empty cache."
            )
            self.cache = {}
            return

        for lang_file in self.translations_path.glob("*.json"):
            try:
                lang_code = lang_file.stem
                with open(lang_file, "r", encoding="utf-8") as f:
                    lang_data = json.load(f)

                for hash_id, entry_data in lang_data.items():
                    if hash_id not in self.cache:
                        # Assuming the source_text is stored with the translation
                        if "source_text" in entry_data:
                            self.cache[hash_id] = CacheEntry(
                                source_text=entry_data["source_text"]
                            )
                        else:
                            # This case should be handled, maybe by loading source text from state
                            logger.warning(
                                f"Source text missing for {hash_id} in {lang_file}, skipping."
                            )
                            continue

                    try:
                        translation_value = TranslationValue.parse_obj(entry_data)
                        self.cache[hash_id].translations[lang_code] = translation_value
                    except ValidationError as e:
                        logger.warning(
                            f"Skipping invalid translation entry for {hash_id} in {lang_file}: {e}"
                        )

            except (json.JSONDecodeError, FileNotFoundError) as e:
                logger.warning(
                    f"Translation file {lang_file} not found or is corrupted ({e})."
                )
        logger.debug(
            f"Finished processing translations. Loaded {len(self.cache)} total entries."
        )

    def get(self, hash_id: str) -> Optional[CacheEntry]:
        """
        Retrieves a CacheEntry from the cache.
        """
        entry = self.cache.get(hash_id)
        logger.debug(f"Cache get for {hash_id}: {'Found' if entry else 'Miss'}")
        return entry

    def get_translation(self, hash_id: str, target_lang: str) -> Optional[str]:
        """
        Retrieves the definitive translation for a given string and language.
        """
        entry = self.get(hash_id)
        if not entry or target_lang not in entry.translations:
            return None
        return entry.translations[target_lang].get_translation()

    def set(self, hash_id: str, entry: CacheEntry):
        """
        Sets or updates an entry in the cache.
        """
        self.cache[hash_id] = entry
        logger.debug(f"Set/updated cache entry for {hash_id}")

    def save(self):
        """
        Saves the current state of the cache to language-specific JSON files.
        """
        logger.debug(
            f"Saving cache with {len(self.cache)} entries to {self.translations_path}"
        )

        translations_by_lang = {}
        for hash_id, entry in self.cache.items():
            for lang_code, translation_value in entry.translations.items():
                if lang_code not in translations_by_lang:
                    translations_by_lang[lang_code] = {}

                # Include source_text in each language file for context
                translations_by_lang[lang_code][hash_id] = {
                    "source_text": entry.source_text,
                    **translation_value.dict(),
                }

        class CustomEncoder(json.JSONEncoder):
            def default(self, o):
                if isinstance(o, datetime):
                    return o.isoformat()
                return super().default(o)

        for lang_code, lang_data in translations_by_lang.items():
            lang_file_path = self.translations_path / f"{lang_code}.json"
            try:
                # Add detailed logging before writing to the file
                logger.debug(
                    f"Preparing to save data for '{lang_code}' to {lang_file_path}"
                )
                logger.debug(
                    f"Data to be saved: {json.dumps(lang_data, indent=2, ensure_ascii=False, cls=CustomEncoder)}"
                )

                with open(lang_file_path, "w", encoding="utf-8") as f:
                    json.dump(
                        lang_data, f, indent=2, ensure_ascii=False, cls=CustomEncoder
                    )
                logger.debug(
                    f"Successfully saved translations for '{lang_code}' to {lang_file_path}"
                )
            except IOError as e:
                logger.error(
                    f"Failed to save translations for '{lang_code}' to {lang_file_path}: {e}"
                )

    def update_with_manual_overrides(self, overrides: Dict[Tuple[str, str], str]):
        """
        Applies a batch of manual overrides to the cache.
        """
        logger.debug(f"Updating cache with {len(overrides)} manual overrides.")
        for (hash_id, lang_code), translation in overrides.items():
            entry = self.get(hash_id)
            if entry and lang_code in entry.translations:
                entry.translations[lang_code].manual_override = translation
                entry.translations[lang_code].last_updated = datetime.now(timezone.utc)
                logger.debug(f"Set manual override for {hash_id}/{lang_code}")
            else:
                logger.warning(
                    f"Cannot set manual override for {hash_id}/{lang_code}: entry not found."
                )
        logger.debug("Finished applying manual overrides.")

    def update_manual_override(self, hash_id: str, lang_code: str, translation: str):
        """
        Sets or updates a manual override for a single translation entry.
        """
        entry = self.get(hash_id)
        if not entry:
            logger.warning(
                f"Cannot set manual override for hash '{hash_id}': entry not found."
            )
            return

        if lang_code not in entry.translations:
            # If the language entry doesn't exist, we can't set an override.
            # This might happen if a new language is added but not yet translated.
            logger.warning(
                f"Cannot set manual override for hash '{hash_id}': language '{lang_code}' not found in translations."
            )
            return

        entry.translations[lang_code].manual_override = translation
        entry.translations[lang_code].last_updated = datetime.now(timezone.utc)
        logger.debug(f"Set manual override for {hash_id}/{lang_code}")
        # Immediately save the change to ensure it persists.
        self.save()

    def get_all_cached_hashes(self) -> Set[str]:
        """Returns a set of all hash_ids currently in the cache."""
        return set(self.cache.keys())

    def get_target_languages(self) -> Set[str]:
        """Returns a set of all unique target language codes in the cache."""
        langs = set()
        for entry in self.cache.values():
            langs.update(entry.translations.keys())
        return langs

    def get_state(self) -> Dict:
        """Loads the state from the state file."""
        if not self.state_path.exists():
            return {}
        try:
            with self.state_path.open("r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            return {}

    def save_state(self, state_data: Dict):
        """Saves the given state data to the state file."""
        logger.debug(f"Saving state to {self.state_path}")

        class CustomEncoder(json.JSONEncoder):
            def default(self, o):
                if isinstance(o, Path):
                    return str(o.as_posix())
                if isinstance(o, BaseModel):
                    return o.dict()
                return super().default(o)

        try:
            with self.state_path.open("w", encoding="utf-8") as f:
                json.dump(
                    state_data, f, indent=2, ensure_ascii=False, cls=CustomEncoder
                )
            logger.debug("State file saved successfully.")
        except IOError as e:
            logger.error(f"Failed to save state file to {self.state_path}: {e}")

    def remove_entries_by_hash(self, hashes_to_remove: Set[str]):
        """Removes all cache entries associated with the given hashes."""
        logger.debug(f"Removing {len(hashes_to_remove)} entries from cache.")
        count = 0
        for hash_id in hashes_to_remove:
            if hash_id in self.cache:
                del self.cache[hash_id]
                logger.debug(f"  - Removed cache entry for hash: {hash_id}")
                count += 1
        logger.debug(f"Removed {count} entries from the cache.")
