# Multi-User Architecture Plan

> **Status:** Planned, not yet implemented
> **Users:** Brian, David, Jonathan
> **Estimated effort:** ~60-70 hours total (can be phased)

---

## Current State (Single-User)

All data is stored in single hardcoded files:
```
server/data/
├── profile.json          # One profile for everyone
├── sessions.json         # One session store
├── context_store.json    # One context store
└── insights.json         # One insights store
```

No user identification in API requests. Everything assumes a single user.

---

## Target Architecture (Multi-User)

### Data Directory Structure

```
server/data/
├── brian/
│   ├── profile.json
│   ├── context_store.json
│   ├── insights.json
│   └── exercise_store.json
├── david/
│   ├── profile.json
│   ├── context_store.json
│   ├── insights.json
│   └── exercise_store.json
├── jonathan/
│   └── ... (same structure)
└── sessions.json          # Shared, keyed by user_id:provider
```

### User Identification

**Method:** `X-User-ID` HTTP header on all requests

```swift
// iOS - APIClient.swift
var request = URLRequest(url: url)
request.setValue(currentUserId, forHTTPHeaderField: "X-User-ID")
```

```python
# Python - server.py
from fastapi import Header

@app.post("/chat")
async def chat(request: ChatRequest, x_user_id: str = Header(default="brian")):
    # x_user_id is extracted from header
    ...
```

**Security:** Acceptable for home network. If exposing externally, add API key validation.

---

## Implementation Phases

### Phase 1: Infrastructure (4-6 hours)

Create the foundation for user-aware data access.

**New file: `server/user_data.py`**
```python
from pathlib import Path

DATA_DIR = Path(__file__).parent / "data"
VALID_USERS = {"brian", "david", "jonathan"}

def get_user_data_dir(user_id: str) -> Path:
    """Get or create data directory for a user."""
    if user_id not in VALID_USERS:
        raise ValueError(f"Unknown user: {user_id}")

    user_dir = DATA_DIR / user_id
    user_dir.mkdir(parents=True, exist_ok=True)
    return user_dir

def get_user_file(user_id: str, filename: str) -> Path:
    """Get path to a user-specific data file."""
    return get_user_data_dir(user_id) / filename
```

**Modify: `server/sessions.py`**
- Already has `user_id` parameter structure
- Just need to ensure it's passed from API layer

---

### Phase 2: Profile Module (6-8 hours)

Make all profile functions user-aware.

**Modify: `server/profile.py`**

```python
# BEFORE
PROFILE_PATH = Path(__file__).parent / "data" / "profile.json"

def load_profile() -> UserProfile:
    if PROFILE_PATH.exists():
        ...

# AFTER
from user_data import get_user_file

def load_profile(user_id: str = "brian") -> UserProfile:
    profile_path = get_user_file(user_id, "profile.json")
    if profile_path.exists():
        ...

def save_profile(user_id: str, profile: UserProfile) -> None:
    profile_path = get_user_file(user_id, "profile.json")
    ...
```

**Functions to update:**
- `load_profile(user_id)`
- `save_profile(user_id, profile)`
- `get_profile_summary(user_id)`
- `clear_profile(user_id)`
- `update_profile_from_conversation(user_id, ...)`
- `extract_from_conversation(user_id, ...)`
- `generate_personality_notes(user_id, ...)`
- `finalize_onboarding(user_id, ...)`

**Migration:** Create `seed_david_profile()` and `seed_jonathan_profile()` or a generic `seed_profile(user_id, data)`.

---

### Phase 3: Context Store (10-12 hours)

Make all context storage user-aware.

**Modify: `server/context_store.py`**

```python
# BEFORE
CONTEXT_FILE = DATA_DIR / "context_store.json"
_cache: Optional["ContextStore"] = None

# AFTER
from user_data import get_user_file

# Per-user caches
_caches: dict[str, "ContextStore"] = {}
_cache_timestamps: dict[str, float] = {}

def load_store(user_id: str) -> "ContextStore":
    context_path = get_user_file(user_id, "context_store.json")
    ...

def save_store(user_id: str, store: "ContextStore") -> None:
    context_path = get_user_file(user_id, "context_store.json")
    ...
```

**Functions to update (40+):**
- `load_store(user_id)`
- `save_store(user_id, store)`
- `get_snapshot(user_id, date)`
- `upsert_snapshot(user_id, snapshot)`
- `get_recent_snapshots(user_id, days)`
- `add_insight(user_id, insight)`
- `get_insights(user_id, ...)`
- `format_body_comp_for_chat(user_id)`
- `compute_body_comp_trends(user_id)`
- ... and many more

**Key consideration:** Cache management needs to be per-user.

---

### Phase 4: API Endpoints (12-16 hours)

Add user identification to all endpoints.

**Option A: Header extraction per endpoint**
```python
@app.post("/chat")
async def chat(request: ChatRequest, x_user_id: str = Header(default="brian")):
    user_profile = profile.load_profile(x_user_id)
    context = await chat_context.build_chat_context(x_user_id, ...)
    ...
```

