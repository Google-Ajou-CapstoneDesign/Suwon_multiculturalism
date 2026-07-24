# Local Bridge — Database 설계 문서

Supabase (PostgreSQL + pgvector) 기반 데이터베이스 구조를 정리한 문서입니다.  
`schema.sql`을 Supabase 대시보드 SQL Editor에 실행하면 전체 구조가 생성됩니다.

---

## 전체 구조 개요

```
knowledge_chunks          ← 에이전트 RAG 지식베이스 (노동법 + 비자정보)
public_centers            ← 수원시 공공기관 목록
users                     ← 실명 인증 사용자
chat_sessions             ← 에이전트 대화 히스토리
safe_workplaces           ← 안심 사업장 (모듈 3)
workplace_reviews         ← 사업장 실명 후기 (모듈 3)
community_posts           ← 자국민 실명 커뮤니티 (모듈 4)
```

### 마이그레이션 대상

| 기존 파일 | 대체 테이블 |
|-----------|------------|
| `backend/data/labor_law_chunks.json` | `knowledge_chunks` (category=`labor_law`) |
| `backend/data/public_centers.csv` | `public_centers` |
| `services/storage_service.py` (인메모리) | `chat_sessions` |
| `services/vector_db_service.py` (ChromaDB) | `knowledge_chunks` + pgvector RPC |

---

## 익스텐션

| 익스텐션 | 용도 |
|---------|------|
| `vector` | pgvector — 768차원 코사인 유사도 벡터 검색 |
| `uuid-ossp` | `uuid_generate_v4()` UUID 생성 |

---

## 테이블 상세

### 1. `knowledge_chunks` — RAG 지식베이스

에이전트 tools의 벡터 검색 공용 테이블. ChromaDB와 JSON 파일을 완전 대체합니다.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | TEXT | PK | `ll_001`, `vi_e9_001` 형식 |
| `category` | TEXT | NOT NULL, CHECK | `labor_law` 또는 `visa_info` |
| `topic` | TEXT | NOT NULL | 주제명 (`최저임금`, `E-9 근로 조건` 등) |
| `law` | TEXT | nullable | 관련 법령 — `labor_law` 전용 |
| `visa_type` | TEXT | nullable | 비자 유형 (`E-9`, `D-2` 등) — `visa_info` 전용 |
| `content` | TEXT | NOT NULL | 실제 지식 텍스트 |
| `keywords` | TEXT[] | nullable | 키워드 배열 |
| `embedding` | VECTOR(768) | nullable | text-embedding-004 임베딩 — 시딩 스크립트가 채움 |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | |

**시드 데이터**
- `labor_law` : 12건 (최저임금, 근로시간, 임금체불, 연차, 부당해고, 근로계약서, 4대보험, 퇴직금, 외국인 권리, 직장내괴롭힘, 주휴수당, 신고절차)
- `visa_info` : 4건 (E-9, D-2, F-4, D-4)
- embedding은 `NULL`로 삽입 → 백엔드 시딩 스크립트 실행 후 채워짐

---

### 2. `public_centers` — 공공기관

`find_nearby_centers` / `get_center_info` tool에서 조회하는 수원시 지원기관 목록.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | SERIAL | PK | |
| `name` | TEXT | NOT NULL | 기관명 |
| `type` | TEXT | NOT NULL, CHECK | `labor` / `welfare` / `legal` |
| `address` | TEXT | NOT NULL | 도로명 주소 |
| `lat` | DOUBLE PRECISION | NOT NULL | 위도 |
| `lng` | DOUBLE PRECISION | NOT NULL | 경도 |
| `phone` | TEXT | nullable | 전화번호 |
| `hours` | TEXT | nullable | 운영시간 |
| `supported_languages` | TEXT[] | nullable | 지원 언어 (`['ko','vi','zh']`) |
| `reservation_url` | TEXT | nullable | 예약 URL |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | |

**시드 데이터 (10건)**

