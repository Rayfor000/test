import abc
from typing import List, Optional, Dict


class Translator(abc.ABC):
    """Abstract base class for all translators."""

    @abc.abstractmethod
    def __init__(self) -> None:
        """Initializes the translator."""
        raise NotImplementedError

    @abc.abstractmethod
    def translate(
        self,
        texts: List[str],
        target_language: str,
        source_language: str,
        glossary: Optional[Dict[str, str]] = None,
    ) -> List[str]:
        """
        Translates the given text.

        Args:
            texts: The text to translate.
            target_language: The target language.
            source_language: The source language.
            glossary: A dictionary of terms to not translate or to translate in a specific way.

        Returns:
            The translated text.
        """
        raise NotImplementedError
