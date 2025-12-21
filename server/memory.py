"""AI-native memory system - relationship texture and callbacks.

This module simulates Anthropic's Memory Tool using file-based storage.
Claude decides what's memorable via explicit markers in responses.

Design principles:
1. Let Claude decide what's memorable - no rigid schemas
2. Markdown format - human-readable, Claude-native
3. Selective memory - only genuinely relationship-building moments
4. Complements profile.py (structured facts) with relationship texture
"""

import re
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional

import llm_router

# Memory storage directory
MEMORY_DIR = Path(__file__).parent / "data" / "memories"

# Pattern to match memory markers in Claude's responses
# Supports: <memory:remember>, <memory:callback>, <memory:tone>, <memory:thread>
MEMORY_PATTERN = re.compile(r'<memory:(\w+)>(.*?)</memory:\1>', re.DOTALL)

# Memory protocol instructions for system prompt
MEMORY_PROTOCOL = """
MEMORY PROTOCOL:
You have relationship memory from past conversations. Use it naturally:
- Reference callbacks and inside jokes when they fit organically
- Build on established threads and ongoing topics
- Maintain the communication style that's worked

When something genuinely memorable happens (1-3 per conversation max), mark it:
<memory:remember>What to remember about this exchange</memory:remember>
<memory:callback>A phrase/joke that could be referenced later</memory:callback>
<memory:tone>Observation about what communication style worked</memory:tone>
<memory:thread>Topic to follow up on in future sessions</memory:thread>

Be selective - only mark genuinely relationship-building moments, not every fact.
Don't force callbacks. Use memories when they fit naturally.
"""


def ensure_memory_dir():
    """Create memory directory structure if needed."""
    MEMORY_DIR.mkdir(parents=True, exist_ok=True)
    (MEMORY_DIR / "session_notes").mkdir(exist_ok=True)

    # Initialize index.md if missing
    index_path = MEMORY_DIR / "index.md"
    if not index_path.exists():
        index_path.write_text("""# Memory Index

Last updated: (not yet)

## Quick Reference
(Populated from conversations)

## Active Threads
(None yet)

## Recent Callbacks
(None yet)
""")

    # Initialize relationship.md if missing
    relationship_path = MEMORY_DIR / "relationship.md"
    if not relationship_path.exists():
        relationship_path.write_text("""# Relationship Memory

## Inside Jokes & Callbacks
(None yet)

## Communication Calibration
### What Works
(Observing...)

### What Doesn't Work
(Observing...)

## Memorable Exchanges
(None yet)
""")


def read_memory_file(filename: str) -> Optional[str]:
    """Read a memory file, return None if not found."""
    ensure_memory_dir()
    path = MEMORY_DIR / filename
    if path.exists():
        return path.read_text()
    return None


def write_memory_file(filename: str, content: str):
    """Write content to a memory file."""
    ensure_memory_dir()
    path = MEMORY_DIR / filename
    path.write_text(content)


def get_memory_context() -> str:
    """Assemble memory context for system prompt injection.

    Returns formatted string with relationship memory for Claude to reference.
    Prioritizes recent and high-value memories.
    """
    ensure_memory_dir()
    parts = []

    # 1. Index - quick reference (always include)
    index = read_memory_file("index.md")
    if index and len(index) > 50:  # Has content beyond template
        parts.append(index)

    # 2. Relationship memory - callbacks, inside jokes, tone calibration
    relationship = read_memory_file("relationship.md")
    if relationship and len(relationship) > 100:  # Has content beyond template
        # Cap at ~1500 chars to avoid bloating context
        parts.append(relationship[:3000])

    # 3. Today's session notes if they exist
    today = datetime.now().strftime("%Y-%m-%d")
    session_notes = read_memory_file(f"session_notes/{today}.md")
    if session_notes:
        parts.append(f"## Today's Session\n{session_notes}")

    if not parts:
        return ""

    return "\n\n".join(parts)


def store_memories(mem_type: str, contents: list[str]) -> int:
    """Store pre-extracted memory markers from iOS.

    iOS extracts markers locally and syncs them to server for backup.
    This allows provider parity - both Claude and Gemini responses
    update the same memory store.

    Args:
        mem_type: One of "remember", "callback", "tone", "thread"
        contents: List of memory content strings

    Returns count of memories stored.
    """
    if not contents:
        return 0

    ensure_memory_dir()

    today = datetime.now().strftime("%Y-%m-%d")
    date_display = datetime.now().strftime("%b %d")

    # Append to relationship.md
    relationship_path = MEMORY_DIR / "relationship.md"

    new_entries = []
    for item in contents:
        item = item.strip()
        if not item:
            continue
        if mem_type == "callback":
            new_entries.append(f"\n### {date_display} - Callback\n- {item}")
        elif mem_type == "tone":
            new_entries.append(f"\n### {date_display} - Tone Calibration\n- {item}")
        elif mem_type == "thread":
            new_entries.append(f"\n### {date_display} - Active Thread\n- {item}")
        else:  # remember
            new_entries.append(f"\n### {date_display} - Memorable\n- {item}")

    if new_entries:
        with open(relationship_path, 'a') as f:
            f.write("\n" + "\n".join(new_entries))

    # Also append to today's session notes
    session_dir = MEMORY_DIR / "session_notes"
    session_dir.mkdir(exist_ok=True)
    session_path = session_dir / f"{today}.md"
    with open(session_path, 'a') as f:
        for item in contents:
            item = item.strip()
            if item:
                f.write(f"\n- [{mem_type}] {item}")

    return len([c for c in contents if c.strip()])


