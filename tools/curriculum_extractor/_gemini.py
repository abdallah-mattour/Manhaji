"""Thin wrapper around the Gemini API for curriculum drafting.

Two reasons this exists vs calling the SDK directly:
1. Single chokepoint for the model name + temperature + JSON-only response
   config, so the rest of the tool doesn't repeat boilerplate.
2. Centralized error handling — Gemini occasionally returns markdown-wrapped
   JSON or extra prose around the JSON body; we strip that here so callers
   get clean parsed dicts.

Requires GEMINI_API_KEY in the environment. The backend already uses this
key for runtime AI features (see Manhaji/backend/src/main/resources/application.yaml).
"""
from __future__ import annotations

import json
import os
import re
from typing import Any

from google import genai
from google.genai import types


# Model choice rationale:
# - gemini-2.5-flash is what the backend uses (Manhaji/backend application.yaml).
# - For structured drafting it's plenty smart, very fast, and cheap. Pro tier
#   would add cost without measurably better question quality at this scale.
DEFAULT_MODEL = "gemini-2.5-flash"


class GeminiError(Exception):
    """Raised when Gemini returns an unparseable response or the call fails."""


def _client() -> genai.Client:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key or api_key == "not-set":
        raise GeminiError(
            "GEMINI_API_KEY is not set. Export it in your shell:\n"
            "  PowerShell:  $env:GEMINI_API_KEY = '<your-key>'\n"
            "  Bash/Zsh:    export GEMINI_API_KEY='<your-key>'\n"
            "The same key the backend uses (application.yaml > app.ai.gemini.api-key)."
        )
    return genai.Client(api_key=api_key)


def draft_lesson_json(
    *,
    system_prompt: str,
    user_prompt: str,
    model: str = DEFAULT_MODEL,
    temperature: float = 0.4,
) -> dict[str, Any]:
    """Send a prompt to Gemini and return parsed JSON.

    Args:
        system_prompt: Spec/template instructions. Goes into the model's
                       system instructions so it's prioritized over user input.
        user_prompt: The extracted chapter content + per-call drafting ask.
        model: Override the default model if needed.
        temperature: 0.4 is a good sweet spot — low enough that the question
                     structure stays consistent across runs, high enough to
                     get varied phrasing in the prompts themselves.

    Returns:
        Parsed JSON dict — the lesson template with `questions` array.

    Raises:
        GeminiError if the API call fails or response isn't valid JSON.
    """
    client = _client()
    try:
        response = client.models.generate_content(
            model=model,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=temperature,
                # response_mime_type forces Gemini to return JSON in the body
                # so we don't have to strip markdown fences (sometimes Flash
                # wraps JSON in ```json blocks anyway; the parser below
                # handles both).
                response_mime_type="application/json",
            ),
        )
    except Exception as e:
        raise GeminiError(f"Gemini API call failed: {e}") from e

    text = (response.text or "").strip()
    if not text:
        raise GeminiError("Gemini returned empty response")

    # Strip ```json``` fences if the model added them despite response_mime_type
    text = _strip_md_fences(text)

    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        # Save the failed response for debugging — author can inspect what
        # the model returned vs what we expected.
        raise GeminiError(
            f"Gemini returned text that isn't valid JSON: {e}\n"
            f"First 300 chars of response:\n{text[:300]}"
        ) from e


def _strip_md_fences(text: str) -> str:
    """Remove ```json ... ``` markdown fences if present. Gemini Flash
    sometimes wraps JSON in code fences even with response_mime_type set."""
    m = re.match(r"^\s*```(?:json)?\s*\n(.*?)\n```\s*$", text, re.DOTALL)
    if m:
        return m.group(1)
    return text
