"""LLM Router - calls CLI tools via subprocess."""
import asyncio
import shutil
import json
from dataclasses import dataclass
from typing import Optional
import config


@dataclass
class LLMResponse:
    """Response from an LLM provider."""
    text: str
    provider: str
    success: bool
    error: Optional[str] = None


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
        elif provider == "ollama" and is_available(config.OLLAMA_CLI):
            available.append("ollama")
    return available


async def call_claude(prompt: str, system_prompt: Optional[str] = None) -> LLMResponse:
    """Call Claude CLI."""
    args = [config.CLAUDE_CLI, "-p", prompt, "--output-format", "text"]

    if system_prompt:
        args.extend(["--system", system_prompt])

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
            return LLMResponse(
                text="",
                provider="claude",
                success=False,
                error=stderr.decode().strip() or f"Exit code {process.returncode}"
            )

        return LLMResponse(
            text=stdout.decode().strip(),
            provider="claude",
            success=True
        )

    except asyncio.TimeoutError:
        return LLMResponse(text="", provider="claude", success=False, error="Timeout")
    except Exception as e:
        return LLMResponse(text="", provider="claude", success=False, error=str(e))


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

        return LLMResponse(text=text, provider="gemini", success=True)

    except asyncio.TimeoutError:
        return LLMResponse(text="", provider="gemini", success=False, error="Timeout")
    except Exception as e:
        return LLMResponse(text="", provider="gemini", success=False, error=str(e))


async def call_ollama(prompt: str, system_prompt: Optional[str] = None) -> LLMResponse:
    """Call Ollama CLI (local LLM)."""
    full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt

    try:
        process = await asyncio.create_subprocess_exec(
            config.OLLAMA_CLI, "run", config.OLLAMA_MODEL, full_prompt,
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
                provider="ollama",
                success=False,
                error=stderr.decode().strip() or f"Exit code {process.returncode}"
            )

        return LLMResponse(
            text=stdout.decode().strip(),
            provider="ollama",
            success=True
        )

    except asyncio.TimeoutError:
        return LLMResponse(text="", provider="ollama", success=False, error="Timeout")
    except Exception as e:
        return LLMResponse(text="", provider="ollama", success=False, error=str(e))


PROVIDER_FUNCTIONS = {
    "claude": call_claude,
    "gemini": call_gemini,
    "ollama": call_ollama,
}


async def chat(prompt: str, system_prompt: Optional[str] = None) -> LLMResponse:
    """
    Send a chat message through available providers.
    Tries each provider in priority order until one succeeds.
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
        func = PROVIDER_FUNCTIONS.get(provider)
        if not func:
            continue

        response = await func(prompt, system_prompt)
        if response.success:
            return response
        errors.append(f"{provider}: {response.error}")

    return LLMResponse(
        text="",
        provider="none",
        success=False,
        error=f"All providers failed: {'; '.join(errors)}"
    )
