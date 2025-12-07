"""Server configuration - reads from environment or uses defaults."""
import os
from pathlib import Path

# Server settings
HOST = os.getenv("AIRFIT_HOST", "0.0.0.0")
PORT = int(os.getenv("AIRFIT_PORT", "8080"))

# CLI paths (will search PATH if not specified)
CLAUDE_CLI = os.getenv("CLAUDE_CLI", "claude")
GEMINI_CLI = os.getenv("GEMINI_CLI", "gemini")
CODEX_CLI = os.getenv("CODEX_CLI", "codex")

# Timeouts
CLI_TIMEOUT = int(os.getenv("CLI_TIMEOUT", "120"))  # seconds

# Provider priority (comma-separated)
PROVIDERS = os.getenv("AIRFIT_PROVIDERS", "claude,gemini,codex").split(",")

# Data directory for storing custom instructions, etc.
DATA_DIR = Path(os.getenv("AIRFIT_DATA_DIR", Path.home() / ".airfit"))
DATA_DIR.mkdir(parents=True, exist_ok=True)
