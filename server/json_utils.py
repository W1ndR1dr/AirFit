"""JSON utilities for parsing LLM responses."""
import json
from typing import Optional, Any


def extract_json_from_text(text: str) -> Optional[dict]:
    """
    Extract a JSON object from LLM response text.

    Handles common LLM response formats:
    - Pure JSON
    - JSON wrapped in markdown code blocks
    - JSON embedded in explanatory text

    Uses brace matching to find the outermost JSON object.

    Args:
        text: The raw LLM response text

    Returns:
        Parsed JSON dict, or None if extraction fails
    """
    if not text:
        return None

    # Try to find JSON object
    start = text.find('{')
    if start == -1:
        return None

    # Find matching closing brace using depth tracking
    depth = 0
    end = start
    for i, char in enumerate(text[start:], start):
        if char == '{':
            depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0:
                end = i + 1
                break

    if depth != 0:
        return None  # Unbalanced braces

    try:
        return json.loads(text[start:end])
    except json.JSONDecodeError:
        return None


def extract_json_array_from_text(text: str) -> Optional[list]:
    """
    Extract a JSON array from LLM response text.

    Similar to extract_json_from_text but for arrays.

    Args:
        text: The raw LLM response text

    Returns:
        Parsed JSON list, or None if extraction fails
    """
    if not text:
        return None

    # Try to find JSON array
    start = text.find('[')
    if start == -1:
        return None

    # Find matching closing bracket using depth tracking
    depth = 0
    end = start
    for i, char in enumerate(text[start:], start):
        if char == '[':
            depth += 1
        elif char == ']':
            depth -= 1
            if depth == 0:
                end = i + 1
                break

    if depth != 0:
        return None  # Unbalanced brackets

    try:
        return json.loads(text[start:end])
    except json.JSONDecodeError:
        return None


def safe_int(value: Any, default: int = 0) -> int:
    """Safely convert a value to int with a default."""
    try:
        return int(value) if value is not None else default
    except (ValueError, TypeError):
        return default


def safe_float(value: Any, default: float = 0.0) -> float:
    """Safely convert a value to float with a default."""
    try:
        return float(value) if value is not None else default
    except (ValueError, TypeError):
        return default


def safe_str(value: Any, default: str = "") -> str:
    """Safely convert a value to str with a default."""
    return str(value) if value is not None else default
