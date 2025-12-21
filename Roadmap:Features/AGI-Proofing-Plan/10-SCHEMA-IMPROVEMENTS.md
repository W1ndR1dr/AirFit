# Schema Improvements Guide

## Overview

This guide documents the "cheap insurance" schema changes that cost almost nothing now but provide infinite future optionality. These are the load-bearing decisions from Patrick Collison's analysis.

---

## 1. Schema Versioning

### Rationale

Every data structure should carry a version number. This enables future migrations without breaking existing data.

> "5 minutes of work saves 50 hours later." — Patrick Collison

### Implementation

**File:** `server/context_store.py`

#### Before:
```python
@dataclass
class DailySnapshot:
    date: str
    nutrition: NutritionSnapshot
    health: HealthSnapshot
    workout: WorkoutSnapshot
```

#### After:
```python
@dataclass
class DailySnapshot:
    schema_version: int = 1  # ADD THIS
    date: str
    nutrition: NutritionSnapshot
    health: HealthSnapshot
    workout: WorkoutSnapshot
    extensions: dict = field(default_factory=dict)  # ADD THIS
```

### Apply to All Data Structures:

| File | Class | Add |
|------|-------|-----|
| `context_store.py` | `DailySnapshot` | `schema_version`, `extensions` |
| `context_store.py` | `NutritionSnapshot` | `schema_version` |
| `context_store.py` | `HealthSnapshot` | `schema_version` |
| `context_store.py` | `WorkoutSnapshot` | `schema_version` |
| `profile.py` | `UserProfile` | `schema_version` |
| `exercise_store.py` | `ExercisePerformance` | `schema_version` |

---

## 2. User ID Parameter

### Rationale

Make `user_id` first-class everywhere, even if always "default" today. Costs nothing, enables multi-user later.

### Implementation

**File:** `server/context_store.py`

#### Before:
```python
def load_store() -> ContextStore:
    ...

def get_snapshot(date_str: str) -> Optional[DailySnapshot]:
    ...
```

#### After:
```python
def load_store(user_id: str = "default") -> ContextStore:
    path = DATA_DIR / f"context_store_{user_id}.json"
    ...

def get_snapshot(user_id: str = "default", date_str: str) -> Optional[DailySnapshot]:
    store = load_store(user_id)
    ...
```

### Apply to All Functions:

| File | Functions to Update |
|------|---------------------|
| `context_store.py` | `load_store()`, `save_store()`, `get_snapshot()`, `update_snapshot()` |
| `profile.py` | `load_profile()`, `save_profile()`, `update_profile_from_conversation()` |
| `sessions.py` | `get_or_create_session()`, `clear_session()` |
| `memory.py` | `get_memory_context()`, `store_memories()`, `consolidate_memories()` |
| `exercise_store.py` | `load_store()`, `save_store()`, `get_exercise()` |

### Migration Path:

1. Rename existing files: `context_store.json` → `context_store_default.json`
2. Update code to use parameterized paths
3. No data migration needed

---

## 3. Extensions Dict

### Rationale

The `extensions` dict is an escape valve for future fields without schema changes.

### Example Use Cases:

```python
# Future: Track meditation
snapshot.extensions["meditation_minutes"] = 15

# Future: Track glucose (CGM)
snapshot.extensions["glucose_mg_dl"] = 95
snapshot.extensions["glucose_trend"] = "stable"

# Future: Track caffeine
snapshot.extensions["caffeine_mg"] = 200
```

### Implementation:

```python
@dataclass
class DailySnapshot:
    schema_version: int = 1
    date: str
    nutrition: NutritionSnapshot
    health: HealthSnapshot
    workout: WorkoutSnapshot
    extensions: dict = field(default_factory=dict)  # ADD THIS

    def get_extension(self, key: str, default=None):
        return self.extensions.get(key, default)

    def set_extension(self, key: str, value):
        self.extensions[key] = value
```

---

## 4. Flexible Macro Dict (Optional Enhancement)

### Rationale

