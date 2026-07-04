from __future__ import annotations
from typing import Optional, Literal
from pydantic import BaseModel


class Location(BaseModel):
    lat: float
    lng: float


class ChatRequest(BaseModel):
    session_id: str
    message: str
    image_base64: Optional[str] = None
    language: Literal["ko", "vi", "en"] = "ko"
    location: Optional[Location] = None


class WarningCard(BaseModel):
    title: str
    content: str
    severity: Literal["high", "medium", "low"]


class MapPin(BaseModel):
    name: str
    lat: float
    lng: float
    type: Literal["labor", "welfare", "legal"]
    phone: Optional[str] = None
    address: Optional[str] = None


class ChatResponse(BaseModel):
    session_id: str
    reply: str
    warning_cards: list[WarningCard] = []
    map_pins: list[MapPin] = []
    next_actions: list[str] = []
