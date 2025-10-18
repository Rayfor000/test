import argparse
import logging
import time
from .config import load_config
from .workflow import run_task
from .translate import initialize_translators
from .reporting import generate_summary_report


def main():
    """Main entry point for the GlocalText CLI."""
    start_time = time.time()

    parser = argparse.ArgumentParser(description="GlocalText Localization Tool")
    parser.add_argument(
        "-c",
        "--config",
        default="config.yaml",
        help="Path to the configuration file (default: config.yaml)",
    )
    parser.add_argument(
        "--incremental",
        action="store_true",
        help="Run in incremental mode, translating only new or modified content.",
    )
    parser.add_argument(
        "--debug",
        nargs="?",
        const=True,
        default=False,
        help="Enable debug logging. Optionally provide a directory path to save the debug log file.",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
    )

    try:
        config = load_config(args.config)

        if args.debug:
            config.debug_options.enabled = True
            if isinstance(args.debug, str):
                config.debug_options.log_path = args.debug

        translators = initialize_translators(config)

        all_matches = []
        for task in config.tasks:
            if task.enabled:
                if args.incremental:
                    task.incremental = True
                logging.info(f"\n--- Running Task: {task.name} ---")
                task_matches = run_task(task, translators, config)
                all_matches.extend(task_matches)
                logging.info(f"--- Task Finished: {task.name} ---")

        generate_summary_report(all_matches, start_time, config)

    except FileNotFoundError:
        logging.error(f"Configuration file not found at: {args.config}")
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}", exc_info=True)

    logging.info("\nAll tasks completed.")


if __name__ == "__main__":
    main()