def extract_and_store_memories(response_text: str) -> int:
    """Extract memory markers from response and store them.

    Parses <memory:type>content</memory:type> markers from Claude's response
    and appends them to the appropriate memory files.

    Returns count of memories stored.
    """
    ensure_memory_dir()

    matches = MEMORY_PATTERN.findall(response_text)
    if not matches:
        return 0

    timestamp = datetime.now().isoformat()
    today = datetime.now().strftime("%Y-%m-%d")
    date_display = datetime.now().strftime("%b %d")

    # Group by type
    memories_by_type: dict[str, list[str]] = {}
    for mem_type, content in matches:
        content = content.strip()
        if content:  # Skip empty markers
            memories_by_type.setdefault(mem_type, []).append(content)

    if not memories_by_type:
        return 0

    # Append to relationship.md
    relationship_path = MEMORY_DIR / "relationship.md"
    relationship_content = relationship_path.read_text() if relationship_path.exists() else ""

    new_entries = []
    for mem_type, items in memories_by_type.items():
        for item in items:
            if mem_type == "callback":
                new_entries.append(f"\n### {date_display} - Callback\n- {item}")
            elif mem_type == "tone":
                new_entries.append(f"\n### {date_display} - Tone Calibration\n- {item}")
            elif mem_type == "thread":
                new_entries.append(f"\n### {date_display} - Active Thread\n- {item}")
            else:  # remember
                new_entries.append(f"\n### {date_display} - Memorable\n- {item}")

    # Append new entries to relationship.md
    if new_entries:
        with open(relationship_path, 'a') as f:
            f.write("\n" + "\n".join(new_entries))

    # Update index with latest callbacks
    update_index_recent(matches, date_display)

    # Also append to today's session notes
    session_path = MEMORY_DIR / "session_notes" / f"{today}.md"
    with open(session_path, 'a') as f:
        for mem_type, items in memories_by_type.items():
            for item in items:
                f.write(f"\n- [{mem_type}] {item}")

    return len(matches)


def update_index_recent(matches: list[tuple[str, str]], date_display: str):
    """Update the index.md with recent callbacks and threads."""
    index_path = MEMORY_DIR / "index.md"
    if not index_path.exists():
        ensure_memory_dir()
        return

    index = index_path.read_text()

    # Update timestamp
    now = datetime.now().isoformat()
    index = re.sub(
        r"Last updated: .*",
        f"Last updated: {now}",
        index
    )

    # Extract callbacks and threads from matches
    callbacks = [m[1].strip()[:60] for m in matches if m[0] == "callback"]
    threads = [m[1].strip()[:60] for m in matches if m[0] == "thread"]

    # Add to Recent Callbacks section
    if callbacks:
        callback_entries = "\n".join([f"- {date_display}: {c}" for c in callbacks])
        if "## Recent Callbacks" in index:
            # Insert after header
            index = index.replace(
                "## Recent Callbacks\n",
                f"## Recent Callbacks\n{callback_entries}\n"
            )

    # Add to Active Threads section
    if threads:
        thread_entries = "\n".join([f"- {t}" for t in threads])
        if "## Active Threads" in index:
            index = index.replace(
                "## Active Threads\n",
                f"## Active Threads\n{thread_entries}\n"
            )

    index_path.write_text(index)


def strip_memory_markers(text: str) -> str:
    """Remove memory markers from response before sending to user.

    The markers are for internal storage only - user shouldn't see them.
    """
    # Remove markers but keep any text around them
    cleaned = MEMORY_PATTERN.sub('', text)
    # Clean up extra whitespace from removed markers
    cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
    return cleaned.strip()


def get_all_memories() -> dict:
    """Get all memory files for API/UI display.

    Returns dict with all memory file contents.
    """
    ensure_memory_dir()

    result = {
        "index": read_memory_file("index.md") or "",
        "relationship": read_memory_file("relationship.md") or "",
        "session_notes": {}
    }

    # Get all session notes
    session_dir = MEMORY_DIR / "session_notes"
    if session_dir.exists():
        for note_file in session_dir.glob("*.md"):
            date_str = note_file.stem
            result["session_notes"][date_str] = note_file.read_text()

    return result


