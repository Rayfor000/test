import os
import re
import xxhash
import typing
import logging
from pathlib import Path
from typing import Dict, Set, List, Tuple

from pydantic import BaseModel, Field

from glocaltext.core.config import I18nConfig

logger = logging.getLogger(__name__)


class ExtractedString(BaseModel):
    """
    Represents a single string extracted from a source file.
    """

    hash_id: str = Field(..., description="The xxhash of the text")
    text: str = Field(..., description="The actual extracted string")
    source_file: Path = Field(..., description="The file where it was found")
    line_number: int = Field(..., description="The line number where it was found")


class I18nProcessor:
    """
    Handles the extraction of user-visible strings from source files.
    """

    def __init__(self, config: I18nConfig, project_path: Path):
        """
        Initializes the processor with the given configuration and project path.

        Args:
            config: The internationalization configuration.
            project_path: The root path of the project to scan.
        """
        self.config = config
        self.project_path = project_path
        self.extracted_strings: Dict[str, ExtractedString] = {}
        self._processed_files: Set[Path] = set()
        logger.debug("I18nProcessor initialized")

    def get_processed_files(self) -> Set[Path]:
        """Returns the set of all file paths that were processed."""
        return self._processed_files

    def exclude_files_from_processing(
        self, relative_paths_to_exclude: Set[str], base_path: Path
    ):
        """
        Removes a set of files from the internal list of processed files.
        """
        absolute_paths_to_exclude = {
            base_path.resolve() / p for p in relative_paths_to_exclude
        }

        initial_count = len(self._processed_files)
        self._processed_files -= absolute_paths_to_exclude
        final_count = len(self._processed_files)

        if initial_count > final_count:
            logger.debug(
                f"Excluded {initial_count - final_count} protected files from processing."
            )

    def run(self) -> Dict[str, ExtractedString]:
        """
        Scans source files, extracts strings, and returns them.

        Returns:
            A dictionary mapping unique string hash IDs to ExtractedString objects.
        """
        logger.debug("Running I18nProcessor...")
        # 1. File Scanning
        original_cwd = Path.cwd()
        try:
            os.chdir(self.project_path)
            logger.debug(f"Changed directory to {self.project_path}")

            include_patterns = self.config.source.include
            logger.debug(f"Include patterns: {include_patterns}")
            files_to_scan: Set[Path] = {
                p.resolve()
                for pattern in include_patterns
                for p in Path().rglob(pattern)
            }
            logger.debug(
                f"Found {len(files_to_scan)} files to scan from include patterns."
            )

            exclude_patterns = self.config.source.exclude
            logger.debug(f"Exclude patterns: {exclude_patterns}")
            files_to_ignore: Set[Path] = {
                p.resolve()
                for pattern in exclude_patterns
                for p in Path().rglob(pattern)
            }
            logger.debug(
                f"Found {len(files_to_ignore)} files to ignore from exclude patterns."
            )

        finally:
            os.chdir(original_cwd)
            logger.debug(f"Changed directory back to {original_cwd}")

        filtered_files = files_to_scan - files_to_ignore
        logger.debug(f"Files after inclusion/exclusion: {len(filtered_files)}")

        # Exclude files within any .ogos directory
        self._processed_files = {p for p in filtered_files if ".ogos" not in p.parts}
        logger.debug(
            f"Final file count after excluding '.ogos' directories: {len(self._processed_files)}"
        )
        logger.info(f"Found {len(self._processed_files)} files to process.")

        # 2. String Extraction
        for file_path in self._processed_files:
            logger.debug(f"Processing file: {file_path}")
            try:
                original_content = file_path.read_text(encoding="utf-8")

                # Step 1: Find all character ranges to ignore.
                ignored_ranges: List[Tuple[int, int]] = []
                for rule in self.config.ignore_rules:
                    for match in re.finditer(
                        rule.pattern, original_content, re.DOTALL | re.MULTILINE
                    ):
                        ignored_ranges.append((match.start(), match.end()))

                # Step 2: Extract strings, but only if they don't fall within an ignored range.
                for rule in self.config.capture_rules:
                    for match in re.finditer(
                        rule.pattern, original_content, re.DOTALL | re.MULTILINE
                    ):
                        # Check if the entire match is within any ignored range.
                        is_ignored = False
                        for start, end in ignored_ranges:
                            if match.start() >= start and match.end() <= end:
                                logger.debug(
                                    f"  - Ignoring match '{match.group(0)[:50]}...' because it falls within an ignored range ({start}, {end})."
                                )
                                is_ignored = True
                                break
                        if is_ignored:
                            continue

                        try:
                            extracted_text = match.group(rule.capture_group)
                            line_number = (
                                original_content.count("\n", 0, match.start()) + 1
                            )
                            # Normalize f-string content for consistent hashing
                            normalized_text = re.sub(r"\{.*?\}", "{}", extracted_text)
                            hash_id = xxhash.xxh64(
                                normalized_text.encode("utf-8")
                            ).hexdigest()
                            logger.debug(
                                f"  - Extracted string: '{extracted_text[:50]}...' (Hash: {hash_id})"
                            )

                            if hash_id not in self.extracted_strings:
                                logger.debug(
                                    f"    - New unique string found. Adding to list."
                                )
                                self.extracted_strings[hash_id] = ExtractedString(
                                    hash_id=hash_id,
                                    text=extracted_text,
                                    source_file=file_path,
                                    line_number=line_number,
                                )
                            else:
                                logger.debug(f"    - String already exists. Skipping.")
                        except IndexError:
                            logger.error(
                                f"Capture group {rule.capture_group} not found for pattern {rule.pattern}"
                            )

            except (IOError, UnicodeDecodeError) as e:
                logger.error(f"Error processing file {file_path}: {e}")

        logger.info(f"Extracted {len(self.extracted_strings)} unique strings.")
        return self.extracted_strings

    def extract_raw_strings_from_file(self, file_path: Path) -> typing.List[str]:
        """
        Extracts a list of raw strings from a single file based on the configured rules.
        """
        raw_strings = []
        logger.debug(f"Extracting raw strings from: {file_path}")
        try:
            content = file_path.read_text(encoding="utf-8")

            # Note: sync does not currently use ignore_rules as it compares source and localized files directly.
            # This could be a future enhancement if needed.
            for rule in self.config.capture_rules:
                for match in re.finditer(
                    rule.pattern, content, re.DOTALL | re.MULTILINE
                ):
                    try:
                        extracted_text = match.group(rule.capture_group)
                        raw_strings.append(extracted_text)
                    except IndexError:
                        logger.error(
                            f"Capture group {rule.capture_group} not found for pattern {rule.pattern} in file {file_path}"
                        )
        except (IOError, UnicodeDecodeError) as e:
            logger.error(f"Error reading file {file_path}: {e}")
        return raw_strings

    def get_source_text(self, hash_id: str) -> typing.Optional[str]:
        """
        Retrieves the original source text for a given hash ID.

        Args:
            hash_id: The hash ID of the string to retrieve.

        Returns:
            The source text, or None if not found.
        """
        entry = self.extracted_strings.get(hash_id)
        return entry.text if entry else None

    def get_file_hash(self, file_path: Path) -> str:
        """Computes the xxhash of a file's content."""
        hasher = xxhash.xxh64()
        with open(file_path, "rb") as f:
            buf = f.read()
            hasher.update(buf)
        return hasher.hexdigest()
