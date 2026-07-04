"""Single-agent orchestrator using Gemini function calling."""
from __future__ import annotations
import asyncio

import google.generativeai as genai

from schemas.chat import ChatRequest, ChatResponse, MapPin, WarningCard
from tools import contract_scanner, dlp_tool, labor_law_rag, maps_tool, public_data_tool
from services import gemini_service, storage_service

_LANG_NAMES = {"ko": "한국어", "vi": "베트남어", "en": "English"}

_DISCLAIMERS = {
    "ko": "⚠️ 본 서비스는 법적 조언이 아닌 참고용 가이드입니다. 최종 판단은 전문가와 상담하세요.",
    "vi": "⚠️ Dịch vụ này chỉ mang tính tham khảo, không phải tư vấn pháp lý. Hãy tham khảo ý kiến chuyên gia.",
    "en": "⚠️ This service is for reference only and not legal advice. Please consult a professional.",
}

_SYSTEM_PROMPT = """당신은 Co-Local입니다. 수원시에 거주하는 이주 근로자를 위한 노동권 전문 AI 어시스턴트입니다.

주요 역할:
- 근로계약서의 법 위반 조항 분석 및 설명
- 한국 노동법(임금·근로시간·해고·연차·4대보험 등) 질문 답변
- 주변 노동청·복지센터·법률상담 기관 안내
- 임금체불 등 노동권 침해 상황 대처 방법 안내

반드시 {LANGUAGE}로 응답하세요.
답변은 명확하고 실용적이어야 하며, 구체적인 연락처와 다음 행동 지침을 포함하세요.
법적 책임 면책 문구를 항상 답변 말미에 포함하세요."""


async def run_agent(request: ChatRequest) -> ChatResponse:
    gemini_service.configure()

    language = request.language
    session_id = request.session_id

    # 1. Contract image pre-processing (before main agent loop)
    warning_cards: list[WarningCard] = []
    contract_context = ""
    if request.image_base64:
        scan_result = await contract_scanner.scan_contract_image(
            request.image_base64, language
        )
        for v in scan_result.get("violations", []):
            warning_cards.append(
                WarningCard(
                    title=v.get("title", "위반 항목"),
                    content=v.get("content", ""),
                    severity=v.get("severity", "medium"),
                )
            )
        summary = scan_result.get("summary", "")
        if summary:
            contract_context = f"\n\n[계약서 분석 완료]\n{summary}"
            if warning_cards:
                issues = "\n".join(f"- {w.title}: {w.content}" for w in warning_cards)
                contract_context += f"\n\n발견된 문제:\n{issues}"

    # 2. Per-turn mutable state (closures below write into these)
    map_pins_buffer: list[dict] = []

    # 3. Tool functions — closures that capture map_pins_buffer
    def search_labor_law(query: str) -> str:
        """한국 노동법 관련 법조항을 검색합니다. 임금·근로시간·해고·연차·4대보험·임금체불 등 노동 관련 질문에 사용하세요.

        Args:
            query: 검색할 키워드 또는 질문 (예: '최저임금', '연장근무 수당', '부당해고 신고')
        """
        return labor_law_rag.search_labor_law(query)

    def find_nearby_centers(latitude: float, longitude: float, center_type: str = "all") -> str:
        """사용자 위치 근처의 노동청·복지센터·법률상담 기관을 찾아 지도에 핀을 꽂습니다.

        Args:
            latitude: 위도 (사용자 GPS 또는 메시지에서 추출)
            longitude: 경도 (사용자 GPS 또는 메시지에서 추출)
            center_type: 'labor'(노동청/고용센터), 'welfare'(복지센터/다문화센터), 'legal'(법률상담), 'all'(전체)
        """
        desc, pins = maps_tool.find_nearby_centers(latitude, longitude, center_type)
        map_pins_buffer.extend(pins)
        return desc

    def get_center_info(center_type: str = "all") -> str:
        """수원시 외국인 지원 기관의 전체 목록과 연락처를 조회합니다.

        Args:
            center_type: 'labor', 'welfare', 'legal', 'all'
        """
        return public_data_tool.get_center_info(center_type)

    # 4. Build model with tools
    lang = _LANG_NAMES.get(language, "한국어")
    system = _SYSTEM_PROMPT.replace("{LANGUAGE}", lang)

    model = genai.GenerativeModel(
        model_name="gemini-2.0-flash",
        tools=[search_labor_law, find_nearby_centers, get_center_info],
        system_instruction=system,
    )

    history = storage_service.get_history(session_id)
    chat = model.start_chat(history=history)

    # 5. Build message
    user_text = dlp_tool.mask_pii(request.message)
    if request.location:
        user_text += f"\n[현재 위치: 위도 {request.location.lat}, 경도 {request.location.lng}]"
    user_text += contract_context

    msg_parts: list = []
    if request.image_base64:
        import base64, io
        from PIL import Image
        img_bytes = base64.b64decode(request.image_base64)
        img = Image.open(io.BytesIO(img_bytes))
        msg_parts.append(img)
    msg_parts.append(user_text)

    # 6. Agent loop — manual function calling for full control
    response = await asyncio.to_thread(chat.send_message, msg_parts)

    for _ in range(8):
        fn_calls = [
            p.function_call
            for p in response.parts
            if hasattr(p, "function_call") and p.function_call.name
        ]
        if not fn_calls:
            break

        tool_map = {
            "search_labor_law": search_labor_law,
            "find_nearby_centers": find_nearby_centers,
            "get_center_info": get_center_info,
        }

        tool_responses = []
        for fc in fn_calls:
            fn = tool_map.get(fc.name)
            try:
                result = fn(**dict(fc.args)) if fn else f"알 수 없는 도구: {fc.name}"
            except Exception as exc:
                result = f"도구 오류: {exc}"

            tool_responses.append(
                genai.protos.Part(
                    function_response=genai.protos.FunctionResponse(
                        name=fc.name,
                        response={"result": result},
                    )
                )
            )

        response = await asyncio.to_thread(chat.send_message, tool_responses)

    # 7. Collect final reply text
    reply_parts = [p.text for p in response.parts if hasattr(p, "text") and p.text]
    reply = dlp_tool.mask_pii("".join(reply_parts))

    # Append disclaimer if labor / contract content was involved
    if warning_cards or map_pins_buffer:
        reply += f"\n\n{_DISCLAIMERS.get(language, _DISCLAIMERS['ko'])}"

    # 8. Persist session history
    storage_service.save_history(session_id, list(chat.history))

    # 9. Build next actions
    next_actions: list[str] = []
    if warning_cards:
        next_actions += [
            "고용노동부 신고: ☎1350 (무료, 외국어 지원)",
            "수원시 마을변호사 무료상담: ☎1899-3300",
        ]
    if map_pins_buffer:
        next_actions.append("지도에서 가까운 기관 위치 확인")

    return ChatResponse(
        session_id=session_id,
        reply=reply,
        warning_cards=warning_cards,
        map_pins=[MapPin(**p) for p in map_pins_buffer],
        next_actions=next_actions,
    )
