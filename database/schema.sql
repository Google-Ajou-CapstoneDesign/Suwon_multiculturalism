-- =============================================================
-- Local Bridge — Supabase Schema
-- text-embedding-004 기준 벡터 차원: 768
-- =============================================================


-- =============================================================
-- 0. EXTENSIONS
-- =============================================================

CREATE EXTENSION IF NOT EXISTS vector;       -- pgvector (RAG 벡터 검색)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- UUID 생성


-- =============================================================
-- 1. RAG 지식베이스 (에이전트 tools 공용)
--    ChromaDB + labor_law_chunks.json + visa_info 통합 대체
--    category: 'labor_law' | 'visa_info'
-- =============================================================

CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id          TEXT PRIMARY KEY,             -- 'll_001', 'vi_e9_001' 등
    category    TEXT NOT NULL                 -- 'labor_law' | 'visa_info'
                CHECK (category IN ('labor_law', 'visa_info')),
    topic       TEXT NOT NULL,                -- '최저임금', 'E-9 근로시간' 등
    law         TEXT,                         -- 관련 법령 (labor_law용)
    visa_type   TEXT,                         -- 비자 유형 (visa_info용, nullable)
    content     TEXT NOT NULL,
    keywords    TEXT[],
    embedding   VECTOR(768),                  -- text-embedding-004 임베딩 (시딩 후 채워짐)
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE knowledge_chunks IS
    '에이전트 RAG 지식베이스. category로 labor_law/visa_info 구분.
     embedding은 백엔드 시딩 스크립트가 Gemini text-embedding-004로 채운다.';


-- =============================================================
-- 2. 공공기관 데이터
--    public_centers.csv 대체
--    find_nearby_centers / get_center_info tool 용
-- =============================================================

