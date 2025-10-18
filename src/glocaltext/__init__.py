import importlib.metadata

try:
    # Dynamically get the version from the installed package
    __version__ = importlib.metadata.version("GlocalText")
except importlib.metadata.PackageNotFoundError:
    # Fallback for when the package is not installed, e.g., in a development environment
    __version__ = "0.0.0-dev"
