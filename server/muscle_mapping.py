"""Exercise to muscle group mapping for set tracking.

COUNTING PHILOSOPHY:
- Arms (biceps, triceps): DIRECT WORK ONLY - rows don't count for biceps,
  presses don't count for triceps. Lower targets (8-16 sets) reflect this.
- Legs: Compounds CAN count for multiple groups. BSS, leg press, squats all
  count for both quads AND glutes since both are primary movers.
- Back/Chest/Delts: Only exercises where that muscle is a PRIMARY mover count.

This matches hypertrophy research showing arms need direct isolation volume,
while compound legs provide sufficient stimulus for multiple muscle groups.
"""

from typing import Optional

# Maps exercise name patterns to PRIMARY muscle groups only
# Arms (biceps/triceps) require direct work - compounds don't count for them
EXERCISE_MUSCLES: dict[str, list[str]] = {
    # Chest - pressing is chest, NOT triceps (triceps needs direct work)
    "Bench Press": ["chest"],
    "Incline Bench Press": ["chest", "delts"],
    "Decline Bench Press": ["chest"],
    "Dumbbell Bench Press": ["chest"],
    "Incline Dumbbell Press": ["chest", "delts"],
    "Dumbbell Fly": ["chest"],
    "Cable Fly": ["chest"],
    "Incline Fly": ["chest"],
    "Chest Dip": ["chest"],
    "Push Up": ["chest"],
    "Machine Chest Press": ["chest"],
    "Pec Deck": ["chest"],

    # Back - pulling is back, NOT biceps (biceps needs direct work)
    "Pull Up": ["back"],
    "Chin Up": ["back"],
    "Lat Pulldown": ["back"],
    "Barbell Row": ["back"],
    "Bent Over Row": ["back"],
    "Dumbbell Row": ["back"],
    "Cable Row": ["back"],
    "Seated Row": ["back"],
    "T-Bar Row": ["back"],
    "Deadlift": ["back", "glutes", "hamstrings"],
    "Rack Pull": ["back", "glutes"],
    "Shrug": ["back"],
    "Face Pull": ["back", "delts"],
    "Straight Arm Pulldown": ["back"],
    "Machine Row": ["back"],

    # Legs - Quads/Glutes (compounds COUNT for both - both are primary movers)
    "Squat": ["quads", "glutes"],
    "Back Squat": ["quads", "glutes"],
    "Front Squat": ["quads", "glutes"],
    "Goblet Squat": ["quads", "glutes"],
    "Bulgarian Split Squat": ["quads", "glutes"],
    "Split Squat": ["quads", "glutes"],
    "Leg Press": ["quads", "glutes"],  # High feet = more glute emphasis
    "Hack Squat": ["quads", "glutes"],
    "Lunge": ["quads", "glutes"],
    "Walking Lunge": ["quads", "glutes"],
    "Reverse Lunge": ["quads", "glutes"],
    "Step Up": ["quads", "glutes"],
    "Leg Extension": ["quads"],
    "Sissy Squat": ["quads"],

    # Legs - Hamstrings/Glutes
    "Romanian Deadlift": ["hamstrings", "glutes"],
    "Stiff Leg Deadlift": ["hamstrings", "glutes"],
    "Good Morning": ["hamstrings", "glutes"],
    "Leg Curl": ["hamstrings"],
    "Lying Leg Curl": ["hamstrings"],
    "Seated Leg Curl": ["hamstrings"],
    "Nordic Curl": ["hamstrings"],
    "Hip Thrust": ["glutes"],  # Glute-only, hamstrings are secondary
    "Glute Bridge": ["glutes"],
    "Cable Pull Through": ["glutes", "hamstrings"],
    "Glute Kickback": ["glutes"],
    "Hip Abduction": ["glutes"],
    "Hip Adduction": ["glutes"],

    # Calves
    "Calf Raise": ["calves"],
    "Standing Calf Raise": ["calves"],
    "Seated Calf Raise": ["calves"],
    "Donkey Calf Raise": ["calves"],
    "Leg Press Calf Raise": ["calves"],

    # Shoulders - pressing is delts, NOT triceps
    "Overhead Press": ["delts"],
    "Military Press": ["delts"],
    "Shoulder Press": ["delts"],
    "Dumbbell Shoulder Press": ["delts"],
    "Arnold Press": ["delts"],
    "Push Press": ["delts"],
    "Lateral Raise": ["delts"],
    "Side Lateral Raise": ["delts"],
    "Front Raise": ["delts"],
    "Rear Delt Fly": ["delts", "back"],
    "Reverse Fly": ["delts", "back"],
    "Upright Row": ["delts"],
    "Machine Shoulder Press": ["delts"],

    # Triceps - DIRECT WORK ONLY
    "Tricep Extension": ["triceps"],
    "Tricep Pushdown": ["triceps"],
    "Cable Tricep Extension": ["triceps"],
    "Overhead Tricep Extension": ["triceps"],
    "Skull Crusher": ["triceps"],
    "Lying Tricep Extension": ["triceps"],
    "Close Grip Bench Press": ["triceps"],  # This IS direct tricep work
    "Diamond Push Up": ["triceps"],
    "Dip": ["triceps"],  # Tricep dip variant
    "Tricep Kickback": ["triceps"],

    # Biceps - DIRECT WORK ONLY
    "Bicep Curl": ["biceps"],
    "Barbell Curl": ["biceps"],
    "Dumbbell Curl": ["biceps"],
    "Hammer Curl": ["biceps"],
    "Preacher Curl": ["biceps"],
    "Concentration Curl": ["biceps"],
    "Cable Curl": ["biceps"],
    "Incline Curl": ["biceps"],
    "EZ Bar Curl": ["biceps"],
    "Spider Curl": ["biceps"],

    # Core
    "Crunch": ["core"],
    "Sit Up": ["core"],
    "Plank": ["core"],
    "Side Plank": ["core"],
    "Leg Raise": ["core"],
    "Hanging Leg Raise": ["core"],
    "Ab Rollout": ["core"],
    "Cable Crunch": ["core"],
    "Russian Twist": ["core"],
    "Wood Chop": ["core"],
    "Dead Bug": ["core"],
    "Bird Dog": ["core"],
    "Pallof Press": ["core"],
}

