from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="AI Recorder Bridge API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi.staticfiles import StaticFiles
import os

# Create uploads directory if not exists
os.makedirs("uploads", exist_ok=True)
# Mount uploads directory to /uploads path
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

from database import engine, Base
from routers import auth
from models import user, recording, collection

# Create Tables
Base.metadata.create_all(bind=engine)

# Run Migrations (Check for new columns)
from migrate_db import run_migration
run_migration()

app.include_router(auth.router)
from routers import recordings, collections
app.include_router(recordings.router, prefix="/recordings")
app.include_router(collections.router)

@app.get("/")
async def root():
    return {"message": "AI Recorder Bridge API is running"}

@app.get("/sanity")
async def sanity_check():
    return {"sanity": "pass"}

@app.get("/health")
async def health_check():
    return {"status": "ok"}

@app.on_event("startup")
async def startup_event():
    print("MAPPING ROUTES:")
    for route in app.routes:
        print(f"PATH: {route.path} NAME: {route.name}")
