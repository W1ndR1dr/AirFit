"""AirFit Server - FastAPI backend that wraps CLI LLM tools."""
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from contextlib import asynccontextmanager
import os

import config
import llm_router
import hevy


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    providers = llm_router.get_available_providers()
    print(f"AirFit server starting on http://{config.HOST}:{config.PORT}")
    print(f"Available providers: {providers or 'NONE - install claude/gemini/ollama'}")
    yield
    print("AirFit server shutting down")


app = FastAPI(
    title="AirFit Server",
    description="AI fitness coach backend using CLI LLM tools",
    version="0.1.0",
    lifespan=lifespan
)

# Allow iOS app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Request/Response Models ---

class ChatRequest(BaseModel):
    """Chat message from the iOS app."""
    message: str
    system_prompt: Optional[str] = None
    health_context: Optional[dict] = None  # For Day 2: HealthKit data


class ChatResponse(BaseModel):
    """Chat response back to the iOS app."""
    response: str
    provider: str
    success: bool
    error: Optional[str] = None


class HealthStatus(BaseModel):
    """Server health check response."""
    status: str
    providers: list[str]
    hevy_configured: bool
    version: str


# --- Endpoints ---

@app.get("/health", response_model=HealthStatus)
async def health_check():
    """Check server status and available providers."""
    return HealthStatus(
        status="ok",
        providers=llm_router.get_available_providers(),
        hevy_configured=bool(os.getenv("HEVY_API_KEY")),
        version="0.1.0"
    )


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Send a message to the AI coach.

    The server will:
    1. Fetch Hevy workout data (if API key configured)
    2. Include health context from iOS (HealthKit)
    3. Try available LLM providers in priority order
    4. Return the AI response
    """
    context_parts = []

    # Get Hevy workout data (server-side)
    hevy_context = await hevy.get_hevy_context()
    if hevy_context.get("hevy_workouts"):
        context_parts.append(hevy_context["hevy_workouts"])

    # Add HealthKit data from iOS (if provided)
    if request.health_context:
        context_parts.append(format_health_context(request.health_context))

    # Build the full prompt
    if context_parts:
        context_str = "\n\n".join(context_parts)
        prompt = f"{context_str}\n\nUser message: {request.message}"
    else:
        prompt = request.message

    # Call the LLM
    result = await llm_router.chat(prompt, request.system_prompt)

    return ChatResponse(
        response=result.text,
        provider=result.provider,
        success=result.success,
        error=result.error
    )


def format_health_context(context: dict) -> str:
    """Format HealthKit data into a readable context string for the LLM."""
    parts = ["Here is the user's current health data:"]

    if "steps" in context:
        parts.append(f"- Steps today: {context['steps']}")
    if "sleep_hours" in context:
        parts.append(f"- Sleep last night: {context['sleep_hours']} hours")
    if "active_calories" in context:
        parts.append(f"- Active calories today: {context['active_calories']}")
    if "weight_kg" in context:
        parts.append(f"- Weight: {context['weight_kg']} kg")
    if "resting_hr" in context:
        parts.append(f"- Resting heart rate: {context['resting_hr']} bpm")

    # Add any other keys dynamically
    known_keys = {"steps", "sleep_hours", "active_calories", "weight_kg", "resting_hr"}
    for key, value in context.items():
        if key not in known_keys:
            parts.append(f"- {key.replace('_', ' ').title()}: {value}")

    return "\n".join(parts)


if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host=config.HOST,
        port=config.PORT,
        reload=True  # Auto-reload during development
    )
