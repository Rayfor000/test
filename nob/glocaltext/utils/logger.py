import logging
import sys
import time
from importlib import metadata


def setup_logger(level=logging.INFO):
    """
    Set up the logger.
    """
    try:
        # Dynamically get the version from pyproject.toml
        version = metadata.version("GlocalText")
    except metadata.PackageNotFoundError:
        # Fallback for when the package is not installed (e.g., in development)
        version = "0.0.0-dev"

    logger = logging.getLogger("glocaltext")
    logger.setLevel(level)

    # Create a handler
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(level)

    # Create a formatter and add it to the handler
    log_format = f"%(asctime)s | GlocalText - {version} - %(levelname)s - %(message)s"
    formatter = logging.Formatter(log_format, datefmt="%Y-%m-%dT%H:%M:%SZ")
    formatter.converter = time.gmtime
    handler.setFormatter(formatter)

    # Add the handler to the logger
    if not logger.handlers:
        logger.addHandler(handler)

    return logger
