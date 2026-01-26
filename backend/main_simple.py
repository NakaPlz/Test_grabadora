from fastapi import FastAPI
from routers import recordings

app = FastAPI()

app.include_router(recordings.router, prefix="/recordings")

@app.get("/sanity")
def sanity():
    return {"sanity": "simple pass"}
