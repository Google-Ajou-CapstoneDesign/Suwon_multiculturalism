---
title: Local Bridge API
emoji: 🌉
colorFrom: blue
colorTo: green
sdk: docker
pinned: false
app_port: 7860
---

# Local Bridge — Backend API

외국인 근로자를 위한 AI 기반 노동권익 보호 플랫폼 **Local Bridge**의 FastAPI 백엔드입니다.  
Hugging Face Spaces (CPU Basic) 위에서 동작하며, Flutter 앱과 `/chat` 엔드포인트로 통신합니다.

---

## 엔드포인트

| Method | Path | 설명 |
|--------|------|------|
| GET | `/` | 서버 상태 확인 |
| GET | `/health` | 헬스체크 |
| POST | `/chat` | 메인 에이전트 호출 |

### POST `/chat` — 요청

```json
{
  "session_id": "uuid-v4",
  "message": "주휴수당이 뭐예요?",
  "image_base64": "...(선택, 계약서 이미지)",
  "language": "ko",
  "location": { "lat": 37.2636, "lng": 127.0286 }
}
```

### POST `/chat` — 응답

```json
{
  "session_id": "uuid-v4",
  "reply": "주휴수당은 ...",
  "warning_cards": [
    { "title": "최저임금 미달", "content": "...", "severity": "high", "law": "최저임금법 제6조" }
  ],
  "map_pins": [
    { "name": "수원시외국인복지센터", "address": "...", "lat": 37.27, "lng": 127.01, "phone": "031-..." }
  ],
  "next_actions": ["고용노동부 1350에 전화하세요"]
}
```

---

## 파이프라인

```
POST /chat
  └─ DLP 마스킹 (PII 제거)
  └─ 계약서 이미지 전처리 (이미지 첨부 시, Gemini Vision)
  └─ Gemini 3.1 Pro 단일 에이전트 + Function Calling 루프 (최대 8회)
       ├─ search_labor_law(query)          → ChromaDB 벡터 검색
       ├─ find_nearby_centers(lat, lng)    → 수원시 기관 거리 계산
       └─ get_center_info(type)            → 기관 목록 조회
  └─ ChatResponse 반환
```

---

## 환경변수 (HF Spaces Secrets)

Space 설정 → **Variables and secrets** 에서 아래 항목을 Secret으로 등록하세요.

| 변수명 | 필수 | 설명 |
|--------|------|------|
| `GEMINI_API_KEY` | ✅ | Google AI Studio API 키 |
| `GOOGLE_MAPS_API_KEY` | 선택 | Maps API (미설정 시 maps_tool 비활성) |
| `GOOGLE_CLOUD_PROJECT_ID` | 선택 | Cloud DLP 사용 시 필요 |

> `VECTOR_DB_PATH`는 Dockerfile에서 `/data/chromadb`로 자동 설정됩니다.  
> 첫 실행 시 `labor_law_chunks.json`에서 자동 시딩되며, `/data`에 저장되어 재시작 시 유지됩니다.

---

## 로컬 실행

```bash
cd backend
cp ../.env.example .env   # 환경변수 설정
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

Flutter 에뮬레이터에서 접근할 때는 `http://10.0.2.2:8000` 을 사용하세요.

---

## 기술 스택

- **Runtime**: Python 3.11 / FastAPI / Uvicorn
- **AI**: Gemini 3.1 Pro (Function Calling), `text-embedding-004`
- **Vector DB**: ChromaDB (persistent, `/data/chromadb`)
- **PII**: Google Cloud DLP (선택) / regex fallback
- **배포**: Hugging Face Spaces — Docker SDK, CPU Basic (2 vCPU / 16 GB RAM)
