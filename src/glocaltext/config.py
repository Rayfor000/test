import yaml
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Literal, Optional, Union


@dataclass
class ReportOptions:
    """Options for generating a summary report."""

    enabled: bool = True
    export_csv: bool = False
    export_dir: Optional[str] = None


@dataclass
class DebugOptions:
    """Options for debugging the translation process."""

    enabled: bool = False
    log_path: Optional[str] = None


@dataclass
class BatchOptions:
    """Batching settings for a provider."""

    enabled: bool = True
    batch_size: int = 20
    max_tokens_per_batch: int = 8000


@dataclass
class ProviderSettings:
    """Settings for a specific translation provider."""

    api_key: str | None = None
    model: str | None = None
    batch_options: BatchOptions = field(default_factory=BatchOptions)


@dataclass
class Output:
    """Defines the output behavior for a translation task."""

    in_place: bool = True
    path: str | None = None
    filename_suffix: Optional[str] = None
    # The 'filename_prefix' is included for backward compatibility with older configs.
    # It will be handled and converted to 'filename_suffix' in __post_init__.
    filename_prefix: Optional[str] = None

    def __post_init__(self):
        """Handles backward compatibility and validates attributes."""
        # If 'filename_prefix' is provided, use it to populate 'filename_suffix'
        # to maintain backward compatibility.
        if self.filename_prefix is not None:
            if self.filename_suffix is None:
                self.filename_suffix = self.filename_prefix

        # Original validation logic
        if self.in_place and self.path is not None:
            raise ValueError(
                "The 'path' attribute cannot be used when 'in_place' is True."
            )
        if not self.in_place and self.path is None:
            raise ValueError(
                "The 'path' attribute is required when 'in_place' is False."
            )


@dataclass
class MatchRule:
    """Defines the matching criteria for a rule."""

    exact: Optional[Union[str, List[str]]] = None
    contains: Optional[Union[str, List[str]]] = None

    def __post_init__(self):
        """Validates that either 'exact' or 'contains' is provided, but not both."""
        if self.exact is None and self.contains is None:
            raise ValueError(
                "Either 'exact' or 'contains' must be provided for a match rule."
            )
        if self.exact is not None and self.contains is not None:
            raise ValueError(
                "'exact' and 'contains' cannot be used simultaneously in a match rule."
            )


@dataclass
class ActionRule:
    """Defines the action to be taken when a rule matches."""

    action: Literal["skip", "replace", "modify"]
    value: Optional[str] = None

    def __init__(self, **kwargs):
        """
        Initializes the ActionRule with backward compatibility for 'type'.
        """
        # Provide backward compatibility for configs using 'type' instead of 'action'.
        if "type" in kwargs:
            kwargs["action"] = kwargs.pop("type")

        # Set attributes from kwargs
        for key, value in kwargs.items():
            setattr(self, key, value)

    def __post_init__(self):
        """Validates that 'value' is provided for actions that require it."""
        if self.action in ["replace", "modify"] and self.value is None:
            raise ValueError(
                f"The 'value' must be provided for the '{self.action}' action."
            )


@dataclass
class Rule:
    """
    A single rule combining a match condition and an action.
    This class is designed to be constructed from a dictionary,
    so the from_dict method in GlocalConfig will handle the nested instantiation.
    """

    match: MatchRule
    action: ActionRule

    def __init__(self, match: Dict[str, Any], action: Dict[str, Any]):
        self.match = MatchRule(**match)
        self.action = ActionRule(**action)


@dataclass
class Source:
    """Defines the source files for a translation task."""

    include: List[str] = field(default_factory=list)


@dataclass
class TranslationTask:
    """A single task defining what to translate and how."""

    name: str
    source_lang: str
    target_lang: str
    source: Source
    extraction_rules: List[str]
    translator: Optional[str] = None
    model: Optional[str] = None
    prompts: Dict[str, str] = field(default_factory=dict)
    enabled: bool = True
    exclude: List[str] = field(default_factory=list)
    output: Output = field(default_factory=Output)
    rules: List[Rule] = field(default_factory=list)
    regex_rewrites: Dict[str, str] = field(default_factory=dict)
    incremental: bool = False