| 기관명 | type |
|--------|------|
| 수원시외국인복지센터 | welfare |
| 경기수원고용노동청 | labor |
| 수원출입국·외국인청 | welfare |
| 수원시다문화가족지원센터(권선) | welfare |
| 수원시다문화가족지원센터(팔달) | welfare |
| 수원시 마을변호사(팔달구청) | legal |
| 수원시 마을변호사(영통구청) | legal |
| 한국산업인력공단 경기남부지사 | welfare |
| 경기도외국인인권지원센터 | welfare |
| 수원시 권선구 노동상담소 | labor |

---

### 3. `users` — 사용자

실명 인증 정보를 저장합니다. Flutter ProfileScreen의 인증 완료 시 레코드가 생성됩니다.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | |
| `nationality` | TEXT | nullable | `cn`, `vn` 등 국가 코드 |
| `visa_type` | TEXT | nullable | `E-9`, `D-2`, `F-4`, `D-4` 등 |
| `visa_number` | TEXT | nullable | 비자번호 (해시 저장 권장) |
| `is_verified` | BOOLEAN | DEFAULT FALSE | 실명 인증 완료 여부 |
| `preferred_lang` | TEXT | DEFAULT `ko`, CHECK | `ko` / `vi` / `zh` / `en` |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | |

---

### 4. `chat_sessions` — 채팅 세션

`storage_service.py`의 인메모리 히스토리를 영속화합니다.  
`history` 컬럼에 Gemini SDK `Content` 객체 배열을 JSON으로 직렬화해 저장합니다.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `session_id` | TEXT | PK | Flutter UUID v4 |
| `user_id` | UUID | FK → users(id), nullable | 실명 인증 사용자 연결 |
| `history` | JSONB | NOT NULL, DEFAULT `[]` | Gemini Content[] JSON 직렬화 |
| `language` | TEXT | DEFAULT `ko` | 사용자 언어 설정 |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | |

---

### 5. `safe_workplaces` — 안심 사업장 (모듈 3)

체불·산재보험 공공데이터 검증을 통과한 신뢰 사업장 목록.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | UUID | PK | |
| `name` | TEXT | NOT NULL | 사업장명 |
| `industry` | TEXT | NOT NULL | 업종 |
| `address` | TEXT | NOT NULL | |
| `lat` / `lng` | DOUBLE PRECISION | nullable | 좌표 |
| `phone` | TEXT | nullable | |
| `allowed_visa_types` | TEXT[] | nullable | 취업 가능 비자 목록 |
| `is_certified` | BOOLEAN | DEFAULT FALSE | 안심 사업장 인증 여부 |
| `certification_date` | TIMESTAMPTZ | nullable | 인증 일자 |
| `recertification_due` | TIMESTAMPTZ | nullable | 재인증 기한 |
| `public_data_verified` | BOOLEAN | DEFAULT FALSE | 공공데이터 검증 통과 여부 |
| `wage_direct_payment` | BOOLEAN | nullable | 임금 직접 지급 여부 |
| `review_count` | INTEGER | DEFAULT 0 | |
| `avg_rating` | NUMERIC(3,2) | nullable | 평균 평점 |
| `created_at` / `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | |

---

### 6. `workplace_reviews` — 사업장 후기 (모듈 3)

실명 인증 사용자의 사업장 후기.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | UUID | PK | |
| `workplace_id` | UUID | NOT NULL, FK → safe_workplaces(id) ON DELETE CASCADE | |
| `reviewer_nationality` | TEXT | NOT NULL | |
| `reviewer_visa_type` | TEXT | NOT NULL | |
| `rating` | SMALLINT | NOT NULL, CHECK (1~5) | |
| `content` | TEXT | nullable | 후기 본문 |
| `is_verified_worker` | BOOLEAN | DEFAULT FALSE | 재직·전직 이력 인증 여부 |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | |

---

### 7. `community_posts` — 커뮤니티 게시글 (모듈 4)

국적별 실명 커뮤니티 게시판. `nationality` 컬럼으로 중국어권/베트남어권 분리.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | UUID | PK | |
| `user_id` | UUID | FK → users(id), nullable | |
| `nationality` | TEXT | NOT NULL | `cn` / `vn` |
| `title` | TEXT | NOT NULL | |
| `content` | TEXT | NOT NULL | |
| `reply_count` | INTEGER | DEFAULT 0 | |
| `created_at` / `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | |

---

## RPC 함수 (벡터 검색)

