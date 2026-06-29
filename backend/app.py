from fastapi import FastAPI
from routers import chat, contract, map, user

app = FastAPI(title="Co-Local API")

app.include_router(chat.router, prefix="/chat", tags=["chat"])
app.include_router(contract.router, prefix="/contract", tags=["contract"])
app.include_router(map.router, prefix="/map", tags=["map"])
app.include_router(user.router, prefix="/user", tags=["user"])

@app.get("/")
def root():
    return {"message": "Co-Local API is running"}
