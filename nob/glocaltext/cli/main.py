import logging
import os
from pathlib import Path
from typing import Dict, Set

import typer
import yaml

from glocaltext.core.cache import TranslationCache
from glocaltext.core.compiler import Compiler
from glocaltext.core.config import I18nConfig, L10nConfig
from glocaltext.core.i18n import I18nProcessor, ExtractedString
from glocaltext.core.l10n import L10nProcessor
from glocaltext.core.sync import SyncProcessor
from glocaltext.utils.logger import setup_logger

app = typer.Typer(
    help="GlocalText: A command-line tool for seamless software localization.",
    add_completion=False,
)


@app.command()
def init(
    directory_path: str = typer.Argument(
        ".", help="The path to the directory to initialize."
    ),
    debug: bool = typer.Option(
        False, "--debug", "-d", help="Enable debug mode with verbose logging."
    ),
):
    """
    Initialize GlocalText configuration files (i18n-rules.yaml and l10n-rules.yaml).
    """
    if debug:
        setup_logger(level=logging.DEBUG)
    else:
        setup_logger(level=logging.INFO)

    logger = logging.getLogger(__name__)

    base_path = Path(directory_path)
    ogos_path = base_path / ".ogos"
    ogos_path.mkdir(exist_ok=True)

    i18n_config_path = ogos_path / "i18n-rules.yaml"
    l10n_config_path = ogos_path / "l10n-rules.yaml"

    if i18n_config_path.exists() or l10n_config_path.exists():
        logger.warning(
            f"Configuration files already exist in {ogos_path}. Aborting initialization."
        )
        raise typer.Abort()

    # Create default i18n-rules.yaml
    default_i18n_config = {
        "source": {
            "include": ["**/*.*"],
            "exclude": ["tests/*", "docs/*", ".ogos/*", "localized/*"],
        },
        "capture_rules": [
            {"pattern": r"_\(\s*f?[\"'](.*?)[\"']\s*\)", "capture_group": 1}
        ],
        "ignore_rules": [],
    }
    with open(i18n_config_path, "w", encoding="utf-8") as f:
        yaml.dump(default_i18n_config, f, allow_unicode=True, sort_keys=False)
    logger.info(f"Created default i18n configuration at: {i18n_config_path}")

    # Create default l10n-rules.yaml
    default_l10n_config = {
        "translation_settings": {
            "source_lang": "en",
            "target_lang": ["ja", "zh-TW"],
            "provider": "google",
        },
        "provider_configs": {
            "gemini": {"model": "GEMINI_MODEL_NAME", "api_key": "GEMINI_API_KEY"},
            "openai": {
                "model": "OPENAI_MODEL_NAME",
                "base_url": "https://api.openai.com/v1",
                "api_key": "OPENAI_API_KEY",
                "prompts": {
                    "system": "You are a professional translator. Translate the user's text to {target_lang}.",
                    "contxt": "Translate the following from {source_lang} to {target_lang}: {text}",
                },
            },
            "ollama": {"model": "llama3", "base_url": "http://localhost:11434"},
        },
        "glossary": {"GlocalText": "GlocalText"},
        "glossary_file": None,
        "protection_rules": [r"\{.*?\}", r"\$.*?\$"],
    }
    with open(l10n_config_path, "w", encoding="utf-8") as f:
        yaml.dump(default_l10n_config, f, allow_unicode=True, sort_keys=False)
    logger.info(f"Created default l10n configuration at: {l10n_config_path}")


