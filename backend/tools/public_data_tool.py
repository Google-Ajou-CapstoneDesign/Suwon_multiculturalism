"""Public support center data lookup tool (CSV-based)."""
from __future__ import annotations
import os

import pandas as pd

_df: pd.DataFrame | None = None
_DATA_PATH = os.path.join(os.path.dirname(__file__), "../data/public_centers.csv")


def _load() -> pd.DataFrame:
    global _df
    if _df is None:
        _df = pd.read_csv(_DATA_PATH, dtype={"phone": str})
    return _df


def get_center_info(center_type: str = "all") -> str:
    """수원시 외국인 지원 기관의 목록과 연락처를 조회합니다.

    Args:
        center_type: 'labor'(노동청), 'welfare'(복지센터), 'legal'(법률상담), 'all'(전체)

    Returns:
        기관 목록 텍스트
    """
    df = _load()
    if center_type != "all":
        df = df[df["type"] == center_type]

    if df.empty:
        return "해당 유형의 기관 정보를 찾을 수 없습니다."

    lines = [
        f"- {row['name']} | 주소: {row['address']} | 전화: {row['phone']} | 운영: {row['hours']}"
        for _, row in df.iterrows()
    ]
    return "\n".join(lines)
