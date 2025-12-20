"""LLM Router - calls CLI tools via subprocess with session support."""
import asyncio
import shutil
import json
from dataclasses import dataclass
from typing import Optional
import config
import sessions


@dataclass
class LLMResponse:
    """Response from an LLM provider."""
    text: str
    provider: str
    success: bool
    error: Optional[str] = None
    session_id: Optional[str] = None


def is_available(cli_name: str) -> bool:
    """Check if a CLI tool is available in PATH."""
    return shutil.which(cli_name) is not None


def get_available_providers() -> list[str]:
    """Return list of available providers based on what's installed."""
    available = []
    for provider in config.PROVIDERS:
        if provider == "claude" and is_available(config.CLAUDE_CLI):
            available.append("claude")
        elif provider == "gemini" and is_available(config.GEMINI_CLI):
            available.append("gemini")
        elif provider == "codex" and is_available(config.CODEX_CLI):
            available.append("codex")
    return available


async def call_claude(
    prompt: str,
    system_prompt: Optional[str] = None,
    session_id: Optional[str] = None,
    use_session: bool = True
) -> LLMResponse:
    """
    Call Claude CLI with optional session support.

    If use_session=True (default), maintains conversation context across calls.
    Claude CLI handles auto-compact automatically when context gets large.
    """
    # Get or create session for conversation continuity
    if use_session and session_id is None:
        session = sessions.get_or_create_session(provider="claude")
        session_id = session.session_id

    # Build command
    # Use --resume for session continuity (works for both new and existing sessions)
    if session_id:
        args = [config.CLAUDE_CLI, "--resume", session_id, "-p", prompt, "--output-format", "text"]
    else:
        args = [config.CLAUDE_CLI, "-p", prompt, "--output-format", "text"]

    if system_prompt:
        args.extend(["--system-prompt", system_prompt])

    try:
        process = await asyncio.create_subprocess_exec(
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        stdout, stderr = await asyncio.wait_for(
            process.communicate(),
            timeout=config.CLI_TIMEOUT
        )

        if process.returncode != 0:
            error_msg = stderr.decode().strip() or f"Exit code {process.returncode}"

            # If session doesn't exist, fall back to creating new one
            if "session" in error_msg.lower() and "not found" in error_msg.lower():
                # Clear the bad session and retry with new one
                sessions.clear_session(provider="claude")
                return await call_claude(prompt, system_prompt, session_id=None, use_session=True)

            return LLMResponse(
                text="",
                provider="claude",
                success=False,
                error=error_msg,
                session_id=session_id
            )

        # Clean up output - filter CLI notices
        text = stdout.decode().strip()
        # Remove telemetry/data collection notices
        lines = [l for l in text.split('\n') if 'data collection' not in l.lower() and 'is disabled' not in l.lower()]
        text = '\n'.join(lines).strip()

        return LLMResponse(
            text=text,
            provider="claude",
            success=True,
            session_id=session_id
        )

    except asyncio.TimeoutError:
        return LLMResponse(text="", provider="claude", success=False, error="Timeout", session_id=session_id)
    except Exception as e:
        return LLMResponse(text="", provider="claude", success=False, error=str(e), session_id=session_id)


async def call_gemini(prompt: str, system_prompt: Optional[str] = None) -> LLMResponse:
    """Call Gemini CLI."""
    full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt

    try:
        process = await asyncio.create_subprocess_exec(
            config.GEMINI_CLI, "-p", full_prompt,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        stdout, stderr = await asyncio.wait_for(
            process.communicate(),
            timeout=config.CLI_TIMEOUT
        )

        if process.returncode != 0:
            return LLMResponse(
                text="",
                provider="gemini",
                success=False,
                error=stderr.decode().strip() or f"Exit code {process.returncode}"
            )

        # Clean ANSI codes from Gemini output
        text = stdout.decode().strip()
        import re
        text = re.sub(r'\x1b\[[0-9;]*m', '', text)

        # Remove telemetry/data collection notices
        lines = [l for l in text.split('\n') if 'data collection' not in l.lower()]
        text = '\n'.join(lines).strip()

        return LLMResponse(text=text, provider="gemini", success=True)

    except asyncio.TimeoutError:
        return LLMResponse(text="", provider="gemini", success=False, error="Timeout")
    except Exception as e:
        return LLMResponse(text="", provider="gemini", success=False, error=str(e))


async def call_codex(prompt: str, system_prompt: Optional[str] = None) -> LLMResponse:
    """Call OpenAI Codex CLI."""
    full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt

    try:
        process = await asyncio.create_subprocess_exec(
            config.CODEX_CLI, "-p", full_prompt,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        stdout, stderr = await asyncio.wait_for(
            process.communicate(),
            timeout=config.CLI_TIMEOUT
        )

        if process.returncode != 0:
            return LLMResponse(
                text="",
                provider="codex",
                success=False,
                error=stderr.decode().strip() or f"Exit code {process.returncode}"
            )

        # Clean output
        text = stdout.decode().strip()
        lines = [l for l in text.split('\n') if 'data collection' not in l.lower()]
        text = '\n'.join(lines).strip()

        return LLMResponse(
            text=text,
            provider="codex",
            success=True
        )

    except asyncio.TimeoutError:
        return LLMResponse(text="", provider="codex", success=False, error="Timeout")
    except Exception as e:
        return LLMResponse(text="", provider="codex", success=False, error=str(e))


PROVIDER_FUNCTIONS = {
    "claude": call_claude,
    "gemini": call_gemini,
    "codex": call_codex,
}


async def chat(
    prompt: str,
    system_prompt: Optional[str] = None,
    use_session: bool = True
) -> LLMResponse:
    """
    Send a chat message through available providers.
    Tries each provider in priority order until one succeeds.

    If use_session=True (default), maintains conversation context.
    Set to False for one-off tasks like nutrition parsing.
    """
    available = get_available_providers()

    if not available:
        return LLMResponse(
            text="",
            provider="none",
            success=False,
            error="No LLM providers available. Install claude, gemini, or ollama CLI."
        )

    errors = []
    for provider in available:
        if provider == "claude":
            response = await call_claude(prompt, system_prompt, use_session=use_session)
        elif provider == "gemini":
            response = await call_gemini(prompt, system_prompt)
        elif provider == "codex":
            response = await call_codex(prompt, system_prompt)
        else:
            continue

        if response.success:
            return response
        errors.append(f"{provider}: {response.error}")

    return LLMResponse(
        text="",
        provider="none",
        success=False,
        error=f"All providers failed: {'; '.join(errors)}"
    )


def clear_chat_session(provider: str = "claude") -> bool:
    """Clear the chat session to start a fresh conversation."""
    return sessions.clear_session(provider=provider)
