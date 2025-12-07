"""Nutrition parsing via AI."""
import json
import re
from dataclasses import dataclass
from typing import Optional

import llm_router


@dataclass
class NutritionComponent:
    """Single food component."""
    name: str
    calories: int
    protein: int
    carbs: int
    fat: int


@dataclass
class NutritionEntry:
    """Parsed nutrition data from food input."""
    name: str
    calories: int
    protein: int
    carbs: int
    fat: int
    confidence: str  # "high", "medium", "low"
    components: list[NutritionComponent]


PARSE_SYSTEM_PROMPT = """You are a nutrition parsing assistant. When given a food description, estimate the macros.

RESPOND ONLY WITH JSON in this exact format:
{
  "name": "cleaned up food name",
  "calories": 450,
  "protein": 35,
  "carbs": 40,
  "fat": 15,
  "confidence": "high",
  "components": [
    {"name": "chicken breast", "calories": 280, "protein": 52, "carbs": 0, "fat": 6},
    {"name": "rice", "calories": 170, "protein": 3, "carbs": 37, "fat": 0}
  ]
}

confidence levels:
- "high": specific foods with known nutrition (e.g., "4 eggs", "chipotle bowl")
- "medium": general descriptions you can estimate (e.g., "chicken stir fry")
- "low": vague or unusual items (e.g., "some snacks")

components: Break down compound meals into individual items. For single items, omit components or use empty array.

Be practical and realistic. Round to whole numbers.
ONLY output the JSON, no other text."""


async def parse_food(text: str) -> Optional[NutritionEntry]:
    """
    Parse food text into nutrition data using AI.

    Example inputs:
    - "4 eggs scrambled with cheese"
    - "chipotle bowl, chicken, rice, beans, guac"
    - "protein shake with banana"
    """
    prompt = f"Parse this food: {text}"

    # Stateless - nutrition parsing shouldn't pollute chat history
    result = await llm_router.chat(prompt, PARSE_SYSTEM_PROMPT, use_session=False)

    if not result.success:
        return None

    try:
        # Find the outermost JSON object (handles nested arrays/objects)
        start = result.text.find('{')
        if start == -1:
            return None

        # Find matching closing brace
        depth = 0
        end = start
        for i, char in enumerate(result.text[start:], start):
            if char == '{':
                depth += 1
            elif char == '}':
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break

        data = json.loads(result.text[start:end])

        # Parse components
        components = []
        for comp in data.get("components", []):
            components.append(NutritionComponent(
                name=comp.get("name", ""),
                calories=int(comp.get("calories", 0)),
                protein=int(comp.get("protein", 0)),
                carbs=int(comp.get("carbs", 0)),
                fat=int(comp.get("fat", 0))
            ))

        return NutritionEntry(
            name=data.get("name", text),
            calories=int(data.get("calories", 0)),
            protein=int(data.get("protein", 0)),
            carbs=int(data.get("carbs", 0)),
            fat=int(data.get("fat", 0)),
            confidence=data.get("confidence", "low"),
            components=components
        )
    except (json.JSONDecodeError, ValueError, TypeError):
        return None


CORRECT_SYSTEM_PROMPT = """You are a nutrition correction assistant. Given original food data and a user correction, recalculate the macros.

RESPOND ONLY WITH JSON in this exact format:
{
  "name": "updated food name if needed",
  "calories": 450,
  "protein": 35,
  "carbs": 40,
  "fat": 15,
  "reasoning": "brief explanation of adjustment"
}

Common corrections:
- Portion size changes ("large not medium" = ~1.5x, "had two" = 2x)
- Cooking method ("grilled not fried" = less fat)
- Added/removed ingredients ("add cheese", "no rice")
- Quantity adjustments ("only had half")

Apply your nutritional knowledge to make reasonable adjustments.
ONLY output the JSON, no other text."""


async def correct_entry(
    original_name: str,
    original_calories: int,
    original_protein: int,
    original_carbs: int,
    original_fat: int,
    correction: str
) -> Optional[NutritionEntry]:
    """
    Apply a natural language correction to an existing entry.

    Example corrections:
    - "that was a large portion"
    - "I had two of those"
    - "it was grilled, not fried"
    - "add cheese"
    """
    prompt = f"""Original entry:
- Name: {original_name}
- Calories: {original_calories}
- Protein: {original_protein}g
- Carbs: {original_carbs}g
- Fat: {original_fat}g

User correction: {correction}

Recalculate the macros based on this correction."""

    # Stateless - corrections are one-off tasks
    result = await llm_router.chat(prompt, CORRECT_SYSTEM_PROMPT, use_session=False)

    if not result.success:
        return None

    try:
        start = result.text.find('{')
        if start == -1:
            return None

        depth = 0
        end = start
        for i, char in enumerate(result.text[start:], start):
            if char == '{':
                depth += 1
            elif char == '}':
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break

        data = json.loads(result.text[start:end])

        return NutritionEntry(
            name=data.get("name", original_name),
            calories=int(data.get("calories", original_calories)),
            protein=int(data.get("protein", original_protein)),
            carbs=int(data.get("carbs", original_carbs)),
            fat=int(data.get("fat", original_fat)),
            confidence="corrected",
            components=[]
        )
    except (json.JSONDecodeError, ValueError, TypeError):
        return None


async def get_macro_feedback(
    current_calories: int,
    current_protein: int,
    current_carbs: int,
    current_fat: int,
    is_training_day: bool = True
) -> str:
    """
    Get quick AI feedback on current macro status.
    Uses targets from the system prompt context.
    """
    if is_training_day:
        targets = {"calories": 2600, "protein": 175, "carbs": 330, "fat": 67}
    else:
        targets = {"calories": 2200, "protein": 175, "carbs": 250, "fat": 57}

    remaining_cals = targets["calories"] - current_calories
    remaining_protein = targets["protein"] - current_protein

    prompt = f"""Current intake: {current_calories} cal, {current_protein}g P, {current_carbs}g C, {current_fat}g F
Targets ({'training' if is_training_day else 'rest'} day): {targets['calories']} cal, {targets['protein']}g P, {targets['carbs']}g C, {targets['fat']}g F
Remaining: {remaining_cals} cal, {remaining_protein}g protein

Give a 1-2 sentence status update. Be casual, like a bro checking in."""

    # Stateless - feedback is a one-off task
    result = await llm_router.chat(prompt, use_session=False)
    return result.text if result.success else "Couldn't get feedback right now."