# Optimal weekly set ranges per muscle group (min, max)
# Based on hypertrophy research - adjust per user goals
OPTIMAL_RANGES: dict[str, tuple[int, int]] = {
    "chest": (12, 20),
    "back": (12, 20),
    "quads": (12, 20),
    "glutes": (12, 22),
    "hamstrings": (10, 18),
    "delts": (10, 18),
    "triceps": (8, 16),
    "biceps": (8, 16),
    "calves": (12, 22),
    "core": (8, 18),
}


def get_muscles_for_exercise(exercise_name: str) -> list[str]:
    """
    Get the muscle groups targeted by an exercise.

    Uses fuzzy matching:
    1. Exact match (case-insensitive)
    2. Substring match (finds "Bench Press" in "Barbell Bench Press (Smith)")
    3. Keyword match (looks for key movement patterns)

    Returns empty list if no match found.
    """
    name_lower = exercise_name.lower().strip()

    # Try exact match first
    for exercise, muscles in EXERCISE_MUSCLES.items():
        if exercise.lower() == name_lower:
            return muscles

    # Try substring match - check if our pattern is in the exercise name
    for exercise, muscles in EXERCISE_MUSCLES.items():
        exercise_lower = exercise.lower()
        if exercise_lower in name_lower or name_lower in exercise_lower:
            return muscles

    # Try keyword-based matching for common patterns
    # NOTE: Arms are DIRECT ONLY - no biceps from rows, no triceps from presses
    keywords_to_muscles = {
        # Chest (no triceps credit)
        ("bench", "press"): ["chest"],
        ("bench", "fly"): ["chest"],
        ("fly",): ["chest"],
        # Back (no biceps credit)
        ("pull", "up"): ["back"],
        ("pulldown",): ["back"],
        ("row",): ["back"],
        # Legs - compounds count for multiple groups
        ("squat",): ["quads", "glutes"],
        ("lunge",): ["quads", "glutes"],
        ("split", "squat"): ["quads", "glutes"],
        ("bss",): ["quads", "glutes"],
        ("leg", "press"): ["quads", "glutes"],
        ("leg", "curl"): ["hamstrings"],
        ("leg", "extension"): ["quads"],
        ("hip", "thrust"): ["glutes"],
        ("deadlift",): ["back", "hamstrings", "glutes"],
        ("rdl",): ["hamstrings", "glutes"],
        ("calf",): ["calves"],
        # Shoulders (no triceps credit)
        ("press", "shoulder"): ["delts"],
        ("press", "overhead"): ["delts"],
        ("ohp",): ["delts"],
        ("lateral", "raise"): ["delts"],
        # Arms - direct only
        ("curl",): ["biceps"],
        ("extension", "tricep"): ["triceps"],
        ("pushdown",): ["triceps"],
        ("skull", "crush"): ["triceps"],
        # Core
        ("crunch",): ["core"],
        ("plank",): ["core"],
        ("ab",): ["core"],
    }

    for keywords, muscles in keywords_to_muscles.items():
        if all(kw in name_lower for kw in keywords):
            return muscles

    return []


def get_status(current: int, min_sets: int, max_sets: int) -> str:
    """Get status label based on current sets vs optimal range."""
    if current < min_sets:
        return "below"
    elif current == min_sets:
        return "at_floor"
    elif current > max_sets:
        return "above"
    else:
        return "in_zone"
