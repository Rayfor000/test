import regex
from pathlib import Path
from typing import Dict, List, Iterable
from glob import glob
import logging
import hashlib
import json

from google.generativeai.generative_models import GenerativeModel

from .models import TextMatch
from .config import GlocalConfig, TranslationTask, Output, BatchOptions
from .translate import process_matches
from .translators.base import BaseTranslator

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def calculate_checksum(text: str) -> str:
    """Calculates the SHA-256 checksum of a given text."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def get_cache_path(task_output: Output) -> Path:
    """
    Returns the correct path for the .glocaltext_cache.json file.
    - If a path is specified, the cache is in that directory.
    - If in_place, the cache is in the current working directory as a fallback.
    """
    if task_output.path:
        output_dir = Path(task_output.path)
        if output_dir.suffix or not output_dir.is_dir():
            # If the path looks like a file, or doesn't exist as a directory,
            # place the cache in its parent directory.
            return output_dir.parent / ".glocaltext_cache.json"
        # If the path is an existing directory, place the cache inside it.
        return output_dir / ".glocaltext_cache.json"
    else:
        # Fallback for in-place translations.
        return Path.cwd() / ".glocaltext_cache.json"


def load_cache(cache_path: Path, task_name: str) -> Dict[str, str]:
    """Safely loads the cache for a specific task from the cache file."""
    if not cache_path.exists():
        return {}
    try:
        with open(cache_path, "r", encoding="utf-8") as f:
            full_cache = json.load(f)
        return full_cache.get(task_name, {})
    except (json.JSONDecodeError, IOError):
        logging.warning(f"Could not read or parse cache file at {cache_path}.")
        return {}


def update_cache(cache_path: Path, task_name: str, all_matches: List[TextMatch]):
    """Updates the cache file with the latest translations for a specific task."""
    try:
        full_cache: Dict[str, Dict[str, str]] = {}
        if cache_path.exists():
            with open(cache_path, "r", encoding="utf-8") as f:
                try:
                    full_cache = json.load(f)
                except json.JSONDecodeError:
                    logging.warning(
                        f"Cache file {cache_path} is corrupted. A new one will be created."
                    )

        # Create or update the cache for the current task
        task_cache = {
            calculate_checksum(match.original_text): match.translated_text
            for match in all_matches
            if match.translated_text is not None
        }
        full_cache[task_name] = task_cache

        # Write the updated cache back to the file
        cache_path.parent.mkdir(parents=True, exist_ok=True)
        with open(cache_path, "w", encoding="utf-8") as f:
            json.dump(full_cache, f, ensure_ascii=False, indent=4)

    except IOError as e:
        logging.error(f"Could not write to cache file at {cache_path}: {e}")


def create_token_based_batches(
    matches: List[TextMatch],
    model: GenerativeModel,
    batch_options: BatchOptions,
) -> List[List[TextMatch]]:
    """
    Creates batches of text matches based on token count to not exceed the provider's limit.

    Args:
        matches: A list of all text matches to be translated.
        model: The generative model instance used for counting tokens.
        batch_options: The batching configuration.

    Returns:
        A list of batches, where each batch is a list of TextMatch objects.
    """
    if not batch_options.enabled:
        return [matches] if matches else []

    batches: List[List[TextMatch]] = []
    current_batch: List[TextMatch] = []
    current_batch_tokens = 0

    for match in matches:
        # Estimate tokens for the current match
        match_tokens = model.count_tokens(match.original_text).total_tokens

        # Check if adding the match exceeds the token limit or batch size
        if current_batch and (
            (current_batch_tokens + match_tokens > batch_options.max_tokens_per_batch)
            or (len(current_batch) >= batch_options.batch_size)
        ):
            batches.append(current_batch)
            current_batch = []
            current_batch_tokens = 0

        current_batch.append(match)
        current_batch_tokens += match_tokens

    # Add the last batch if it's not empty
    if current_batch:
        batches.append(current_batch)

    logging.info(f"Created {len(batches)} batches based on token limits.")
    return batches


def _find_files(task: TranslationTask) -> Iterable[Path]:
    """Finds all files for a task, respecting includes and excludes."""
    base_path = Path.cwd()

    included_files = set()
    for pattern in task.source.include:
        for file_path in glob(str(base_path / pattern), recursive=True):
            included_files.add(Path(file_path))

    excluded_files = set()
    for pattern in task.exclude:
        for file_path in glob(str(base_path / pattern), recursive=True):
            excluded_files.add(Path(file_path))

    return sorted(included_files - excluded_files)


def _apply_regex_rewrites(content: str, task: TranslationTask) -> str:
    """Applies regex rewrites to the content before text extraction."""
    if not task.regex_rewrites:
        return content

    for pattern, replacement in task.regex_rewrites.items():
        try:
            content = regex.sub(pattern, replacement, content)
        except regex.error as e:
            logging.warning(
                f"Skipping invalid regex rewrite pattern '{pattern}' in task '{task.name}': {e}"
            )
    return content


def _extract_matches_from_content(
    content: str, file_path: Path, task: TranslationTask
) -> List[TextMatch]:
    """Extracts text matches from a single file's content based on extraction rules."""
    matches = []
    for rule_pattern in task.extraction_rules:
        try:
            for match in regex.finditer(rule_pattern, content, regex.MULTILINE):
                if match.groups():
                    matches.append(
                        TextMatch(
                            original_text=match.group(1),
                            source_file=file_path,
                            span=match.span(1),
                            task_name=task.name,
                        )
                    )
        except regex.error as e:
            logging.warning(
                f"Skipping invalid regex pattern '{rule_pattern}' in task '{task.name}': {e}"
            )
    return matches


