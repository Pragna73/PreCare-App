from __future__ import annotations

import os

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_ollama import ChatOllama
from langchain_openai import ChatOpenAI


def get_llm(model_name: str, temperature: float = 0, json_mode: bool = False):
    """Factory returning the configured LangChain chat model."""
    lowered = model_name.lower()

    if lowered.startswith("gpt"):
        kwargs = {"temperature": temperature}
        if json_mode:
            kwargs["model_kwargs"] = {"response_format": {"type": "json_object"}}
        return ChatOpenAI(model=model_name, **kwargs)

    if lowered.startswith("gemini"):
        api_key = os.getenv("GOOGLE_GEMINI_API_KEY", "")
        if not api_key:
            raise ValueError("GOOGLE_GEMINI_API_KEY is required for Gemini model")

        # Gemini JSON mode is driven by prompt/response parsing for compatibility.
        return ChatGoogleGenerativeAI(model=model_name, api_key=api_key, temperature=temperature)

    kwargs = {"temperature": temperature}
    if json_mode:
        kwargs["format"] = "json"
    return ChatOllama(model=model_name, **kwargs)
