import os
from supabase import create_client, Client
from fastapi import UploadFile
import uuid

# Initialize Supabase Client
supabase_url = os.environ.get("SUPABASE_URL", "").strip()
supabase_key = os.environ.get("SUPABASE_KEY", "").strip()

if supabase_url and supabase_key:
    supabase: Client = create_client(supabase_url, supabase_key)
else:
    # Handle gracefully if missing, though it shouldn't happen in prod now
    print("WARNING: SUPABASE_URL or SUPABASE_KEY is missing. Storage will fail.")
    supabase = None

BUCKET_NAME = "recordings"

def upload_file_to_supabase(recording_id: str, file: UploadFile) -> str:
    """
    Uploads a file to Supabase Storage and returns the public URL.
    """
    if not supabase:
        raise ValueError("Supabase client is not initialized.")

    # Create a unique filename to prevent collisions, but keep the original extension
    ext = file.filename.split('.')[-1] if '.' in file.filename else 'wav'
    file_name = f"{recording_id}_{uuid.uuid4().hex}.{ext}"
    
    # Read file content
    file_bytes = file.file.read()
    
    # Upload to Supabase Storage
    res = supabase.storage.from_(BUCKET_NAME).upload(
        file=file_bytes,
        path=file_name,
        file_options={"content-type": "audio/wav"}
    )
    
    # Get the public URL for the file so the frontend can play it directly
    public_url = supabase.storage.from_(BUCKET_NAME).get_public_url(file_name)
    
    # The return value of get_public_url is sometimes wrapped in an object or just string
    # Based on supabase-py v2.3+, get_public_url returns a string directly
    return public_url

def delete_file_from_supabase(remote_url: str) -> bool:
    """
    Deletes a file from Supabase Storage given its public URL.
    """
    if not supabase or not remote_url:
        return False
        
    try:
        # The remote_url looks like: https://[project_ref].supabase.co/storage/v1/object/public/recordings/[filename]
        # We need to extract just the [filename] part
        if BUCKET_NAME in remote_url:
            parts = remote_url.split(f"/{BUCKET_NAME}/")
            if len(parts) > 1:
                filename = parts[1]
                supabase.storage.from_(BUCKET_NAME).remove([filename])
                return True
    except Exception as e:
        print(f"Failed to delete file from Supabase storage: {e}")
        
    return False
