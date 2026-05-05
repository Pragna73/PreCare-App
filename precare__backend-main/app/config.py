from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent
UPLOAD_DIR = BASE_DIR / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


class Settings:
    openai_api_key: str = os.getenv("OPENAI_API_KEY", "")
    google_gemini_api_key: str = os.getenv("GOOGLE_GEMINI_API_KEY", "")
    anthropic_api_key: str = os.getenv("ANTHROPIC_API_KEY", "")

    # Chatbot model (Ask Maya)
    llm_model: str = os.getenv("LLM_MODEL", "gemini-1.5-flash")
    # Report risk model (Claude)
    claude_model: str = os.getenv("CLAUDE_MODEL", "claude-3-5-sonnet-latest")


settings = Settings()
