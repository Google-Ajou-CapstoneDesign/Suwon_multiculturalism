from __future__ import annotations
from pydantic import BaseModel


class ErrorResponse(BaseModel):
    detail: str
    code: str = "INTERNAL_ERROR"


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