def update_memory_file(filename: str, content: str) -> bool:
    """Update a specific memory file.

    Used by API for user edits.
    Returns True if successful.
    """
    ensure_memory_dir()

    # Validate filename (security)
    if ".." in filename or filename.startswith("/"):
        return False

    # Only allow known file patterns
    allowed_patterns = ["index.md", "relationship.md", "tone_calibration.md"]
    if filename not in allowed_patterns and not filename.startswith("session_notes/"):
        return False

    path = MEMORY_DIR / filename
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return True


def delete_memory_file(filename: str) -> bool:
    """Delete a specific memory file.

    Returns True if deleted, False if not found or not allowed.
    """
    ensure_memory_dir()

    # Validate filename (security)
    if ".." in filename or filename.startswith("/"):
        return False

    path = MEMORY_DIR / filename
    if path.exists() and path.is_file():
        path.unlink()
        return True
    return False


def clear_all_memories() -> int:
    """Clear all memory files.

    Returns count of files deleted.
    """
    ensure_memory_dir()
    count = 0

    # Clear main files
    for filename in ["index.md", "relationship.md", "tone_calibration.md"]:
        path = MEMORY_DIR / filename
        if path.exists():
            path.unlink()
            count += 1

    # Clear session notes
    session_dir = MEMORY_DIR / "session_notes"
    if session_dir.exists():
        for note_file in session_dir.glob("*.md"):
            note_file.unlink()
            count += 1

    # Reinitialize empty files
    ensure_memory_dir()

    return count


CONSOLIDATION_PROMPT = """You are consolidating relationship memories for an AI fitness coach.

Your job is to take raw memory entries (callbacks, threads, tone observations, memorable moments)
and distill them into a clean, organized relationship memory file.

PRINCIPLES:
- Keep what builds relationship texture (inside jokes, callbacks, personality observations)
- Merge redundant entries - if the same callback appears 3 times, keep one
- Preserve specificity - "dark humor lands well" is better than "humor works"
- Active threads should be current - drop completed or stale ones
- Tone calibrations should be actionable - what actually works with this person

OUTPUT FORMAT (markdown):

# Relationship Memory

## Inside Jokes & Callbacks
(Phrases, references, running jokes to use naturally)
- [callback with brief context if needed]

## Communication Calibration
### What Works
- [specific observation]

### What Doesn't Work
- [specific observation]

## Active Threads
(Topics to follow up on - remove if resolved)
- [thread]

## Memorable Exchanges
(Key moments that shaped the relationship)
- [date]: [brief description]

Keep it tight - this goes into the system prompt. Max ~50 lines.
Remove anything that's:
- Redundant (duplicate info)
- Stale (old threads that are clearly resolved)
- Too generic (could apply to anyone)
- Already captured in profile.py (structured facts belong there, not here)"""


async def consolidate_memories() -> dict:
    """Periodically consolidate and organize memories.

    Called by scheduler to:
    - Summarize old session notes (older than 7 days)
    - Clean up redundant entries via LLM
    - Update index.md with patterns

    Returns dict with consolidation stats.
    """
    ensure_memory_dir()
    stats = {"archived": 0, "consolidated": False, "error": None}

    session_dir = MEMORY_DIR / "session_notes"
    cutoff_date = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")

    # Collect old session notes for archival
    old_notes = []
    if session_dir.exists():
        for note_file in sorted(session_dir.glob("*.md")):
            date_str = note_file.stem
            if date_str < cutoff_date:
                content = note_file.read_text().strip()
                if content:
                    old_notes.append(f"### {date_str}\n{content}")
                note_file.unlink()
                stats["archived"] += 1

    # Read current relationship memory
    relationship_content = read_memory_file("relationship.md") or ""

    # If we have old notes or relationship file is getting long, consolidate
    total_content = relationship_content + "\n".join(old_notes)
    if len(total_content) < 500:
        # Not enough content to bother consolidating
        return stats

    # Build consolidation prompt
    prompt = f"""Here are the current relationship memories to consolidate:

{relationship_content}

{'--- OLD SESSION NOTES TO INCORPORATE ---' if old_notes else ''}
{chr(10).join(old_notes) if old_notes else ''}

Consolidate these into a clean, organized relationship memory file.
Remove redundancy, keep what matters for the coaching relationship."""

    result = await llm_router.chat(prompt, CONSOLIDATION_PROMPT, use_session=False)

    if result.success and result.text.strip():
        # Clean up response - remove markdown code blocks if present
        consolidated = result.text.strip()
        if consolidated.startswith("```"):
            lines = consolidated.split("\n")
            # Remove first and last lines if they're code block markers
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            consolidated = "\n".join(lines)

        # Write consolidated relationship memory
        write_memory_file("relationship.md", consolidated)
        stats["consolidated"] = True

        # Update index with consolidation timestamp
        index_content = read_memory_file("index.md") or ""
        now = datetime.now().isoformat()
        index_content = re.sub(
            r"Last updated: .*",
            f"Last updated: {now} (consolidated)",
            index_content
        )
        write_memory_file("index.md", index_content)
    else:
        stats["error"] = result.error or "Empty response from LLM"

    return stats