def _detect_newline(file_path: Path) -> str | None:
    """Detects the newline character of a file."""
    try:
        with open(file_path, "r", encoding="utf-8", newline="") as f:
            f.readline()
            # isinstance check is robust for empty files where newlines is None
            if isinstance(f.newlines, tuple):
                # Handle mixed newlines if necessary, for now, take the first
                return f.newlines[0]
            return f.newlines
    except (IOError, IndexError):
        # Fallback if file is empty or unreadable
        return None


def capture_text_matches(
    task: TranslationTask, config: GlocalConfig
) -> List[TextMatch]:
    """
    Phase 1: Capture
    Finds all text fragments to be translated based on the task's rules.
    """
    all_matches = []
    files_to_process = list(_find_files(task))
    logging.info(f"Task '{task.name}': Found {len(files_to_process)} files to process.")

    for file_path in files_to_process:
        try:
            content = file_path.read_text("utf-8")
            content = _apply_regex_rewrites(content, task)
            file_matches = _extract_matches_from_content(content, file_path, task)
            all_matches.extend(file_matches)
        except IOError as e:
            logging.error(f"Could not read file {file_path}: {e}")
        except Exception as e:
            logging.error(
                f"An unexpected error occurred while processing {file_path}: {e}"
            )

    logging.info(f"Task '{task.name}': Captured {len(all_matches)} total text matches.")

    if config.debug_options.enabled:
        debug_messages = [
            f"[DEBUG] Captured: '{match.original_text}' from file {match.source_file} at span {match.span}"
            for match in all_matches
        ]

        if config.debug_options.log_path:
            log_dir = Path(config.debug_options.log_path)
            log_dir.mkdir(parents=True, exist_ok=True)
            log_file = log_dir / "glocaltext_debug.log"
            with open(log_file, "a", encoding="utf-8") as f:
                f.write("\n".join(debug_messages) + "\n")
            logging.info(f"Debug log saved to {log_file}")
        else:
            for msg in debug_messages:
                logging.info(msg)

    return all_matches


def _get_output_path(file_path: Path, task_output: Output) -> Path | None:
    """Determines the output path for a given file and task output settings."""
    if task_output.in_place:
        return file_path
    if task_output.path:
        output_dir = Path(task_output.path)
        return output_dir / file_path.name
    return None


def _write_modified_content(output_path: Path, content: str, newline: str | None):
    """
    Writes the modified content to the specified output path.
    This function is robust against cases where the parent directory path might
    exist as a file, a situation that can occur from previous failed runs.
    """
    # If the target parent directory exists as a file, remove it before creating the directory.
    if output_path.parent.is_file():
        logging.warning(
            f"Output directory path {output_path.parent} exists as a file. Deleting it to create directory."
        )
        output_path.parent.unlink()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, "utf-8", newline=newline)
    logging.info(f"Successfully wrote modified content to {output_path}")


def precise_write_back(matches: List[TextMatch], task_output: Output):
    """
    Phase 5: Write-back
    Writes translated text back to files with precision.
    """
    if not matches:
        logging.info("No matches with translated text to write back.")
        return

    matches_by_file: Dict[Path, List[TextMatch]] = {}
    for match in matches:
        if match.translated_text is not None:
            matches_by_file.setdefault(match.source_file, []).append(match)

    logging.info(f"Writing back translations for {len(matches_by_file)} files.")

    for file_path, file_matches in matches_by_file.items():
        try:
            file_matches.sort(key=lambda m: m.span[0], reverse=True)
            logging.info(
                f"Processing {file_path}: {len(file_matches)} translations to apply."
            )
            original_newline = _detect_newline(file_path)
            content = file_path.read_text("utf-8")

            for match in file_matches:
                start, end = match.span
                translated_text = match.translated_text or match.original_text
                content = content[:start] + translated_text + content[end:]

            output_path = _get_output_path(file_path, task_output)
            if output_path:
                _write_modified_content(output_path, content, newline=original_newline)
            else:
                logging.warning(
                    f"Output path is not defined for a non-in-place task. Skipping write-back for {file_path}."
                )

        except IOError as e:
            logging.error(f"Could not read or write file {file_path}: {e}")
        except Exception as e:
            logging.error(
                f"An unexpected error occurred during write-back for {file_path}: {e}"
            )


def run_task(
    task: TranslationTask,
    translators: Dict[str, BaseTranslator],
    config: GlocalConfig,
) -> List[TextMatch]:
    """
    Runs a single translation task from start to finish.
    Supports both full and incremental translation modes.
    """
    # Phase 1: Capture all text matches from source files.
    all_matches = capture_text_matches(task, config)

    if not task.incremental:
        # Full translation mode
        logging.info(f"Running task '{task.name}' in full translation mode.")
        process_matches(all_matches, translators, task, config)
    else:
        # Incremental translation mode
        logging.info(f"Running task '{task.name}' in incremental mode.")
        cache_path = get_cache_path(task.output)
        cache = load_cache(cache_path, task.name)
        logging.info(f"Loaded {len(cache)} items from cache for task '{task.name}'.")

        matches_to_translate = []
        cached_count = 0

        for match in all_matches:
            checksum = calculate_checksum(match.original_text)
            if checksum in cache:
                match.translated_text = cache[checksum]
                match.provider = "cached"
                cached_count += 1
            else:
                matches_to_translate.append(match)

        logging.info(f"Found {cached_count} translations in cache.")
        logging.info(
            f"Found {len(matches_to_translate)} new or modified texts to translate."
        )

        if matches_to_translate:
            process_matches(matches_to_translate, translators, task, config)

        # After processing, update the cache with all matches (including new ones)
        update_cache(cache_path, task.name, all_matches)

    # Phase 3: Write the translated content back to the files.
    if task.output:
        precise_write_back(all_matches, task.output)

    return all_matches
