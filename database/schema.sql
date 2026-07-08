CREATE TABLE IF NOT EXISTS users (
    id                   SERIAL PRIMARY KEY,
    auth_provider        TEXT        NOT NULL,          -- google, apple
    auth_provider_id     TEXT        NOT NULL UNIQUE,   -- OAuth ID
    email                TEXT,
    nickname             TEXT,
    preferred_language   TEXT        DEFAULT 'ko',
    nationality          TEXT,
    visa_type            TEXT,
    residence            TEXT,
    created_at           TIMESTAMPTZ DEFAULT NOW()
);
________________________________________
CREATE TABLE IF NOT EXISTS chat_sessions (
    id               SERIAL PRIMARY KEY,
    user_id          INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title            TEXT,
    session_type     TEXT        DEFAULT 'normal',      -- normal, contract
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);
________________________________________
CREATE TABLE IF NOT EXISTS uploaded_files (
    id               SERIAL PRIMARY KEY,
    user_id          INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name        TEXT        NOT NULL,
    file_url         TEXT        NOT NULL,
    file_type        TEXT,
    created_at       TIMESTAMPTZ DEFAULT NOW()
);
________________________________________
CREATE TABLE IF NOT EXISTS chat_messages (
    id               SERIAL PRIMARY KEY,
    session_id       INTEGER     NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role             TEXT        NOT NULL,          -- user, assistant
    message_type     TEXT        DEFAULT 'text',    -- text, image
    content          TEXT,
    file_id          INTEGER     REFERENCES uploaded_files(id) ON DELETE SET NULL,
    tool_result      JSONB,
    created_at       TIMESTAMPTZ DEFAULT NOW()
);
________________________________________
CREATE TABLE IF NOT EXISTS contract_analyses (
    id               SERIAL PRIMARY KEY,
    user_id          INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_id          INTEGER     NOT NULL REFERENCES uploaded_files(id) ON DELETE CASCADE,

    model_name       TEXT        DEFAULT 'gemini',

    analysis_result  JSONB       NOT NULL,
    risk_level       TEXT,
    summary          TEXT,

    created_at       TIMESTAMPTZ DEFAULT NOW()
);
________________________________________
CREATE TABLE IF NOT EXISTS institutions (
    id                    SERIAL PRIMARY KEY,

    name                  TEXT        NOT NULL,
    category              TEXT        NOT NULL,

    address               TEXT,
    latitude              DOUBLE PRECISION,
    longitude             DOUBLE PRECISION,

    phone                 TEXT,
    opening_hours         TEXT,

    supported_languages   JSONB,
    services              JSONB,

    reservation_url       TEXT,

    created_at            TIMESTAMPTZ DEFAULT NOW(),
    updated_at            TIMESTAMPTZ DEFAULT NOW()
);
________________________________________
CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id               SERIAL PRIMARY KEY,

    category         TEXT        NOT NULL,     -- labor, visa, institution
    title            TEXT,
    source           TEXT,

    content          TEXT        NOT NULL,

    embedding        VECTOR(768),             -- BGE-M3 기준 (차원은 모델에 맞게 수정)

    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);