CREATE TABLE IF NOT EXISTS public_centers (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    type        TEXT NOT NULL
                CHECK (type IN ('labor', 'welfare', 'legal')),
    address     TEXT NOT NULL,
    lat         DOUBLE PRECISION NOT NULL,
    lng         DOUBLE PRECISION NOT NULL,
    phone       TEXT,
    hours       TEXT,
    supported_languages TEXT[],               -- ['ko','vi','zh'] 등
    reservation_url     TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public_centers IS '수원시 노동·복지·법률 지원 기관 목록. 기관 추가·수정은 이 테이블에서 관리.';


-- =============================================================
-- 3. 사용자 & 세션
-- =============================================================

-- 3-1. 사용자 (실명 인증 정보 포함)
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nationality     TEXT,                     -- 'cn' | 'vn' | etc.
    visa_type       TEXT,                     -- 'E-9' | 'D-2' | 'F-4' 등
    visa_number     TEXT,                     -- 인증에 쓰인 비자 번호 (해시 저장 권장)
    is_verified     BOOLEAN DEFAULT FALSE,    -- 실명 인증 완료 여부
    preferred_lang  TEXT DEFAULT 'ko'
                    CHECK (preferred_lang IN ('ko', 'vi', 'zh', 'en')),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 3-2. 채팅 세션 (에이전트 히스토리 영속화)
--      현재 storage_service.py 인메모리 대체
CREATE TABLE IF NOT EXISTS chat_sessions (
    session_id  TEXT PRIMARY KEY,             -- Flutter UUID v4
    user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    history     JSONB NOT NULL DEFAULT '[]', -- Gemini chat history (Content[])
    language    TEXT DEFAULT 'ko',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON COLUMN chat_sessions.history IS
    'Gemini SDK Content 객체 배열을 JSON으로 직렬화한 값.
     run_agent()에서 chat.history를 jsonable_encoder로 변환 후 저장.';


-- =============================================================
-- 4. 서비스 기능 테이블 (모듈 3 — 안심 사업장 / 모듈 4 — 커뮤니티)
-- =============================================================

-- 4-1. 안심 사업장 (모듈 3)
CREATE TABLE IF NOT EXISTS safe_workplaces (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                    TEXT NOT NULL,
    industry                TEXT NOT NULL,
    address                 TEXT NOT NULL,
    lat                     DOUBLE PRECISION,
    lng                     DOUBLE PRECISION,
    phone                   TEXT,
    allowed_visa_types      TEXT[],           -- ['E-9','D-2'] 등 취업 가능 비자
    is_certified            BOOLEAN DEFAULT FALSE,
    certification_date      TIMESTAMPTZ,
    recertification_due     TIMESTAMPTZ,      -- 재인증 기한
    public_data_verified    BOOLEAN DEFAULT FALSE, -- 체불명단·산재보험 공공데이터 통과
    wage_direct_payment     BOOLEAN,          -- 임금 직접 지급 여부 (건설업 팀장 구조 방지)
    review_count            INTEGER DEFAULT 0,
    avg_rating              NUMERIC(3, 2),
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- 4-2. 사업장 실명 후기 (모듈 3)
CREATE TABLE IF NOT EXISTS workplace_reviews (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workplace_id        UUID NOT NULL REFERENCES safe_workplaces(id) ON DELETE CASCADE,
    reviewer_nationality TEXT NOT NULL,
    reviewer_visa_type  TEXT NOT NULL,
    rating              SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    content             TEXT,
    is_verified_worker  BOOLEAN DEFAULT FALSE, -- 재직·전직 이력 인증 여부
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 4-3. 자국민 실명 커뮤니티 게시글 (모듈 4)
CREATE TABLE IF NOT EXISTS community_posts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    nationality TEXT NOT NULL,                -- 'cn' | 'vn' (국적별 분리)
    title       TEXT NOT NULL,
    content     TEXT NOT NULL,
    reply_count INTEGER DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);


-- =============================================================
-- 5. 벡터 검색 RPC 함수 (Supabase RPC 호출용)
--    백엔드: supabase.rpc('match_labor_law', {...})
-- =============================================================

-- 5-1. 노동법 RAG 검색
CREATE OR REPLACE FUNCTION match_labor_law(
    query_embedding VECTOR(768),
    match_count     INT     DEFAULT 3,
    match_threshold FLOAT   DEFAULT 0.5
)
RETURNS TABLE (
    id          TEXT,
    topic       TEXT,
    law         TEXT,
    content     TEXT,
    similarity  FLOAT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        kc.id,
        kc.topic,
        kc.law,
        kc.content,
        1 - (kc.embedding <=> query_embedding) AS similarity
    FROM knowledge_chunks kc
    WHERE
        kc.category = 'labor_law'
        AND kc.embedding IS NOT NULL
        AND 1 - (kc.embedding <=> query_embedding) > match_threshold
    ORDER BY kc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- 5-2. 비자 정보 RAG 검색 (visa_type 필터 옵션)
CREATE OR REPLACE FUNCTION match_visa_info(
    query_embedding VECTOR(768),
    filter_visa_type TEXT     DEFAULT NULL,   -- NULL이면 전체 비자 검색
    match_count      INT      DEFAULT 3,
    match_threshold  FLOAT    DEFAULT 0.5
)
RETURNS TABLE (
    id          TEXT,
    topic       TEXT,
    visa_type   TEXT,
    content     TEXT,
    similarity  FLOAT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        kc.id,
        kc.topic,
        kc.visa_type,
        kc.content,
        1 - (kc.embedding <=> query_embedding) AS similarity
    FROM knowledge_chunks kc
    WHERE
        kc.category = 'visa_info'
        AND kc.embedding IS NOT NULL
        AND (filter_visa_type IS NULL OR kc.visa_type = filter_visa_type)
        AND 1 - (kc.embedding <=> query_embedding) > match_threshold
    ORDER BY kc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;


-- =============================================================
-- 6. 인덱스
-- =============================================================

-- 벡터 인덱스 (HNSW: 소규모 데이터셋에 IVFFlat보다 효율적)
-- 주의: 데이터 시딩 완료 후 생성 권장 (빈 테이블에는 효과 없음)
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_embedding
    ON knowledge_chunks USING hnsw (embedding vector_cosine_ops);

-- 카테고리·비자 유형 필터용
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_category ON knowledge_chunks (category);
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_visa_type ON knowledge_chunks (visa_type);

-- 기관 타입 필터
CREATE INDEX IF NOT EXISTS idx_public_centers_type ON public_centers (type);

-- 안심 사업장 인증 상태
CREATE INDEX IF NOT EXISTS idx_safe_workplaces_certified ON safe_workplaces (is_certified);
CREATE INDEX IF NOT EXISTS idx_workplace_reviews_workplace ON workplace_reviews (workplace_id);

-- 커뮤니티 국적 필터
CREATE INDEX IF NOT EXISTS idx_community_posts_nationality ON community_posts (nationality);

-- 세션 조회
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user ON chat_sessions (user_id);


-- =============================================================
-- 7. RLS (Row Level Security)
-- =============================================================

ALTER TABLE knowledge_chunks   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_centers     ENABLE ROW LEVEL SECURITY;
ALTER TABLE users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE safe_workplaces    ENABLE ROW LEVEL SECURITY;
ALTER TABLE workplace_reviews  ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts    ENABLE ROW LEVEL SECURITY;

-- 공공 데이터: 누구나 읽기 가능
CREATE POLICY "knowledge_chunks 공개 읽기"
    ON knowledge_chunks FOR SELECT USING (true);

CREATE POLICY "public_centers 공개 읽기"
    ON public_centers FOR SELECT USING (true);

CREATE POLICY "safe_workplaces 공개 읽기"
    ON safe_workplaces FOR SELECT USING (true);

CREATE POLICY "workplace_reviews 공개 읽기"
    ON workplace_reviews FOR SELECT USING (true);

CREATE POLICY "community_posts 공개 읽기"
    ON community_posts FOR SELECT USING (true);

-- 세션: session_id 소유자만 읽기·쓰기
CREATE POLICY "chat_sessions 본인만 접근"
    ON chat_sessions FOR ALL
    USING (session_id = current_setting('request.jwt.claims', true)::json->>'session_id');

-- service_role (백엔드 API)은 RLS 우회 — Supabase 기본 동작


-- =============================================================
-- 8. 시드 데이터
-- =============================================================

-- ── 8-1. public_centers (public_centers.csv 이전) ──────────

INSERT INTO public_centers (name, type, address, lat, lng, phone, hours) VALUES
    ('수원시외국인복지센터',     'welfare', '경기도 수원시 팔달구 팔달로 198',          37.2694, 127.0146, '031-246-1712', '월-금 09:00-18:00'),
    ('경기수원고용노동청',       'labor',   '경기도 수원시 영통구 도청로 30',            37.2701, 127.0543, '1350',         '월-금 09:00-18:00'),
    ('수원출입국·외국인청',     'welfare', '경기도 수원시 영통구 도청로 30',            37.2701, 127.0543, '1345',         '월-금 09:00-18:00'),
    ('수원시다문화가족지원센터(권선)', 'welfare', '경기도 수원시 권선구 권선로 599',   37.2548, 127.0030, '031-244-3997', '월-금 09:00-18:00'),
    ('수원시다문화가족지원센터(팔달)', 'welfare', '경기도 수원시 팔달구 향교로 107',   37.2766, 127.0098, '031-257-3997', '월-금 09:00-18:00'),
    ('수원시 마을변호사(팔달구청)',   'legal',   '경기도 수원시 팔달구 효원로 1',       37.2764, 127.0096, '1899-3300',    '화 14:00-16:00'),
    ('수원시 마을변호사(영통구청)',   'legal',   '경기도 수원시 영통구 영통로 261',     37.2467, 127.0604, '1899-3300',    '수 14:00-16:00'),
    ('한국산업인력공단 경기남부지사', 'welfare', '경기도 수원시 팔달구 효원로 1',       37.2764, 127.0096, '031-240-1700', '월-금 09:00-18:00'),
    ('경기도외국인인권지원센터',     'welfare', '경기도 수원시 팔달구 중부대로 211',   37.2754, 127.0165, '031-235-0067', '월-금 09:00-18:00'),
    ('수원시 권선구 노동상담소',     'labor',   '경기도 수원시 권선구 권선로 185',     37.2528, 127.0082, '031-228-8200', '월-금 09:00-18:00')
ON CONFLICT DO NOTHING;


-- ── 8-2. knowledge_chunks — labor_law (labor_law_chunks.json 이전) ──
--         embedding은 NULL → 백엔드 시딩 스크립트가 채움

INSERT INTO knowledge_chunks (id, category, topic, law, content, keywords) VALUES

('ll_001', 'labor_law', '최저임금', '최저임금법 제6조·제28조',
 '2025년 최저임금은 시간당 10,030원입니다. 사용자는 반드시 최저임금 이상을 지급해야 하며, 이를 위반하면 3년 이하 징역 또는 2천만 원 이하 벌금에 처합니다. 식비·교통비 등 복리후생 명목 금품은 최저임금 산입에서 제외됩니다. 수습 기간(3개월 이내)에는 최저임금의 90%까지 지급 가능하나, 단순노무 직종에는 적용되지 않습니다.',
 ARRAY['최저임금','시급','임금','급여','월급','시간당']),

('ll_002', 'labor_law', '근로시간', '근로기준법 제50조·제53조·제56조',
 '법정 근로시간은 1일 8시간, 1주 40시간입니다. 당사자 합의 시 1주 12시간 한도의 연장근로가 가능합니다(주 최대 52시간). 연장근로에 대해서는 통상임금의 50%를 가산 지급해야 합니다. 야간근로(오후 10시~오전 6시)와 휴일근로도 각각 통상임금의 50%를 가산해야 합니다. 연장·야간·휴일이 겹칠 경우 100%까지 가산됩니다.',
 ARRAY['근로시간','초과근무','야간근무','연장근로','주52시간','야간수당','휴일수당']),

('ll_003', 'labor_law', '임금체불', '근로기준법 제36조·제43조·제109조',
 '사용자는 임금을 매월 1회 이상 일정한 날짜에 직접 근로자에게 지급해야 합니다. 임금이 체불된 경우 근로자는 관할 고용노동청에 진정을 제기할 수 있습니다. 임금체불 사용자는 3년 이하 징역 또는 3천만 원 이하 벌금에 처합니다. 퇴직 후에는 14일 이내에 모든 임금을 지급해야 하며, 위반 시 지연 이자(연 20%)가 발생합니다. 외국인 근로자도 동일하게 보호받습니다.',
 ARRAY['임금체불','임금미지급','월급체불','퇴직금','미지급','지각비']),

('ll_004', 'labor_law', '연차유급휴가', '근로기준법 제60조',
 '1년간 80% 이상 출근한 근로자에게 15일의 유급휴가가 부여됩니다. 3년 이상 계속 근무 시 2년마다 1일씩 추가(최대 25일). 1년 미만 근로자는 매월 개근 시 1일의 유급휴가가 발생합니다. 사용하지 못한 연차에 대해서는 연차수당(통상임금 × 미사용 일수)을 지급해야 합니다.',
 ARRAY['연차','유급휴가','연차수당','휴가','월차']),

('ll_005', 'labor_law', '부당해고', '근로기준법 제23조·제26조·제27조',
 '사용자는 정당한 이유 없이 근로자를 해고하지 못합니다. 해고 시 최소 30일 전에 서면으로 예고해야 하며, 예고 없이 해고할 경우 30일분 이상의 통상임금을 지급해야 합니다. 해고를 당한 근로자는 해고일로부터 3개월 이내에 노동위원회에 부당해고 구제신청을 할 수 있습니다.',
 ARRAY['부당해고','해고','퇴직','해고예고','해고통보','구제신청']),

('ll_006', 'labor_law', '근로계약서 필수 기재 사항', '근로기준법 제17조',
 '사용자는 근로계약 체결 시 ① 임금의 구성항목·계산방법·지급방법, ② 소정근로시간, ③ 주휴일, ④ 연차유급휴가, ⑤ 취업 장소, ⑥ 업무 내용을 서면에 명시하고 근로자에게 교부해야 합니다. 계약서를 교부하지 않거나 필수 항목을 누락하면 500만 원 이하 벌금에 처합니다.',
 ARRAY['근로계약서','계약서','서면계약','계약 필수항목','교부']),

('ll_007', 'labor_law', '4대보험', '국민건강보험법·국민연금법·고용보험법·산업재해보상보험법',
 '월 60시간 이상 근무하는 외국인 근로자도 건강보험, 국민연금(특례 제외국 제외), 고용보험, 산재보험에 가입해야 합니다. 사용자가 4대보험 가입을 거부하거나 보험료를 근로자에게 전가하는 것은 위법입니다. 미등록 외국인도 산재보험 적용 대상입니다.',
 ARRAY['4대보험','건강보험','국민연금','고용보험','산재보험','보험']),

('ll_008', 'labor_law', '퇴직금', '근로자퇴직급여 보장법 제8조',
 '1년 이상 계속 근무한 근로자(주 15시간 이상)는 퇴직 시 1년당 30일분 이상의 평균임금을 퇴직금으로 받을 수 있습니다. 사용자는 퇴직일로부터 14일 이내에 퇴직금을 지급해야 합니다. 퇴직금 미지급 또는 지연 시 지연 이자(연 20%)가 발생합니다. 외국인 근로자도 동일하게 적용됩니다.',
 ARRAY['퇴직금','퇴직급여','퇴직','퇴직위로금']),

('ll_009', 'labor_law', '외국인 근로자 권리', '외국인근로자 고용 등에 관한 법률·근로기준법 제6조',
 '한국에서 일하는 외국인 근로자(미등록 근로자 포함)는 한국인 근로자와 동일한 노동법 보호를 받습니다. 국적을 이유로 임금 차별을 하는 것은 위법입니다. 임금체불·부당해고·산재 발생 시 외국인도 동일하게 권리를 주장할 수 있습니다. 사용자가 신고하면 추방시키겠다고 협박하는 것은 공갈죄에 해당합니다.',
 ARRAY['외국인','이주노동자','베트남','차별','권리','미등록','비자']),

('ll_010', 'labor_law', '직장 내 괴롭힘 및 폭행', '근로기준법 제76조의2·형법 제257조',
 '직장 내 괴롭힘이란 사용자 또는 근로자가 지위를 이용해 다른 근로자에게 신체적·정신적 고통을 주거나 근무환경을 악화시키는 행위입니다. 피해 근로자는 고용노동부에 신고할 수 있으며, 사용자가 필요한 조치를 취하지 않을 경우 1천만 원 이하 과태료가 부과됩니다.',
 ARRAY['폭행','폭언','괴롭힘','성희롱','직장내괴롭힘','협박']),

('ll_011', 'labor_law', '주휴수당', '근로기준법 제55조',
 '1주 15시간 이상 근무하고 소정근로일을 개근한 근로자에게는 1주에 1일의 유급 주휴일이 주어집니다. 주휴수당은 1일 소정근로시간 × 시급으로 계산합니다. 주 40시간 근무자의 경우 주당 8시간분의 추가 임금이 발생합니다. 알바(아르바이트)를 포함한 모든 근로자에게 적용됩니다.',
 ARRAY['주휴수당','주휴일','유급휴일','알바수당']),

('ll_012', 'labor_law', '임금체불 신고 절차', '근로기준법 제104조',
 '임금체불 발생 시 근로자는 ① 고용노동부 고객상담센터(☎1350)에 전화 상담 → ② 관할 지방고용노동청에 임금체불 진정서 제출 → ③ 노동청 근로감독관 조사 및 체불임금 지급 명령 순서로 진행합니다. 체불임금이 지급되지 않을 경우 사법처리(형사고발)도 가능합니다. 소액체당금 제도를 통해 국가가 대신 지급 후 사용자에게 구상권을 행사하는 제도도 있습니다.',
 ARRAY['신고절차','임금체불 신고','진정서','고용노동청','1350','체당금'])

ON CONFLICT (id) DO UPDATE SET
    content     = EXCLUDED.content,
    keywords    = EXCLUDED.keywords,
    updated_at  = NOW();


-- ── 8-3. knowledge_chunks — visa_info (신규, 향후 search_visa_info tool 용) ──

INSERT INTO knowledge_chunks (id, category, topic, visa_type, content, keywords) VALUES

('vi_e9_001', 'visa_info', 'E-9 비전문취업 근로 조건', 'E-9',
 'E-9(비전문취업) 비자는 고용허가제(EPS)를 통해 입국한 외국인 근로자에게 발급됩니다. 허용 업종: 제조업, 건설업, 농축산업, 어업, 서비스업(일부). 근로시간 제한은 없으나 지정된 사업장에서만 근무 가능합니다. 원칙적으로 사업장 변경이 제한되며, 사용자의 동의 또는 부당한 처우가 있을 경우에만 변경 신청이 가능합니다. 체류 기간은 최초 3년, 연장 1년 10개월(최대 4년 10개월)이며 성실근로자는 재입국 특례가 적용됩니다.',
 ARRAY['E-9','비전문취업','고용허가제','EPS','사업장변경']),

('vi_d2_001', 'visa_info', 'D-2 유학 시간제 취업 조건', 'D-2',
 'D-2(유학) 비자 소지자는 시간제 취업이 가능합니다. 허용 시간: 학기 중 주 20시간, 방학 중 제한 없음. 단, 대학(원)의 사전 허가가 필요하며, 허가된 업종·시간을 초과하면 출입국관리법 위반으로 강제 퇴거 및 벌금 대상이 됩니다. 취업 가능 업종: 학교 측이 허가한 분야. 근로계약서 미작성 상태에서 불규칙 대타 근무를 하다가 시간을 초과하는 경우가 빈번하니 주의가 필요합니다.',
 ARRAY['D-2','유학','시간제취업','주20시간','방학','사전허가']),

('vi_f4_001', 'visa_info', 'F-4 재외동포 취업 조건', 'F-4',
 'F-4(재외동포) 비자는 취업 업종 제한이 없어 자유롭게 취업 활동이 가능합니다. 2026년 2월 12일부로 H-2(방문취업) 비자 신규 발급이 중단되고 F-4로 통합되었습니다. 체류 기간은 최대 3년이며 갱신 가능합니다. 단순노무 업종(청소, 식당보조 등) 일부는 별도 허가가 필요할 수 있습니다. 한국계 중국인(조선족) 및 해외 한국계가 주요 대상입니다.',
 ARRAY['F-4','재외동포','자유취업','조선족','H-2통합']),

('vi_d4_001', 'visa_info', 'D-4 일반연수 시간제 취업 조건', 'D-4',
 'D-4(일반연수) 비자 소지자도 D-2와 동일한 시간제 취업 규정이 적용됩니다. 학기 중 주 20시간, 방학 중 제한 없음. 어학당·연수기관에 재학 중인 경우 해당 기관의 허가를 받아야 합니다. 취업 허가 없이 근무 시 출입국관리법 위반입니다.',
 ARRAY['D-4','일반연수','어학당','시간제취업','주20시간'])

ON CONFLICT (id) DO UPDATE SET
    content     = EXCLUDED.content,
    keywords    = EXCLUDED.keywords,
    updated_at  = NOW();
