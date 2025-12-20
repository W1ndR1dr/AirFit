# Running, Cardio & Universal HealthKit Features

**Date:** December 18, 2025
**Context:** Expanding AirFit beyond lifting to support running (and brothers who may not have Hevy)

---

## The Opportunity

AirFit is currently lifting-centric because Hevy provides rich workout data. But HealthKit already has everything needed for a complete cardio/running experience:

### Data Already Available (Permissions Requested)

| Metric | Source | Currently Used? |
|--------|--------|-----------------|
| Distance (run/walk/cycle/swim) | Apple Watch | ❌ No |
| Running speed | Apple Watch | ❌ No |
| Running stride length | Apple Watch | ❌ No |
| Running ground contact time | Apple Watch | ❌ No |
| Running vertical oscillation | Apple Watch | ❌ No |
| VO2 max | Apple Watch | ❌ No |
| Heart rate during workout | Apple Watch | ❌ No |
| Heart rate recovery (1 min) | Apple Watch | ❌ No |
| Cycling cadence/speed | Apple Watch | ❌ No |
| All workout types | Apple Watch | ✅ Basic only |

**This is a treasure trove sitting unused.**

---

## Part I: Running-Specific Features

### 1. **Weekly/Monthly Mileage Dashboard**

**What:** Track running volume over time with trendlines (just like lifting volume).

**Visualization:**
```
This Week: 18.2 mi (↑12% vs last week)
─────────────────────────────
[Sparkline: last 12 weeks of weekly mileage]
─────────────────────────────
Mon  Tue  Wed  Thu  Fri  Sat  Sun
3.1  —    4.0  —    —    6.2  4.9
```

**Implementation:**
- Query `HKQuantityType(.distanceWalkingRunning)` by day
- Aggregate into weekly totals
- LOESS smoothing for trend (same as weight charts)
- Year-over-year comparison: "You ran 847 miles in 2024 vs 623 in 2023"

**Why it matters:** Runners think in miles per week. This is their volume metric like "sets per muscle group" for lifters.

---

### 2. **Pace Progression Chart**

**What:** Track whether you're getting faster over time.

**Visualization:**
```
Average Pace (last 90 days)
─────────────────────────────────────
[Chart: pace (min/mi) over time, LOESS smoothed]
Current: 8:42/mi  |  90 days ago: 9:15/mi
Improvement: 33 sec/mi (↓6%)
```

**Implementation:**
- Query running workouts from HealthKit
- Calculate pace = duration / distance for each run
- Plot over time with LOESS smoothing
- Segment by run type if possible (easy vs tempo vs long)

**Why it matters:** Runners want to know "Am I getting faster?" This answers it definitively.

---

### 3. **VO2 Max Trend Chart**

**What:** Apple Watch estimates VO2 max from outdoor runs. This is the single best indicator of cardiorespiratory fitness.

**Visualization:**
```
VO2 Max (Cardio Fitness)
─────────────────────────────────────
[Chart: VO2 max over time]
Current: 44.2 ml/kg/min  |  Zone: Above Average
Year change: +3.1 (↑7.5%)
```

**Reference zones by age/gender:**
- Excellent: >50 (men 30-39)
- Good: 43-50
- Average: 36-42
- Below Average: <36

**Implementation:**
- Query `HKQuantityType(.vo2Max)` history
- Plot with LOESS smoothing
- Show zone coloring
- Correlate with training volume

**Why it matters:** VO2 max correlates with all-cause mortality better than almost any other metric. Watching it improve is deeply motivating.

---

### 4. **Running Form Analysis**

**What:** Apple Watch tracks stride metrics during runs. Surface them meaningfully.

**Metrics:**
- **Stride length:** Longer = usually more efficient (at same cadence)
- **Ground contact time:** Shorter = more efficient
- **Vertical oscillation:** Lower = more efficient (less energy wasted bouncing)
- **Cadence:** 180 spm is often cited as "optimal"