**Option B: Middleware (cleaner)**
```python
from fastapi import Request

@app.middleware("http")
async def add_user_id(request: Request, call_next):
    request.state.user_id = request.headers.get("X-User-ID", "brian")
    response = await call_next(request)
    return response

# Then in endpoints:
@app.post("/chat")
async def chat(request: ChatRequest, req: Request):
    user_id = req.state.user_id
    ...
```

**Endpoints to update (~30+):**
- `/chat` - user-specific profile and context
- `/profile` - user-specific profile
- `/profile/seed` - user-specific seeding
- `/insights/sync` - user-specific context store
- `/insights` - user-specific insights
- `/health/body-metrics` - user-specific data
- `/nutrition/parse` - stateless (no change needed)
- `/nutrition/status` - might need user targets
- `/training/*` - user-specific exercise history
- `/hevy/*` - might need user-specific API keys (future)

---

### Phase 5: Chat Context (4-6 hours)

Make context building user-aware.

**Modify: `server/chat_context.py`**

```python
# BEFORE
async def build_chat_context(
    health_context: Optional[dict] = None,
    nutrition_context: Optional[dict] = None,
    insights_limit: int = 3
) -> ChatContext:

# AFTER
async def build_chat_context(
    user_id: str,
    health_context: Optional[dict] = None,
    nutrition_context: Optional[dict] = None,
    insights_limit: int = 3
) -> ChatContext:
    context.insights = scheduler.get_insights_for_chat_context(user_id, limit=insights_limit)
    context.body_comp_trends = context_store.format_body_comp_for_chat(user_id)
    ...
```

---

### Phase 6: Supporting Modules (8-10 hours)

**`server/scheduler.py`**
- Background tasks need to run for each user
- Option A: Run insights generation for each user sequentially
- Option B: User-triggered only (not background)

```python
async def run_insight_generation(user_id: str, force: bool = False):
    # Generate insights for specific user
    ...

# Background task runs for all users
async def run_all_users_insight_generation():
    for user_id in VALID_USERS:
        await run_insight_generation(user_id)
```

**`server/insight_engine.py`**
- Add `user_id` parameter to all functions
- Load user-specific snapshots and profile

**`server/hevy.py`**
- Currently uses single API key from env
- Future: Per-user Hevy API keys (store in profile or separate secrets file)
- For now: Shared Hevy account is fine

---

### Phase 7: iOS App (4-6 hours)

**`AirFit/Services/APIClient.swift`**

```swift
actor APIClient {
    static let shared = APIClient()

    // NEW: Current user
    private var currentUserId: String = "brian"

    func setUser(_ userId: String) {
        currentUserId = userId
    }

    private func makeRequest<T: Encodable>(
        endpoint: String,
        method: String = "GET",
        body: T? = nil
    ) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = method

        // NEW: Add user header
        request.setValue(currentUserId, forHTTPHeaderField: "X-User-ID")

        ...
    }
}
```

**User switching UI:**
- Add user picker in Settings or Profile tab
- Store selected user in UserDefaults
- Set `APIClient.shared.setUser()` on app launch

---

## Migration Strategy

### For Existing Data (Brian's data)

```python
# One-time migration script
import shutil
from pathlib import Path

DATA_DIR = Path("server/data")
BRIAN_DIR = DATA_DIR / "brian"

# Create Brian's directory
BRIAN_DIR.mkdir(exist_ok=True)

# Move existing files
for file in ["profile.json", "context_store.json", "insights.json"]:
    src = DATA_DIR / file
    dst = BRIAN_DIR / file
    if src.exists():
        shutil.move(src, dst)
```

### For New Users (David, Jonathan)

Option A: Fresh onboarding through the app
Option B: Seed profiles programmatically (like `seed_brian_profile()`)
Option C: Copy Brian's profile as template, edit

---

## Testing Checklist

- [ ] Brian's data accessible only with `X-User-ID: brian`
- [ ] David's data accessible only with `X-User-ID: david`
- [ ] No data leakage between users
- [ ] Sessions isolated per user
- [ ] Insights generated per user
- [ ] Context store isolated per user
- [ ] Concurrent requests from different users work correctly
- [ ] Missing/invalid user_id handled gracefully (default or error)
- [ ] iOS app sends correct user header

---

## Future Enhancements

1. **Per-user Hevy API keys** - Each user connects their own Hevy account
2. **Per-user HealthKit data** - iOS already handles this (device-bound)
3. **API key authentication** - If exposing server externally
4. **User management endpoints** - Create/delete users via API
5. **Data export/import** - Backup user data

---

## Quick Reference: Files to Modify

| File | Changes | Priority |
|------|---------|----------|
| `server/user_data.py` | NEW - User data utilities | P0 |
| `server/profile.py` | Add user_id to all functions | P0 |
| `server/sessions.py` | Already has structure, wire it up | P0 |
| `server/context_store.py` | Add user_id to all functions | P1 |
| `server/server.py` | Add header extraction, pass user_id | P1 |
| `server/chat_context.py` | Add user_id parameter | P1 |
| `server/scheduler.py` | Per-user background tasks | P2 |
| `server/insight_engine.py` | Add user_id parameter | P2 |
| `AirFit/Services/APIClient.swift` | Add user header | P1 |
| `AirFit/Views/SettingsView.swift` | User picker UI | P2 |