Current nutrition is locked to 4 macros. A dict allows future nutrients.

### Current:
```python
@dataclass
class NutritionSnapshot:
    calories: int = 0
    protein: int = 0
    carbs: int = 0
    fat: int = 0
```

### Enhanced:
```python
@dataclass
class NutritionSnapshot:
    schema_version: int = 1
    macros: dict = field(default_factory=lambda: {
        "calories": 0,
        "protein": 0,
        "carbs": 0,
        "fat": 0
    })
    entry_count: int = 0

    # Convenience accessors for backward compatibility
    @property
    def calories(self) -> int:
        return self.macros.get("calories", 0)

    @property
    def protein(self) -> int:
        return self.macros.get("protein", 0)

    # etc.
```

### Migration:

This is more invasive than schema_version/user_id. **Consider deferring** until you actually need new macros (fiber, sodium, etc.).

---

## 5. Profile Seed Data Externalization

### Rationale

Profiles are data, not code. Move hardcoded profile out of Python.

### Current:
```python
# server/profile.py
def seed_brian_profile():
    profile = UserProfile()
    profile.name = "Brian"
    profile.age = 36
    # ... lots of hardcoded data
```

### Better:
```python
# server/profile.py
def import_profile(user_id: str, profile_path: Path) -> UserProfile:
    """Import a profile from JSON file."""
    with open(profile_path) as f:
        data = json.load(f)
    return UserProfile(**data)

def seed_profile(user_id: str = "default", seed_name: str = "brian"):
    """Load a seed profile by name."""
    seed_path = DATA_DIR / "seed_profiles" / f"{seed_name}.json"
    if seed_path.exists():
        return import_profile(user_id, seed_path)
    return UserProfile()
```

### File Structure:
```
server/data/
├── seed_profiles/
│   └── brian.json     # Brian's profile as JSON
├── context_store_default.json
├── profile_default.json
└── memories/
```

---

## 6. JSON Storage Format

### Rationale

Structure JSON so it could become Postgres rows later.

### Before:
```json
{
  "2024-12-19": {
    "nutrition": {...}
  }
}
```

### After:
```json
{
  "2024-12-19": {
    "user_id": "default",
    "schema_version": 1,
    "date": "2024-12-19",
    "nutrition": {...},
    "extensions": {}
  }
}
```

Every record having `user_id` and `schema_version` means future database migration is `INSERT INTO snapshots SELECT * FROM json_data`.

---

## 7. iOS Model Updates

### NutritionEntry.swift

```swift
@Model
final class NutritionEntry {
    var schemaVersion: Int = 1  // ADD
    var id: UUID
    var name: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var confidence: String
    var timestamp: Date
    var componentsData: Data?
    var extensions: [String: String]?  // ADD for future flexibility
}
```

### LocalProfile.swift

```swift
@Model
final class LocalProfile {
    var schemaVersion: Int = 1  // ADD
    // ... existing fields
    var extensions: [String: String]?  // ADD
}
```

---

## Implementation Priority

### Must Do (< 2 hours total):

| Change | Effort | Impact |
|--------|--------|--------|
| Add `schema_version` to all dataclasses | 30 min | Enables migrations |
| Add `user_id` parameter to all functions | 1 hour | Enables multi-user |
| Add `extensions` dict to snapshots | 15 min | Future field escape valve |

### Should Do (< 1 hour):

| Change | Effort | Impact |
|--------|--------|--------|
| Externalize profile seed to JSON | 30 min | Profiles as data |
| Update JSON format with user_id | 15 min | Database-ready format |

### Defer:

| Change | Reason |
|--------|--------|
| Flexible macro dict | More invasive, wait until needed |
| Full event sourcing | Significant effort, unclear value now |

---

## Summary

The "cheap insurance" changes are:

1. `schema_version` on everything (30 min)
2. `user_id` parameter everywhere (1 hour)
3. `extensions` dict on snapshots (15 min)
4. Externalize seed profiles (30 min)

**Total: ~2 hours for infinite future optionality.**
