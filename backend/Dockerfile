FROM python:3.11-slim

WORKDIR /app

# chromadb(hnswlib), Pillow 빌드에 필요한 시스템 패키지
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

# 의존성 먼저 복사 (레이어 캐시 최적화)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# HF Spaces /data 디렉토리: Space 재시작 간 유지되는 writable 공간
# → ChromaDB 재임베딩 비용 절감 (콜드스타트 시 컬렉션 비어 있을 때만 시딩)
ENV VECTOR_DB_PATH=/data/chromadb

# HF Spaces Docker SDK 기본 포트
EXPOSE 7860

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860"]
