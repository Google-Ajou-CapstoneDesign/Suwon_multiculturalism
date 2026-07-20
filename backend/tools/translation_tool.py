"""Text translation tool using Gemini."""
from __future__ import annotations
import asyncio

import google.generativeai as genai

from services import gemini_service

_LANG_NAMES = {
    "ko": "Korean",
    "vi": "Vietnamese",
    "en": "English",
}


async def translate_text(text: str, target_language: str = "vi") -> str:
    """Translate text to the specified language.

    Args:
        text: Text to translate
        target_language: Target language code ('ko', 'vi', 'en')

    Returns:
        Translated text
    """
    gemini_service.configure()
    target = _LANG_NAMES.get(target_language, "Vietnamese")

    model = genai.GenerativeModel("gemini-3.1-pro")
    prompt = (
        f"Translate the following text to {target}. "
        "Output ONLY the translation, no explanations:\n\n"
        f"{text}"
    )
    response = await asyncio.to_thread(model.generate_content, prompt)
    return response.text.strip()