**Visualization:**
```
Running Form (Last 30 Days)
─────────────────────────────────────
Cadence         178 spm    [progress bar]  Optimal: 180
Ground Contact  248 ms     [progress bar]  Elite: <220
Vertical Osc.   8.2 cm     [progress bar]  Elite: <6
Stride Length   1.12 m     [progress bar]  Personal best
```

**Implementation:**
- Query running biomechanics from HealthKit
- Calculate averages over recent runs
- Show trends (improving form?)
- Provide coaching tips ("Your ground contact time improved 5% this month—you're running more efficiently")

**Why it matters:** Runners obsess over form. This data exists—show it.

---

### 5. **Heart Rate Zone Distribution**

**What:** Show time spent in each HR zone during runs.

**Zones (standard 5-zone model):**
- Zone 1 (50-60% max HR): Recovery
- Zone 2 (60-70%): Easy/Aerobic base
- Zone 3 (70-80%): Tempo
- Zone 4 (80-90%): Threshold
- Zone 5 (90-100%): VO2 max/Sprint

**Visualization:**
```
This Week's Running HR Distribution
─────────────────────────────────────
Z1 ████░░░░░░░░░░░░░░░░  12%  (45 min)
Z2 ██████████████░░░░░░  58%  (2:10)
Z3 █████░░░░░░░░░░░░░░░  18%  (42 min)
Z4 ██░░░░░░░░░░░░░░░░░░   9%  (21 min)
Z5 █░░░░░░░░░░░░░░░░░░░   3%  (8 min)
```

**Implementation:**
- Query heart rate samples during running workouts
- Calculate max HR (220 - age, or from profile)
- Bucket time into zones
- Track weekly/monthly distribution

**Why it matters:** "80/20" training (80% easy, 20% hard) is evidence-based. This shows if you're following it.

---

### 6. **Race Time Predictor**

**What:** Based on recent training, predict finish times for common distances.

**Distances:**
- 5K
- 10K
- Half Marathon
- Marathon

**Visualization:**
```
Race Predictions (based on last 30 days)
─────────────────────────────────────
5K       23:45  (7:38/mi)   Confidence: High
10K      49:30  (7:58/mi)   Confidence: High
Half     1:50:00            Confidence: Medium
Marathon 3:55:00            Confidence: Low (need more long runs)
```

**Implementation:**
- Use Riegel formula or VDOT tables
- Input: recent race times or hard effort runs
- Adjust for training volume and VO2 max
- Show confidence based on training appropriateness

**Why it matters:** Goal setting. "If I keep training like this, I'll run a 23-minute 5K."

---

### 7. **Running Training Load (Acute:Chronic)**

**What:** Same injury-prevention metric from lifting, applied to running.

**Calculation:**
- Acute = 7-day mileage
- Chronic = 28-day average mileage
- Ratio = Acute / Chronic
- Sweet spot: 0.8-1.3
- Injury risk zone: >1.5

**Visualization:**
```
Running Load Ratio: 1.24
─────────────────────────────────────
[Gauge: green zone 0.8-1.3, yellow 1.3-1.5, red >1.5]
7-day: 24.5 mi  |  28-day avg: 19.8 mi/week
Status: In Zone ✓
```

**Why it matters:** Runners get injured from ramping up too fast. This prevents that.

---

### 8. **Long Run Tracker**

**What:** Weekly long runs are the foundation of distance running. Track them explicitly.

**Visualization:**
```
Long Runs (Last 8 Weeks)
─────────────────────────────────────
Week  Distance  % of Weekly
12/15   8.2 mi    45%
12/08   7.0 mi    39%
12/01   9.1 mi    48%
11/24   6.5 mi    35%
...
Recommended: 20-30% of weekly volume
```

**Implementation:**
- Identify longest run each week
- Track progression
- Alert if long run is too large (>30%) or too small (<15%)

**Why it matters:** Long runs build endurance. Monitoring them prevents under/overtraining.

---

## Part II: Universal HealthKit Features (No Hevy Required)

These work for everyone—lifters, runners, cyclists, swimmers, or casual exercisers.

### 9. **Activity Type Breakdown**

**What:** Pie chart of workout types over the past month.

