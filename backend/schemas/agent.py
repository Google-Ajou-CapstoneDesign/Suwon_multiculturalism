from __future__ import annotations
from dataclasses import dataclass, field
from schemas.chat import WarningCard, MapPin


@dataclass
class TurnState:
    """Mutable state accumulated across a single agent turn."""
    warning_cards: list[WarningCard] = field(default_factory=list)
    map_pins: list[dict] = field(default_factory=list)