@dataclass
class GlocalConfig:
    """The root configuration for GlocalText."""

    providers: Dict[str, ProviderSettings] = field(default_factory=dict)
    tasks: List[TranslationTask] = field(default_factory=list)
    debug_options: DebugOptions = field(default_factory=DebugOptions)
    report_options: ReportOptions = field(default_factory=ReportOptions)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "GlocalConfig":
        """Creates a GlocalConfig object from a dictionary, with validation."""

        providers_data = data.get("providers", {})
        providers = {
            p_name: ProviderSettings(
                api_key=p_config.get("api_key"),
                model=p_config.get("model"),
                batch_options=BatchOptions(**p_config.get("batch_options", {})),
            )
            for p_name, p_config in providers_data.items()
        }

        tasks_data = data.get("tasks", [])
        global_skip_translations = data.get("skip_translations", [])

        tasks = []
        for t in tasks_data:
            rules = [Rule(**r) for r in t.get("rules", [])]

            # Backward compatibility for 'manual_translations' (glossary)
            manual_translations = t.get("manual_translations", t.get("glossary", {}))
            for source, target in manual_translations.items():
                rules.append(
                    Rule(
                        match={"exact": source},
                        action={"action": "replace", "value": target},
                    )
                )

            # Backward compatibility for 'keyword_replacements'
            keyword_replacements = t.get("keyword_replacements", {})
            for keyword, replacement in keyword_replacements.items():
                rules.append(
                    Rule(
                        match={"contains": keyword},
                        action={"action": "modify", "value": replacement},
                    )
                )

            # Backward compatibility for global 'skip_translations'
            for text in global_skip_translations:
                rules.append(Rule(match={"exact": text}, action={"action": "skip"}))

            # Backward compatibility for task-level 'skip_translations'
            task_skip = t.get("skip_translations", [])
            for text in task_skip:
                rules.append(Rule(match={"exact": text}, action={"action": "skip"}))

            # Handle 'source' and backward compatibility with 'targets'
            source_data = t.get("source", {})
            if "targets" in t:
                source_data.setdefault("include", t["targets"])

            tasks.append(
                TranslationTask(
                    name=t.get("name", "Unnamed Task"),
                    enabled=t.get("enabled", True),
                    source_lang=t["source_lang"],
                    target_lang=t["target_lang"],
                    source=Source(**source_data),
                    translator=t.get("translator"),
                    model=t.get("model"),
                    prompts=t.get("prompts", {}),
                    exclude=t.get("exclude", []),
                    extraction_rules=t.get("extraction_rules", []),
                    output=Output(**t.get("output", {})),
                    rules=rules,
                    regex_rewrites=t.get("regex_rewrites", {}),
                    incremental=t.get("incremental", False),
                )
            )

        debug_options = DebugOptions(**data.get("debug_options", {}))
        report_options = ReportOptions(**data.get("report_options", {}))

        return cls(
            providers=providers,
            tasks=tasks,
            debug_options=debug_options,
            report_options=report_options,
        )


def load_config(config_path: str) -> GlocalConfig:
    """
    Loads, parses, and validates the YAML configuration file.

    Args:
        config_path: The path to the config.yaml file.

    Returns:
        A GlocalConfig object representing the validated configuration.

    Raises:
        FileNotFoundError: If the config file does not exist.
        yaml.YAMLError: If there is a syntax error in the YAML file.
        ValueError: If the configuration is invalid.
    """
    path = Path(config_path)
    if not path.is_file():
        raise FileNotFoundError(f"Configuration file not found at: {config_path}")

    try:
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)

        if not isinstance(data, dict):
            raise TypeError("Config file must be a YAML mapping (dictionary).")

        return GlocalConfig.from_dict(data)

    except yaml.YAMLError as e:
        raise yaml.YAMLError(f"Error parsing YAML config file: {e}")
    except (KeyError, TypeError, ValueError) as e:
        raise ValueError(f"Invalid or missing configuration: {e}")
