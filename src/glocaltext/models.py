from dataclasses import dataclass, field
from pathlib import Path
import uuid


@dataclass
class TextMatch:
    """
    Represents a piece of text extracted from a source file that is a candidate for translation.

    Attributes:
        original_text: The exact text captured by the extraction rule.
        source_file: The path to the file from which the text was extracted.
        span: A tuple (start, end) indicating the character position of the text in the source file.
        match_id: A unique identifier for this specific match instance.
        task_name: The name of the task this match belongs to.
        translated_text: The translated text. None if not yet translated.
        provider: The translation provider used (e.g., 'gemini', 'google', 'manual').
        tokens_used: The number of tokens consumed for the translation by an AI provider.
    """

    original_text: str
    source_file: Path
    span: tuple[int, int]
    task_name: str
    translated_text: str | None = None
    provider: str | None = None
    tokens_used: int | None = None
    # A unique ID is generated for each match instance to distinguish it from others,
    # even if they have the same text and location (e.g., from different tasks).
    match_id: str = field(
        default_factory=lambda: str(uuid.uuid4()), init=False, repr=False
    )

    def __hash__(self):
        # Hash based on the unique identifier of the match instance.
        return hash(self.match_id)

    def __eq__(self, other):
        # Equality is based on the unique identifier.
        if not isinstance(other, TextMatch):
            return NotImplemented
        return self.match_id == other.match_id

    def to_dict(self):
        """Converts the dataclass instance to a JSON-serializable dictionary."""
        return {
            "match_id": self.match_id,
            "original_text": self.original_text,
            "task_name": self.task_name,
            "translated_text": self.translated_text,
            "source_file": str(self.source_file),
            "span": self.span,
            "provider": self.provider,
            "tokens_used": self.tokens_used,
        }


@dataclass
class TranslationResult:
    """Represents the result of a translation for a single text."""

    translated_text: str
    tokens_used: int | None = None