**Visualization:**
```
Your Training Mix (Last 30 Days)
─────────────────────────────────────
Running        45%  (12 workouts, 8.2 hrs)
Strength       30%  (8 workouts, 4.5 hrs)
Cycling        15%  (4 workouts, 3.0 hrs)
Yoga           10%  (4 workouts, 2.0 hrs)
```

**Implementation:**
- Query all workouts from HealthKit
- Group by activity type
- Calculate time/frequency percentages

**Why it matters:** See what you're actually doing vs. what you think you're doing.

---

### 10. **Workout Frequency Calendar**

**What:** GitHub-style heatmap showing workout days.

**Visualization:**
```
December 2025
─────────────────────────────────────
M  T  W  T  F  S  S
         1  2  3  4
█  ·  █  ·  ·  █  ·   (█ = workout)
8  9 10 11 12 13 14
·  █  ·  █  ·  ·  █
15 16 17 18
█  ·  █  ·

12 workouts this month
```

**Implementation:**
- Query workouts, group by day
- Color intensity by duration or calories
- Track streaks and consistency

**Why it matters:** Visual consistency tracking. "Don't break the chain."

---

### 11. **VO2 Max as Universal Fitness Score**

**What:** Make VO2 max the "hero metric" for cardio fitness (like weight trend for body comp).

**Visualization:**
```
Cardio Fitness Score
─────────────────────────────────────
       44.2
      ml/kg/min

[Gauge showing position in age/gender range]
Above Average for Men 35-40

Trend: ↑3.1 over 6 months
```

**Implementation:**
- Already available from Apple Watch
- Just need to query and display prominently
- Add age/gender context for zones

**Why it matters:** One number that represents cardiorespiratory health. Simple, powerful.

---

### 12. **Cross-Training Balance**

**What:** Ensure balanced training across activity types.

**Recommendation Engine:**
```
Training Balance Analysis
─────────────────────────────────────
✓ Cardio volume: Good (3+ sessions/week)
⚠ Strength training: Low (1 session this week)
  → Suggestion: Add 1-2 strength sessions for injury prevention

✓ Flexibility/Mobility: Good (yoga 2x/week)
```

**Implementation:**
- Categorize workouts (cardio, strength, flexibility)
- Track weekly balance
- Suggest adjustments

**Why it matters:** Runners who only run get injured. Cross-training prevents this.

---

### 13. **Active Calories Trend**

**What:** Daily active calories burned, trended over time.

**Visualization:**
```
Daily Active Burn (Last 30 Days)
─────────────────────────────────────
[Chart: daily calories with 7-day moving average]
Today: 542 cal  |  30-day avg: 487 cal
Trend: ↑11% vs last month
```

**Implementation:**
- Query `HKQuantityType(.activeEnergyBurned)` daily
- Add workout context (spikes on workout days)
- Integrate with nutrition for energy balance

**Why it matters:** Activity level affects TDEE. Show it.

---

### 14. **Heart Rate Recovery Tracking**

**What:** How quickly your HR drops after exercise. Better recovery = better fitness.

**Metric:**
- Heart Rate Recovery (HRR) = HR at end of workout - HR 1 minute later
- Good: >20 bpm drop
- Excellent: >30 bpm drop

**Visualization:**
```
Heart Rate Recovery (Last 10 Workouts)
─────────────────────────────────────
[Chart: HRR over time]
Latest: 28 bpm (Excellent)
Trend: Improving ↑
```

**Implementation:**
- Query `HKQuantityType(.heartRateRecoveryOneMinute)`
- Plot over time
- Correlate with fitness improvements

**Why it matters:** HRR is an independent predictor of cardiac health. It improves with training.

---

### 15. **Step Streaks & Goals**

**What:** Simple daily step tracking with streak mechanics.

**Visualization:**
```
Daily Steps
─────────────────────────────────────
Today: 8,432 / 10,000 goal
━━━━━━━━━━━━━━░░░░░  84%

🔥 Streak: 12 days hitting goal
Personal best: 23 days (November 2024)
```

**Implementation:**
- Query steps daily
- Track goal achievement
- Maintain streak counter

