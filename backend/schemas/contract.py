from __future__ import annotations
from typing import Literal
from pydantic import BaseModel


class ContractViolation(BaseModel):
    title: str
    content: str
    severity: Literal["high", "medium", "low"]
    law: str = ""


class ContractScanResult(BaseModel):
    summary: str
    violations: list[ContractViolation] = []
    safe_items: list[str] = []
    disclaimer: str = "본 서비스는 법적 조언이 아닌 참고용 가이드입니다."
