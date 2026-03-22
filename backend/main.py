from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

# Force load all environment variables from .env file immediately
load_dotenv()

app = FastAPI(title="Hilo API")

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

# Mount uploads directory to /uploads path
os.makedirs("uploads", exist_ok=True)
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

@app.get("/env-debug")
async def env_debug():
    import os
    return {
        "SUPABASE_URL_EXISTS": "SUPABASE_URL" in os.environ,
        "SUPABASE_KEY_EXISTS": "SUPABASE_KEY" in os.environ,
        "URL_STARTS_WITH_HTTP": str(os.environ.get("SUPABASE_URL")).startswith("http"),
        "KEYS_IN_ENV": list(os.environ.keys())
    }

@app.get("/test-dns")
async def test_dns():
    import socket
    import urllib.request
    import os
    import reprlib

    url_env = reprlib.repr(os.environ.get("SUPABASE_URL", ""))
    url_stripped = reprlib.repr(os.environ.get("SUPABASE_URL", "").strip())
    
    # Isolate domain
    raw = os.environ.get("SUPABASE_URL", "").strip()
    if raw.startswith("http"):
        domain = raw.split("://")[-1].split("/")[0]
    else:
        domain = raw

    try:
        ip = socket.gethostbyname(domain)
        dns_success = True
    except Exception as e:
        ip = str(e)
        dns_success = False

    return {
        "env_raw": url_env,
        "env_stripped": url_stripped,
        "domain_parsed": reprlib.repr(domain),
        "resolved_ip": ip,
        "dns_success": dns_success
    }

@app.on_event("startup")
async def startup_event():
    print("MAPPING ROUTES:")
    for route in app.routes:
        print(f"PATH: {route.path} NAME: {route.name}")
