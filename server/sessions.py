"""Session management for conversation continuity."""
import json
import uuid
from pathlib import Path
from datetime import datetime
from typing import Optional
from dataclasses import dataclass, asdict


SESSIONS_PATH = Path(__file__).parent / "data" / "sessions.json"


@dataclass
class Session:
    """A conversation session."""
    session_id: str
    provider: str  # "claude", "gemini", etc.
    created_at: str
    last_used: str
    message_count: int = 0


def _load_sessions() -> dict[str, Session]:
    """Load sessions from disk."""
    if not SESSIONS_PATH.exists():
        return {}
    try:
        data = json.loads(SESSIONS_PATH.read_text())
        return {k: Session(**v) for k, v in data.items()}
    except (json.JSONDecodeError, TypeError):
        return {}


def _save_sessions(sessions: dict[str, Session]) -> None:
    """Save sessions to disk."""
    SESSIONS_PATH.parent.mkdir(parents=True, exist_ok=True)
    data = {k: asdict(v) for k, v in sessions.items()}
    SESSIONS_PATH.write_text(json.dumps(data, indent=2))


def get_or_create_session(user_id: str = "default", provider: str = "claude") -> Session:
    """
    Get existing session for user/provider, or create a new one.

    For now, we use a single session per user per provider.
    This gives conversation continuity within the app.
    """
    sessions = _load_sessions()
    key = f"{user_id}:{provider}"

    if key in sessions:
        session = sessions[key]
        session.last_used = datetime.now().isoformat()
        session.message_count += 1
        _save_sessions(sessions)
        return session

    # Create new session
    session = Session(
        session_id=str(uuid.uuid4()),
        provider=provider,
        created_at=datetime.now().isoformat(),
        last_used=datetime.now().isoformat(),
        message_count=1
    )
    sessions[key] = session
    _save_sessions(sessions)
    return session


def clear_session(user_id: str = "default", provider: str = "claude") -> bool:
    """Clear a session to start fresh."""
    sessions = _load_sessions()
    key = f"{user_id}:{provider}"

    if key in sessions:
        del sessions[key]
        _save_sessions(sessions)
        return True
    return False


def clear_all_sessions() -> int:
    """Clear all sessions. Returns count of cleared sessions."""
    sessions = _load_sessions()
    count = len(sessions)
    _save_sessions({})
    return count


def get_session_info(user_id: str = "default", provider: str = "claude") -> Optional[Session]:
    """Get info about a session without modifying it."""
    sessions = _load_sessions()
    key = f"{user_id}:{provider}"
    return sessions.get(key)
