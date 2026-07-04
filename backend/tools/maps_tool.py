"""Nearby support center finder using CSV public data."""
from __future__ import annotations
import os
import math

import pandas as pd

_centers_df: pd.DataFrame | None = None
_DATA_PATH = os.path.join(os.path.dirname(__file__), "../data/public_centers.csv")

_TYPE_ALIASES = {
    "노동": "labor",
    "복지": "welfare",
    "법률": "legal",
    "법": "legal",
    "all": "all",
    "전체": "all",
    "labor": "labor",
    "welfare": "welfare",
    "legal": "legal",
}


def _load_centers() -> pd.DataFrame:
    global _centers_df
    if _centers_df is None:
        _centers_df = pd.read_csv(_DATA_PATH, dtype={"phone": str})
    return _centers_df


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    return R * 2 * math.asin(math.sqrt(a))


def find_nearby_centers(
    latitude: float,
    longitude: float,
    center_type: str = "all",
) -> tuple[str, list[dict]]:
    """사용자 위치 근처의 노동청·복지센터·법률상담 기관을 찾습니다.

    Args:
        latitude: 위도
        longitude: 경도
        center_type: 'labor'(노동청), 'welfare'(복지센터), 'legal'(법률상담), 'all'(전체)

    Returns:
        (기관 목록 설명 텍스트, 지도 핀 데이터 리스트)
    """
    df = _load_centers().copy()
    normalized = _TYPE_ALIASES.get(center_type.lower(), "all")
    if normalized != "all":
        df = df[df["type"] == normalized]

    df["dist_km"] = df.apply(
        lambda r: _haversine_km(latitude, longitude, r["lat"], r["lng"]), axis=1
    )
    nearest = df.nsmallest(3, "dist_km")

    pins: list[dict] = []
    desc_lines: list[str] = []
    for _, row in nearest.iterrows():
        pins.append(
            {
                "name": row["name"],
                "lat": float(row["lat"]),
                "lng": float(row["lng"]),
                "type": row["type"],
                "phone": str(row["phone"]),
                "address": row["address"],
            }
        )
        desc_lines.append(
            f"- {row['name']} ({row['address']}) | 전화: {row['phone']} | {row['hours']} | 거리: {row['dist_km']:.1f}km"
        )

    text = "가까운 지원 기관:\n" + "\n".join(desc_lines)
    return text, pins