백엔드에서 `supabase.rpc('함수명', {...})`로 호출합니다.

### `match_labor_law`

노동법 지식베이스 코사인 유사도 검색.

```sql
match_labor_law(
    query_embedding VECTOR(768),
    match_count     INT   DEFAULT 3,
    match_threshold FLOAT DEFAULT 0.5
)
-- 반환: id, topic, law, content, similarity
```

### `match_visa_info`

비자 정보 검색. `filter_visa_type`이 `NULL`이면 전체 비자를 대상으로 검색.

```sql
match_visa_info(
    query_embedding  VECTOR(768),
    filter_visa_type TEXT  DEFAULT NULL,
    match_count      INT   DEFAULT 3,
    match_threshold  FLOAT DEFAULT 0.5
)
-- 반환: id, topic, visa_type, content, similarity
```

**백엔드 호출 예시 (supabase-py)**

```python
result = supabase.rpc('match_labor_law', {
    'query_embedding': embedding_vector,  # list[float], len=768
    'match_count': 3,
    'match_threshold': 0.5
}).execute()
chunks = result.data
```

---

## 인덱스

| 인덱스명 | 테이블 | 컬럼 | 타입 | 목적 |
|---------|--------|------|------|------|
| `idx_knowledge_chunks_embedding` | knowledge_chunks | embedding | HNSW (cosine) | 벡터 검색 가속 |
| `idx_knowledge_chunks_category` | knowledge_chunks | category | btree | category 필터 |
| `idx_knowledge_chunks_visa_type` | knowledge_chunks | visa_type | btree | 비자 유형 필터 |
| `idx_public_centers_type` | public_centers | type | btree | 기관 유형 필터 |
| `idx_safe_workplaces_certified` | safe_workplaces | is_certified | btree | 인증 여부 필터 |
| `idx_workplace_reviews_workplace` | workplace_reviews | workplace_id | btree | 사업장별 후기 조회 |
| `idx_community_posts_nationality` | community_posts | nationality | btree | 국적별 게시글 필터 |
| `idx_chat_sessions_user` | chat_sessions | user_id | btree | 유저별 세션 조회 |

> HNSW 인덱스는 데이터 시딩 완료 후 생성해야 효과적입니다. 빈 테이블에는 효과가 없습니다.

---

## RLS (Row Level Security)

| 테이블 | 정책 |
|--------|------|
| `knowledge_chunks` | 전체 공개 읽기 |
| `public_centers` | 전체 공개 읽기 |
| `safe_workplaces` | 전체 공개 읽기 |
| `workplace_reviews` | 전체 공개 읽기 |
| `community_posts` | 전체 공개 읽기 |
| `chat_sessions` | JWT의 `session_id` 일치 시만 접근 |
| `users` | RLS 활성화 (정책 미정 — 서비스 역할 전용) |

백엔드 FastAPI는 `service_role` 키를 사용하므로 RLS를 우회합니다.  
클라이언트(Flutter)가 직접 Supabase에 접근하는 경우 `anon` 키 + RLS 정책을 추가로 설정해야 합니다.

---

## Supabase 적용 방법

1. Supabase 대시보드 → **SQL Editor** → `schema.sql` 전체 붙여넣기 → 실행
2. 환경변수 설정 (`.env` 또는 HF Spaces Secrets)

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
```

3. 백엔드 임베딩 시딩 스크립트 실행 (embedding이 NULL인 행에 text-embedding-004 벡터 채우기)
4. HNSW 인덱스 확인 (`schema.sql`의 인덱스 생성 구문은 데이터 존재 시 자동 적용)

---

## 백엔드 연동 현황

| 서비스 파일 | 현재 상태 | 마이그레이션 목표 |
|------------|----------|-----------------|
| `services/vector_db_service.py` | ChromaDB | Supabase `match_labor_law` RPC |
| `tools/maps_tool.py` | `public_centers.csv` 읽기 | Supabase `public_centers` 쿼리 |
| `tools/public_data_tool.py` | `public_centers.csv` 읽기 | Supabase `public_centers` 쿼리 |
| `services/storage_service.py` | 인메모리 dict | Supabase `chat_sessions` 테이블 |
