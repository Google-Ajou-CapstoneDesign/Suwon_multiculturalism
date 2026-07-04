"""Session storage for agent conversation history (in-memory for MVP)."""
from __future__ import annotations

_store: dict[str, list] = {}


def get_history(session_id: str) -> list:
    return list(_store.get(session_id, []))


def save_history(session_id: str, history: list) -> None:
    _store[session_id] = list(history)


def clear_session(session_id: str) -> None:
    _store.pop(session_id, None)
