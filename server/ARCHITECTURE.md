# AirFit Data Architecture

**CRITICAL: Read this before modifying sync logic or storage.**

This document explains the intentional data architecture decisions for AirFit, optimized for Raspberry Pi deployment (8GB RAM, 32GB SD card).

---

## The Golden Rule: Device-Primary, Server-Compute

```
iOS DEVICE (Source of Truth for User Data)
├── SwiftData: NutritionEntry[]     ← GRANULAR (each meal)
│                                     User entered it here.
│                                     Authoritative. Never delete.
├── HealthKit (Apple-owned)
│   └── Steps, calories, sleep, HRV, weight
│       Apple owns this. Device bridges to server.
│
└── Syncs DAILY AGGREGATES to server (not individual meals)
    Why: Pi storage efficiency. ~2KB/day is fine.
         Storing every meal = wasteful.

         ↓

RASPBERRY PI SERVER (Compute Layer + External APIs)
├── context_store.json (~200KB)
│   └── DailySnapshot[] keyed by date
│       ├── NutritionSnapshot (daily totals)
│       ├── HealthSnapshot (daily metrics)
│       └── WorkoutSnapshot (from Hevy)
│
├── exercise_history.json (~130KB)
│   └── Per-exercise strength progression (from Hevy)
│
├── profile.json (~3KB)
│   └── AI-extracted user profile (regenerable)
│
└── insights.json
    └── AI-generated insights (regenerable)
```

---

## Data Ownership Table

| Data Type | Owner | Stored On | Recovery Strategy |
|-----------|-------|-----------|-------------------|
| **Nutrition entries (meals)** | Device | SwiftData | Irreplaceable - backup device |
| Nutrition aggregates (daily) | Server | context_store.json | Device re-syncs |
| HealthKit metrics | Apple | HealthKit → Server | Device re-syncs |
| Hevy workouts | Server | context_store.json | Re-fetch from Hevy API |
| Exercise history | Server | exercise_history.json | Re-fetch from Hevy API |
| Profile | Server | profile.json | Regenerate from chat |
| Insights | Server | insights.json | Regenerate from data |

---

## Why NOT Store Granular Meals on Server?

1. **Storage efficiency**: Pi has 32GB SD card. Daily aggregates = ~2KB/day = ~7MB/year. Granular meals could be 10x more.

2. **Write wear**: SD cards have limited write cycles. Fewer writes = longer life.

3. **Redundancy is wasteful**: Device already has granular data. Why duplicate?

4. **Recovery**: If server dies, device can re-sync aggregates. Granular data stays safe on device.

5. **Privacy**: User data stays on device. Server only sees aggregates.

---

## What Can Be Regenerated?

| Data | Regenerable? | How |
|------|-------------|-----|
| Nutrition aggregates | Yes | Device re-syncs |
| Health aggregates | Yes | Device re-syncs |
| Hevy workouts | Yes | Re-fetch from Hevy API |
| Exercise history | Yes | Re-fetch from Hevy API |
| Profile | Yes | Re-extract from chat history |
| Insights | Yes | Re-run AI analysis on data |
| **Granular meals** | **NO** | Only exists on device |

**Key insight**: Only user-entered nutrition entries are irreplaceable. Everything else can be rebuilt.

---

## Sync Flow

```
iOS App
  │
  ├── User logs meal → NutritionEntry saved to SwiftData (GRANULAR)
  │
  ├── AutoSyncManager runs (every 15 min)
  │     │
  │     ├── Aggregates NutritionEntry by day
  │     │
  │     ├── Queries HealthKit for daily metrics
  │     │
  │     └── POSTs DailySyncData[] to /insights/sync
  │
  └── Server receives daily aggregates
        │
        └── Upserts into context_store.json
              │
              └── AI can analyze patterns
```

---

## Common Mistakes to Avoid

### ❌ DON'T: Store individual meals on server
```python
# WRONG - duplicates device data, wastes Pi storage
class MealEntry:
    name: str
    calories: int
    timestamp: datetime
```

### ✅ DO: Store daily aggregates
```python
# RIGHT - efficient, recoverable
class NutritionSnapshot:
    calories: int      # Daily total
    protein: int       # Daily total
    entry_count: int   # How many meals
```

### ❌ DON'T: Assume server has granular history
```swift
// WRONG - server doesn't store individual meals
let meals = try await apiClient.getMealsForDay(date)
```

### ✅ DO: Query device for granular data
```swift
// RIGHT - SwiftData has the meals
let meals = try modelContext.fetch(
    FetchDescriptor<NutritionEntry>(predicate: #Predicate { $0.date == date })
)
```

---

## Storage Growth Projections

| Timeframe | Size | Notes |
|-----------|------|-------|
| 1 month | 60-90 KB | ~2-3 KB/day |
| 1 year | ~1 MB | Sustainable |
| 10 years | ~11 MB | Still tiny |
| 10 users, 10 years | ~110 MB | 0.3% of 32GB |

**Conclusion**: Current architecture is optimal for Pi. No changes needed.

---

## File Reference

| File | Purpose | Owner |
|------|---------|-------|
| `context_store.py` | Daily aggregates CRUD | Server |
| `exercise_store.py` | Strength progression CRUD | Server |
| `scheduler.py` | Background sync jobs | Server |
| `AutoSyncManager.swift` | iOS → Server sync | Device |
| `InsightsSyncService.swift` | Aggregation logic | Device |

---

## Questions?

If you're unsure whether a change aligns with this architecture:
1. Ask: "Does device or server own this data?"
2. Ask: "Can this be regenerated if lost?"
3. Ask: "Does this increase Pi storage significantly?"

When in doubt, keep granular data on device, aggregates on server.
