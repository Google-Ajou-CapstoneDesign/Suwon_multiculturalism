import os
import google.generativeai as genai


def configure() -> None:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY environment variable is not set")
    genai.configure(api_key=api_key)


def get_model(model_name: str = "gemini-2.0-flash", **kwargs) -> genai.GenerativeModel:
    return genai.GenerativeModel(model_name=model_name, **kwargs)
