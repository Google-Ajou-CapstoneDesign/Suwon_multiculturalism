# Suwon_multiculturalism
---
- 다문화 노동층을 위한 법률 보조, 환경 적응 Agent

### 파이프라인
- [User App]
  ↓
- [Input Gateway]
  - text/image/location 수신
  - user language 확인
  - consent 확인

  ↓
- [Safety Layer]
  - 개인정보 포함 여부 확인
  - 위치/이미지 처리 가능 여부 확인
  - 필요 시 DLP 마스킹

  ↓
- [Intent Router]
  - 계약서 분석
  - 임금체불 상담
  - 기관 찾기
  - 법률 용어 설명
  - 일반 질문

  ↓
- [Planner Agent]
  - 필요한 tool 목록 결정
  - 실행 순서 결정
  - 위험도 판단

  ↓
- [Tool Executor]
  - Gemini Multimodal
  - Cloud Vision
  - Labor Law RAG
  - Public Data Search
  - Google Maps
  - Translation

  ↓
- [Verifier]
  - 근거 검증
  - 개인정보 검증
  - 단정적 법률 표현 제거
  - 면책 문구 확인

  ↓
- [Response Composer]
  - 사용자 모국어로 요약
  - 위험 조항 카드 생성
  - 지도 핀 데이터 생성
  - 다음 행동 제안

  ↓
- [Flutter UI]
  - 채팅 답변
  - 경고 카드
  - 지도 핀
  - 전화/예약 버튼



### 백엔드 구조
'''
backend/
 ├─ main.py
 ├─ agents/
 │   ├─ main_agent.py
 │   ├─ planner.py
 │   └─ router.py
 ├─ tools/
 │   ├─ contract_scanner.py
 │   ├─ labor_law_rag.py
 │   ├─ maps_tool.py
 │   ├─ dlp_tool.py
 │   ├─ translation_tool.py
 │   └─ public_data_tool.py
 ├─ schemas/
 │   ├─ agent.py
 │   ├─ contract.py
 │   ├─ place.py
 │   └─ response.py
 ├─ services/
 │   ├─ gemini_service.py
 │   ├─ google_maps_service.py
 │   ├─ vector_db_service.py
 │   └─ storage_service.py
 └─ data/
     ├─ labor_law_chunks.json
     └─ public_centers.csv
'''