@app.command()
def run(
    directory_path: str = typer.Argument(
        ".", help="The path to the directory to process."
    ),
    force: bool = typer.Option(
        False,
        "--force",
        "-f",
        help="Force re-translation of all strings, ignoring the cache.",
    ),
    debug: bool = typer.Option(
        False, "--debug", "-d", help="Enable debug mode with verbose logging."
    ),
):
    """
    Run the localization process: extract, translate, and compile.
    """
    if debug:
        setup_logger(level=logging.DEBUG)
    else:
        setup_logger(level=logging.INFO)

    logger = logging.getLogger(__name__)

    base_path = Path(directory_path)
    ogos_path = base_path / ".ogos"
    try:
        i18n_config = I18nConfig.from_yaml(ogos_path / "i18n-rules.yaml")
        l10n_config = L10nConfig.from_yaml(ogos_path / "l10n-rules.yaml")
    except FileNotFoundError as e:
        logger.error(f"Configuration error: {e}")
        logger.error(
            "Please run 'glocaltext init' to create the necessary configuration files."
        )
        raise typer.Abort()

    artifacts_path = ogos_path / "artifacts"
    cache = TranslationCache(artifacts_path)
    i18n_processor = I18nProcessor(i18n_config, base_path)
    l10n_processor = L10nProcessor(l10n_config, cache, i18n_processor)

    # --- State and Conflict Management ---
    previous_state = cache.get_state()
    previous_source_hashes = previous_state.get("source_hashes", {})
    previous_localized_hashes = previous_state.get("localized_hashes", {})

    i18n_processor.run()  # Run to populate processed files
    current_source_hashes = {
        str(p.relative_to(base_path.resolve())): i18n_processor.get_file_hash(p)
        for p in i18n_processor.get_processed_files()
    }

    localized_path = ogos_path / "localized"
    current_localized_hashes = {}
    if localized_path.exists():
        for lang_dir in localized_path.iterdir():
            if lang_dir.is_dir():
                for f in lang_dir.rglob("*"):
                    if f.is_file():
                        try:
                            rel_path = str(f.relative_to(lang_dir))
                            current_localized_hashes[rel_path] = (
                                i18n_processor.get_file_hash(f)
                            )
                        except ValueError:
                            # This can happen if the file is outside the project base path
                            logger.warning(
                                f"Could not calculate relative path for {f}, skipping hash."
                            )

    # --- Differential Logic ---
    current_strings = i18n_processor.extracted_strings

    strings_to_translate: Dict[str, ExtractedString] = {}
    if force:
        logger.info("Force option detected. Translating all extracted strings.")
        strings_to_translate = current_strings
    else:
        logger.info("Performing differential check...")
        previous_strings_data = previous_state.get("extracted_strings", {})
        for hash_id, current_entry in current_strings.items():
            previous_entry_data = previous_strings_data.get(hash_id)
            if (
                not previous_entry_data
                or current_entry.text != previous_entry_data.get("text")
            ):
                strings_to_translate[hash_id] = current_entry

    logger.info(f"Found {len(strings_to_translate)} strings to translate.")

    # --- L10n and Compilation ---
    compiler = Compiler(l10n_config, cache, i18n_processor)

    if strings_to_translate:
        logger.info("Starting l10n translation process...")
        l10n_processor.process_and_translate(strings_to_translate, force)
        logger.info("Translation process completed.")
    else:
        logger.info("No new or modified strings to translate.")

    logger.info("Starting compilation of localized files...")
    compiler.run(base_path)
    logger.info("Compilation completed.")

    # --- Save new state ---
    # After a successful run, the localized files should match the source structure
    # and translations. We can re-calculate the hashes.
    new_localized_hashes = {}
    if localized_path.exists():
        for lang_dir in localized_path.iterdir():
            if lang_dir.is_dir():
                for f in lang_dir.rglob("*"):
                    if f.is_file():
                        try:
                            rel_path = str(f.relative_to(lang_dir))
                            new_localized_hashes[rel_path] = (
                                i18n_processor.get_file_hash(f)
                            )
                        except ValueError:
                            logger.warning(
                                f"Could not calculate relative path for {f}, skipping hash."
                            )

    new_state = {
        "source_hashes": current_source_hashes,
        "localized_hashes": new_localized_hashes,
        "extracted_strings": {k: v.dict() for k, v in current_strings.items()},
    }
    cache.save_state(new_state)
    cache.save()
    logger.info("Current state saved.")


@app.command()
def sync(
    directory_path: str = typer.Argument(
        ".", help="The path to the directory to sync."
    ),
    debug: bool = typer.Option(
        False, "--debug", "-d", help="Enable debug mode with verbose logging."
    ),
):
    """
    Sync manual changes from the 'localized' directory back to the translation cache.
    """
    if debug:
        setup_logger(level=logging.DEBUG)
    else:
        setup_logger(level=logging.INFO)

    logger = logging.getLogger(__name__)

    base_path = Path(directory_path)
    ogos_path = base_path / ".ogos"
    try:
        i18n_config = I18nConfig.from_yaml(ogos_path / "i18n-rules.yaml")
        l10n_config = L10nConfig.from_yaml(ogos_path / "l10n-rules.yaml")
    except FileNotFoundError as e:
        logger.error(f"Configuration error: {e}")
        logger.error("Please run 'glocaltext init' first.")
        raise typer.Abort()

    artifacts_path = ogos_path / "artifacts"
    cache = TranslationCache(artifacts_path)
    i18n_processor = I18nProcessor(i18n_config, base_path)

    sync_processor = SyncProcessor(l10n_config, cache, i18n_processor, base_path)
    sync_processor.run()


if __name__ == "__main__":
    app()
