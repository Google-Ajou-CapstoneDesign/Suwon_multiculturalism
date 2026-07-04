from __future__ import annotations
from typing import Optional, Literal
from pydantic import BaseModel


class Place(BaseModel):
    name: str
    lat: float
    lng: float
    type: Literal["labor", "welfare", "legal"]
    address: Optional[str] = None
    phone: Optional[str] = None
    hours: Optional[str] = None
    distance_km: Optional[float] = None
