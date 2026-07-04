# Suwon_multiculturalism
---
- 다문화 노동층을 위한 법률 보조, 환경 적응 Agent
1. 참여 동기 및 세부 주제 선정 배경
현대 대한민국의 인구 구조 변화 속에서 경기도 수원시는 6만 7천 명 이상의 외국인 주민이 거주하는 핵심 다문화 특례시로 부상하였다. 그러나 이주민들은 한국의 고도화된 행정 및 법률 시스템 앞에서 심각한 '정보 비대칭(Information Asymmetry)'을 겪고 있다. 기존 정부 지원 포털인 다누리(Live in Korea) 등은 방대한 정보를 단순히 나열하는 수동적(Passive) 도서관식 방식에 그쳐 실효성이 떨어지며, 파파고와 같은 단순 단어 단위 기계 번역 앱은 "통상임금", "위약 예정의 금지" 등 복잡한 한국 법률 용어 이면에 숨겨진 독소 조항의 맥락을 전혀 짚어내지 못한다.
특히 이들의 생존과 직결된 가장 심각한 위협은 '노동권 침해 및 고질적인 임금 체불'이다. 고용노동부 통계에 따르면 임금 체불 피해를 입은 외국인 근로자는 2만 3천여 명, 전체 체불액 규모는 약 1,108억 원에 달한다. 최근 수원 일대에서 발생한 임금 체불 호소 미등록 이주노동자의 강제 체포 사건은 현행 사후 구제 시스템의 맹점을 극명히 보여준다.
이러한 문제의식과 참가 동기를 바탕으로, 본 팀은 글로벌 빅테크인 Google의 선진 생성형 AI 인프라와 아주대학교의 학제 간 융합 역량을 결합하여, 지역 사회가 당면한 다문화 소외 문제를 실질적으로 해결하고자 본 대회에 참가하였다. 방학 기간 내 개발 리소스의 한계를 고려하여 MVP(최소 기능 제품)의 타겟을 광범위한 분야가 아닌 '근로계약 및 임금체불(노동권)' 단일 도메인으로 예리하게 집중(Selection and Concentration)하였으며, 관내 노동 및 거주 비율이 급증하고 있는 베트남 이주민을 1차 실증 타겟으로 설정하여 영어 및 베트남어 다국어 UI를 지원하는 '노동권 특화 지능형 챗봇' 서비스 개발을 기획하였다.
2. 핵심 아이디어(해결 과제) 요약
본 프로젝트의 최종 프로덕트인 'Co-Local'은 외부 API(Gemini 3.1 Pro, Google Maps, Cloud Vision 등)를 백엔드에서 유기적으로 연동하여 이주민의 모국어로 실시간 소통하는 '노동권 특화 지능형 챗봇'이다. 기존 포털과 달리 사용자의 상황을 인지하고 오프라인 해결 기관까지 원스톱으로 연결하며, 실증 이후 주거와 복지 등을 아우르는 '다목적 챗봇'으로의 확장을 Phase 2(장기 로드맵) 목표로 명확히 분리하였다. 이번 MVP의 핵심은 오직 '근로계약 스캐너'와 '로컬 생존 지도' 두 가지 기능에 집중되며, D+7, 30, 90일 단위의 자동 알림(Proactive Navigation) 기능은 향후 도입될 고도화 기능(Phase 2)으로 이관하였다.
첫째, Vision-to-LLM 기반 'AI 안심 근로계약 스캐너' 기능이다. 베트남 사용자가 근로계약서 사진을 채팅창에 전송하면, 고급 인텔리전스와 복잡한 문제 해결 기술을 갖춘 강력한 에이전트형 다중 모달(Multimodal) 추론에 특화된 최첨단 모델인 Gemini 3.1 Pro가 문서를 정밀 해독하여 근로기준법 위반 의심 조항을 식별(Flagging)하여 사용자에게 주의를 환기한다.
비교 지표	전통적 OCR (Tesseract 등)	Multimodal LLM (Gemini 3.1 Pro)
인식 원리	문자 형태의 단순 패턴 매칭 및 글자 단위 직역	압도적인 시각적 추론(Visual Reasoning)을 통한 이미지 구조와 텍스트 문맥 동시 분석
저품질 이미지 판독력	고도의 이미지 전처리(Preprocessing) 파이프라인 없이는 저품질 환경에서 판독력 급감	최첨단 에이전트형 인텔리전스로 구겨짐, 흐릿함, 조명 노이즈 등 악조건 환경에서도 뛰어난 판독 강건함 유지
표/레이아웃 유지	텍스트 직렬화로 인해 표의 구조와 법률적 맥락 상실	희소 전문가 혼합(MoE) 아키텍처를 통한 복잡한 표 레이아웃 및 텍스트 맥락 동시 보존
본 파이프라인은 민감 정보 보호를 위해 초기 온보딩 시 개인정보 수집 및 국외 이전 동의를 명시적으로 득하며, Cloud DLP를 기술적 안전장치로 적용하여 데이터 유출 리스크를 최소화한다. 또한 분석 결과 하단에 "⚠️ 본 서비스는 법적 조언이 아닌 참고용 가이드이며, 최종 판단은 전문가와 연계하십시오"라는 면책 조항(Disclaimer)을 필수 출력한다.
둘째, 지자체 공공데이터 RAG(검색 증강 생성)가 결합된 '대화형 로컬 생존 지도(Chat-map)' UX/UI를 구현한다. 공공데이터 RAG 구현의 기술적 신뢰도를 높이기 위해, Google text-embedding-004 임베딩 모델과 경량 벡터 DB(Vector DB)를 활용하여 최신 행정 데이터를 빠르고 정확하게 검색한다.
분류	데이터셋 명칭 및 출처	챗봇 연동 및 활용 방안
다문화 거점	경기데이터드림: 외국인복지센터 현황 API	사용자의 GPS 위치를 기반으로 최단 거리 노동/복지 상담 위탁기관 실시간 매칭
법률 구조	수원시 다문화가족지원센터 & 마을변호사 상담	부당 근로계약 또는 임금 체불 발생 시 수원시 무료 법률 상담(1899-3300) 예약 안내
사용자가 챗봇에게 *"나 지금 임금 500만 원을 못 받았는데 당장 어디로 가야 해?"*라고 묻는 즉시, Function Calling을 통해 Google Maps API가 작동하여 근처 관할 노동청이나 마을변호사 사무실에 붉은색 핀(Pin)을 떨어뜨리고 오프라인 예약을 돕는다.
이러한 구체적 기능 구현을 위한 추진 계획 및 성과 목표(융합적 관점)로, 본 프로젝트는 경영학(서비스 여정 설계 및 UI/UX 디자인), 소프트웨어학(풀스택 API 오케스트레이션 및 데이터 엔지니어링), 법학(노동법 및 행정 절차) 체계가 긴밀하게 결합된 다학제 간 융합적 관점의 결과물이다. 단기 추진 계획으로 하계 방학 기간 내 노동권 특화 MVP 구현 및 수원시 팔달구 일대 거주민 대상의 1차 테스트베드 실증을 완료할 예정이다. 이를 통한 최종 성과 목표는 전통적 OCR의 한계를 극복한 문맥 기반 근로계약서 판독 정확도 향상, 그리고 기존 포털 대비 이주민의 노동 행정 정보 탐색 시간 50% 단축 및 접근성 극대화를 지향한다.
3. 기대효과
이러한 통합적 접근은 정보 인프라 환경의 개선이 이주민의 자발적이고 안정적인 정착 행동을 이끌어낸다는 점에서 명확한 가치를 지닌다. 언어 장벽을 가진 이주민의 적응 실패를 개인의 탓으로 돌리는 대신, 정보 비대칭을 해소하는 능동적 안심 환경을 제공함으로써 긍정적인 행동 변화를 효과적으로 유도할 수 있다. 미시적으로는 사기 및 임금 체불 피해를 서명 단계에서 차단하여 경제적 피해를 예방하고 노동권을 보호한다. 거시적으로는 지자체 창구에 쏟아지는 단순 번역 및 위치 안내 민원을 AI가 1차 필터링함으로써 낭비되는 행정 인력을 중증 법률 구조로 전환하는 혁신을 이끈다.
궁극적인 결과물의 예상 형상 및 특허/논문/창업 발전 가능성 측면에서, 본 프로젝트의 결과물 예상 형상은 모바일 애플리케이션 기반의 '노동권 특화 지능형 챗봇'으로, 사용자의 접근성을 극대화한 온보딩(Sign-In) 화면, 모국어 중심의 지능형 채팅창, 계약서 분석을 위한 이미지 탭, 그리고 Function Calling으로 구동되는 실시간 지도(Map) 연동 화면으로 구성된다. 나아가 본 기술은 'Cloud DLP 기반 PII 마스킹 및 Multimodal LLM 연동 계약서 분석 파이프라인'의 독창성을 바탕으로 한 특허 출원 가능성을 보유하고 있으며, 학제 간 AI 융합 서비스 디자인의 선례로서 학술 논문 발표를 추진함과 동시에, 지자체 공공 인프라와 상생하는 소셜 벤처 형태로의 창업 발전 가능성까지 내포하고 있다. 수원시 실증 이후에는 별도의 거대한 서버 구축 없이도 외부 API 연동만으로 타 지자체에 손쉽게 이식하여 Phase 2의 다목적 플랫폼으로 스케일업(Scale-up) 될 것이다.

