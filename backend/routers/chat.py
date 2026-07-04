from fastapi import APIRouter, HTTPException
from schemas.chat import ChatRequest, ChatResponse
from agents.main_agent import run_agent

router = APIRouter()


@router.post("", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    try:
        return await run_agent(request)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))
