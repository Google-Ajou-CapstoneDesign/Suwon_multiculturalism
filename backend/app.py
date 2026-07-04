from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import chat

load_dotenv()

app = FastAPI(title="Co-Local API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat.router, prefix="/chat", tags=["chat"])


@app.get("/")
def root():
    return {"message": "Co-Local API is running", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "ok"}