### 업데이트 내역
- 2026.07.03
requirements.txt	➡️	의존성 패키지 목록
.env.example	➡️	환경변수 템플릿
backend/app.py	➡️	FastAPI 앱 진입점, CORS, /chat 라우터 연결
backend/routers/chat.py	➡️	POST /chat 엔드포인트
backend/agents/main_agent.py	➡️	**Gemini Function Calling 루프**
backend/tools/contract_scanner.py	➡️	계약서 이미지 → 위반 조항 추출 (Gemini Vision)
backend/tools/labor_law_rag.py	➡️	노동법 ChromaDB 벡터 검색
backend/tools/maps_tool.py	➡️	주변 기관 검색 + 지도 핀 생성
backend/tools/dlp_tool.py	➡️	PII 마스킹 (regex + Cloud DLP 선택적)
backend/tools/translation_tool.py	➡️	다국어 번역
backend/tools/public_data_tool.py	➡️	수원시 공공기관 목록 조회
backend/services/gemini_service.py	➡️	Gemini API 키 설정
backend/services/vector_db_service.py	➡️	ChromaDB 초기화 + 자동 시딩
backend/services/google_maps_service.py	➡️	Google Maps 클라이언트
backend/services/storage_service.py	➡️	세션 히스토리 (메모리)
backend/schemas/chat.py	➡️	ChatRequest / ChatResponse 모델
backend/schemas/contract.py	➡️	ContractScanResult 모델
backend/schemas/place.py	➡️	Place 모델
backend/data/labor_law_chunks.json	➡️	노동법 지식베이스 12개 항목
backend/data/public_centers.csv	➡️	수원시 지원기관 10곳

---
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