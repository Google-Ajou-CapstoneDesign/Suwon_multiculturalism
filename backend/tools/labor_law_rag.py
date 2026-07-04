"""RAG-based Korean labor law search tool."""
from __future__ import annotations
from services import vector_db_service


def search_labor_law(query: str) -> str:
    """한국 노동법 관련 법조항을 검색합니다. 임금, 근로시간, 해고, 연차, 임금체불 등 노동 관련 질문에 사용하세요.

    Args:
        query: 검색할 노동법 키워드 또는 질문 (예: "최저임금", "연장근무 수당", "부당해고")

    Returns:
        관련 법조항 텍스트
    """
    results = vector_db_service.search(query, n_results=3)

    if not results:
        return "관련 노동법 조항을 찾지 못했습니다."

    parts = [f"[{r['law']}]\n{r['content']}" for r in results]
    return "\n\n".join(parts)