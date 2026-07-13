"""Vision-to-LLM contract analysis tool using Gemini multimodal."""
from __future__ import annotations
import base64
import io
import json

import google.generativeai as genai
from PIL import Image

from services import gemini_service

_SCAN_PROMPT = """당신은 한국 노동법 전문가입니다. 첨부된 근로계약서 이미지를 면밀히 분석하세요.

아래 항목을 반드시 검토하세요:
1. 임금 - 2025년 최저임금(시급 10,030원) 이상인지, 식대·교통비 별도 지급 여부
2. 근로시간 - 1일 8시간·주 40시간 초과 여부
3. 초과근무 수당 - 통상임금 50% 가산 명시 여부
4. 연차유급휴가 - 법정 연차 보장 여부
5. 해고 관련 - 부당해고 소지 조항 여부
6. 4대보험 - 가입 명시 여부
7. 기타 독소조항 - 사용자에게 일방적으로 유리한 조항

반드시 아래 JSON 형식으로만 응답하세요 (다른 텍스트 금지):
{
  "summary": "전체 분석 요약 ({{LANGUAGE}}로 작성)",
  "violations": [
    {
      "title": "위반 항목명",
      "content": "구체적 내용 설명",
      "severity": "high",
      "law": "근거 법조항"
    }
  ],
  "safe_items": ["문제 없는 항목"],
  "disclaimer": "⚠️ 본 서비스는 법적 조언이 아닌 참고용 가이드입니다. 최종 판단은 전문가에게 문의하세요."
}

severity 값: "high"(명백한 법 위반), "medium"(주의 필요), "low"(개선 권고)
"""

_LANG_MAP = {"ko": "한국어", "vi": "베트남어", "en": "영어"}


async def scan_contract_image(image_base64: str, language: str = "ko") -> dict:
    """Analyze a contract image and return violations as a structured dict."""
    gemini_service.configure()

    image_data = base64.b64decode(image_base64)
    image = Image.open(io.BytesIO(image_data))

    lang_name = _LANG_MAP.get(language, "한국어")
    prompt = _SCAN_PROMPT.replace("{{LANGUAGE}}", lang_name)

    model = genai.GenerativeModel("gemini-2.0-flash")

    import asyncio
    response = await asyncio.to_thread(model.generate_content, [image, prompt])

    text = response.text.strip()
    # Strip markdown code fences if present
    if text.startswith("```"):
        lines = text.split("\n")
        text = "\n".join(lines[1:-1] if lines[-1] == "```" else lines[1:])

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {
            "summary": text,
            "violations": [],
            "safe_items": [],
            "disclaimer": "⚠️ 본 서비스는 법적 조언이 아닌 참고용 가이드입니다.",
        }