**Why it matters:** Low friction, universal, gamifiable. Good for family members who aren't hardcore athletes.

---

## Part III: Implementation Priority

### Tier 1: Quick Wins (Days of work)

1. **VO2 Max Trend Chart** — One query, one chart, huge value
2. **Workout Frequency Calendar** — Visual, motivating, works for everyone
3. **Weekly Mileage Dashboard** — Simple aggregation of existing data
4. **Step Streaks** — Easy engagement feature

### Tier 2: High Value (Week of work)

5. **Pace Progression Chart** — Requires calculating pace per workout
6. **Heart Rate Zone Distribution** — Need to bucket HR samples
7. **Active Calories Trend** — Simple but needs good visualization
8. **Activity Type Breakdown** — Categorization of workout types

### Tier 3: Advanced (2+ weeks)

9. **Running Form Analysis** — Need to query biomechanics data
10. **Race Time Predictor** — Algorithm complexity
11. **Running Training Load** — Same as lifting, but for mileage
12. **Cross-Training Balance** — Recommendation engine

---

## Part IV: Architecture Notes

### New HealthKitManager Methods Needed

```swift
// Running-specific
func getRunningWorkouts(days: Int) async -> [RunningWorkout]
func getVO2MaxHistory(days: Int) async -> [VO2MaxReading]
func getRunningBiomecrics(for workout: HKWorkout) async -> RunningBiometrics
func getHeartRateSamples(during workout: HKWorkout) async -> [HeartRateSample]

// Universal
func getWorkoutsByType(days: Int) async -> [WorkoutType: [WorkoutSummary]]
func getDailySteps(days: Int) async -> [StepReading]
func getActiveCaloriesHistory(days: Int) async -> [CalorieReading]
func getHeartRateRecoveryHistory(days: Int) async -> [HRRReading]
```

### New Data Models

```swift
struct RunningWorkout: Sendable {
    let date: Date
    let distanceMiles: Double
    let durationMinutes: Double
    let pacePerMile: Double  // in seconds
    let averageHR: Int?
    let calories: Int?
}

struct VO2MaxReading: Sendable {
    let date: Date
    let value: Double  // ml/kg/min
}

struct RunningBiometrics: Sendable {
    let strideLength: Double  // meters
    let groundContactTime: Double  // milliseconds
    let verticalOscillation: Double  // centimeters
    let cadence: Double  // steps per minute
}
```

### Server-Side Context Integration

Add to context store:
```python
@dataclass
class CardioSnapshot:
    running_miles: float = 0.0
    cycling_miles: float = 0.0
    vo2_max: Optional[float] = None
    avg_pace_sec_per_mile: Optional[float] = None
    workout_count: int = 0
    cardio_minutes: int = 0
```

Inject into chat context so AI coach knows about running training too.

---

## Part V: Family-Friendly Mode

For users without Hevy (like your brothers), AirFit can still be valuable:

### HealthKit-Only Mode

When no Hevy API key configured:
1. **Hide:** Strength detail view, lift progress, set volume
2. **Show:** Workout frequency, VO2 max, step streaks, activity breakdown
3. **Coach context:** AI knows about cardio but doesn't reference Hevy data

### Features that work for everyone:
- Nutrition logging (universal)
- Body composition tracking (universal)
- Sleep/recovery metrics (universal)
- Workout frequency calendar
- Step goals and streaks
- VO2 max tracking
- Active calorie burn
- AI coaching (adapted to their training)

This makes AirFit useful for the whole family, not just lifting-focused users.

---

## Summary

**What we have:** Rich HealthKit data for running/cardio sitting unused.

**What we need:** Query methods + visualization components.

**Quick wins:**
1. VO2 max chart (1 day)
2. Workout calendar heatmap (1 day)
3. Weekly mileage sparkline (1 day)
4. Step streak tracker (half day)

**The vision:** AirFit as a universal fitness coach that adapts to however you train—lifting, running, cycling, swimming, or any combination.

---

*"The app should meet you where you are, not where it assumes you should be."*
