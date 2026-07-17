# Suwon_multiculturalism
---
- 다문화 노동층을 위한 법률 보조, 환경 적응 Agent

### 업데이트 내역
- 2026.07.03
  - requirements.txt	➡️	의존성 패키지 목록
  - .env.example	➡️	환경변수 템플릿
  - backend/app.py	➡️	FastAPI 앱 진입점, CORS, /chat 라우터 연결
  - backend/routers/chat.py	➡️	POST /chat 엔드포인트
  - backend/agents/main_agent.py	➡️	**Gemini Function Calling 루프**
  - backend/tools/contract_scanner.py	➡️	계약서 이미지 → 위반 조항 추출 (Gemini Vision)
  - backend/tools/labor_law_rag.py	➡️	노동법 ChromaDB 벡터 검색
  - backend/tools/maps_tool.py	➡️	주변 기관 검색 + 지도 핀 생성
  - backend/tools/dlp_tool.py	➡️	PII 마스킹 (regex + Cloud DLP 선택적)
  - backend/tools/translation_tool.py	➡️	다국어 번역
  - backend/tools/public_data_tool.py	➡️	수원시 공공기관 목록 조회
  - backend/services/gemini_service.py	➡️	Gemini API 키 설정
  - backend/services/vector_db_service.py	➡️	ChromaDB 초기화 + 자동 시딩
  - backend/services/google_maps_service.py	➡️	Google Maps 클라이언트
  - backend/services/storage_service.py	➡️	세션 히스토리 (메모리)
  - backend/schemas/chat.py	➡️	ChatRequest / ChatResponse 모델
  - backend/schemas/contract.py	➡️	ContractScanResult 모델
  - backend/schemas/place.py	➡️	Place 모델
  - backend/data/labor_law_chunks.json	➡️	노동법 지식베이스 12개 항목
  - backend/data/public_centers.csv	➡️	수원시 지원기관 10곳
- 2026.07.14
  - frontend/pubspec.yaml ➡️ 패키지 추가 (http, image_picker, uuid)
  - frontend/lib/main.dart ➡️ CoLocalApp 진입점, HomeScreen 연결
  - frontend/lib/constants/api.dart ➡️ 백엔드 URL 상수 (10.0.2.2:8000)
  - frontend/lib/models/chat_message.dart ➡️ 채팅 메시지 모델
  - frontend/lib/models/chat_response.dart ➡️ API 응답 모델 (WarningCard, MapPin)
  - frontend/lib/services/chat_service.dart ➡️ POST /chat 호출, 이미지 base64 인코딩
  - frontend/lib/widgets/chat_bubble.dart ➡️ 사용자·봇 말풍선, 날짜 구분선, 로딩 인디케이터
  - frontend/lib/screens/home_screen.dart ➡️ 하단 탭 5개 (IndexedStack), 탭 간 상태 공유
  - frontend/lib/screens/chat_screen.dart ➡️ 채팅 UI (메시지 목록, 이미지 첨부, 전송)
  - frontend/lib/screens/image_screen.dart ➡️ 계약서 분석 결과 카드 목록
  - frontend/lib/screens/map_screen.dart ➡️ 주변 기관 목록 + 다음 행동 지침
  - frontend/lib/screens/notification_screen.dart ➡️ 알림 화면 (Stub)
  - frontend/lib/screens/profile_screen.dart ➡️ 프로필 화면 (Stub)
  - frontend/android/app/src/main/AndroidManifest.xml ➡️ 이미지·인터넷 권한 추가
- 2026.07.17
  - frontend/lib/screens/chat_screen.dart ➡️ DefaultTabController 크래시 → onGoToImageTab 콜백으로 수정
  - frontend/lib/screens/home_screen.dart ➡️ onGoToImageTab 콜백 전달 (이미지 탭 전환)
  - frontend/lib/widgets/chat_bubble.dart ➡️ NetworkImage → Image.file() 로컬 파일 렌더링 수정
  - backend/data/labor_law_chunks.json ➡️ 최저임금 2024(9,860원) → 2025(10,030원) 업데이트

---
### 파이프라인
- [Flutter UI]
  - 채팅 화면 (텍스트 입력 + 이미지 첨부)

  ↓
- [POST /chat] `routers/chat.py`
  - ChatRequest: session_id, message, image_base64, language, location

  ↓
- [DLP 마스킹] `tools/dlp_tool.py`
  - 사용자 메시지에서 주민등록번호·전화번호 등 PII 제거

  ↓
- [계약서 이미지 전처리] `tools/contract_scanner.py` ← 이미지 첨부 시만 실행
  - Gemini Vision으로 계약서 분석
  - 위반 조항 → WarningCard 생성
  - 분석 요약 → 에이전트 컨텍스트에 주입

  ↓
- [단일 에이전트] `agents/main_agent.py`
  - Gemini 3.1 Pro + Function Calling
  - 세션 히스토리 유지 (`services/storage_service.py`)
  - Function Calling 루프 (최대 8회):
```
    ├─ search_labor_law(query) → `tools/labor_law_rag.py`
    │    └─ ChromaDB 벡터 검색 (`services/vector_db_service.py`)
    │         └─ text-embedding-004 임베딩 → labor_law_chunks.json 조회
    │
    ├─ find_nearby_centers(lat, lng, type) → `tools/maps_tool.py`
    │    └─ public_centers.csv 거리 계산 → MapPin 생성
    │
    └─ get_center_info(type) → `tools/public_data_tool.py`
         └─ 수원시 기관 전체 목록 반환
```
  ↓
- [응답 구성] `agents/main_agent.py`
  - DLP 마스킹 (응답 텍스트)
  - 면책 문구 추가
  - next_actions 생성

  ↓
- [ChatResponse 반환]
  - reply        → 채팅 말풍선 (`screens/chat_screen.dart`)
  - warning_cards → 계약서 분석 카드 (`screens/image_screen.dart`)
  - map_pins      → 기관 목록 (`screens/map_screen.dart`)
  - next_actions  → 다음 행동 지침 (`screens/map_screen.dart`)



### 프로젝트 구조
```
backend/
 ├─ app.py
 ├─ routers/
 │   └─ chat.py
 ├─ agents/
 │   └─ main_agent.py
 ├─ tools/
 │   ├─ contract_scanner.py
 │   ├─ labor_law_rag.py
 │   ├─ maps_tool.py
 │   ├─ dlp_tool.py
 │   ├─ translation_tool.py
 │   └─ public_data_tool.py
 ├─ schemas/
 │   ├─ chat.py
 │   ├─ contract.py
 │   ├─ place.py
 │   └─ response.py
 ├─ services/
 │   ├─ gemini_service.py
 │   ├─ vector_db_service.py
 │   ├─ google_maps_service.py
 │   └─ storage_service.py
 └─ data/
     ├─ labor_law_chunks.json
     └─ public_centers.csv

frontend/
 └─ lib/
     ├─ main.dart
     ├─ constants/
     │   └─ api.dart
     ├─ models/
     │   ├─ chat_message.dart
     │   └─ chat_response.dart
     ├─ services/
     │   └─ chat_service.dart
     ├─ widgets/
     │   └─ chat_bubble.dart
     └─ screens/
         ├─ home_screen.dart
         ├─ chat_screen.dart
         ├─ image_screen.dart
         ├─ map_screen.dart
         ├─ notification_screen.dart
         └─ profile_screen.dart
```