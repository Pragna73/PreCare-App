from __future__ import annotations

from pathlib import Path

import pytesseract
from PIL import Image, UnidentifiedImageError

try:
    from pypdf import PdfReader
except Exception:  # pragma: no cover
    PdfReader = None  # type: ignore[assignment]


def extract_text(file_path: str) -> str:
    path = Path(file_path)
    if not path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    suffix = path.suffix.lower()

    if suffix in {".txt", ".md"}:
        return path.read_text(encoding="utf-8", errors="ignore").strip()

    if suffix == ".pdf":
        if PdfReader is None:
            raise ValueError("PDF support is unavailable. Install pypdf.")
        reader = PdfReader(str(path))
        pages = [page.extract_text() or "" for page in reader.pages]
        return "\n".join(pages).strip()

    try:
        image = Image.open(path)
        return pytesseract.image_to_string(image).strip()
    except UnidentifiedImageError as exc:
        raise ValueError("Unsupported file format. Use TXT, PDF, or image files.") from exc
