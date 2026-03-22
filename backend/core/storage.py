import os
import uuid
import urllib.request
import urllib.parse
import urllib.error
import re

# Initialize Supabase URL and Key
raw_url = os.environ.get("SUPABASE_URL", "").strip()
# Bulletproof sanitization in case the user copy-pasted "SUPABASE_URL=" or duplicates into the env var field
match = re.search(r"https://[a-zA-Z0-9-]+\.supabase\.co", raw_url)
supabase_url = match.group(0) if match else raw_url

supabase_key = os.environ.get("SUPABASE_KEY", "").strip()
# Remove accidental KEY= prefixes if copied incorrectly
if "SUPABASE_KEY=" in supabase_key:
    supabase_key = supabase_key.replace("SUPABASE_KEY=", "").strip()

BUCKET_NAME = "recordings"

def upload_file_to_supabase(recording_id: str, file) -> str:
    """
    Uploads a file to Supabase Storage using native urllib (bypassing httpx DNS bugs)
    and returns its public URL.
    """
    if not supabase_url or not supabase_key:
        raise ValueError("Supabase URL or KEY is missing.")

    ext = file.filename.split('.')[-1] if '.' in file.filename else 'wav'
    file_name = f"{recording_id}_{uuid.uuid4().hex}.{ext}"
    file_bytes = file.file.read()
    
    encoded_file_name = urllib.parse.quote(file_name)
    upload_url = f"{supabase_url}/storage/v1/object/{BUCKET_NAME}/{encoded_file_name}"
    
    req = urllib.request.Request(upload_url, data=file_bytes, method="POST")
    req.add_header("Authorization", f"Bearer {supabase_key}")
    req.add_header("Content-Type", "audio/wav")
    
    try:
        with urllib.request.urlopen(req) as response:
            if response.status >= 400:
                raise Exception(f"Upload failed: {response.read()}")
    except urllib.error.HTTPError as e:
        raise Exception(f"Upload HTTPError: {e.code} - {e.read().decode('utf-8')}")
    except urllib.error.URLError as e:
        raise Exception(f"Upload URLError: {e.reason}")
    
    public_url = f"{supabase_url}/storage/v1/object/public/{BUCKET_NAME}/{encoded_file_name}"
    return public_url

def delete_file_from_supabase(remote_url: str) -> bool:
    """
    Deletes a file from Supabase Storage given its public URL using native urllib.
    """
    if not supabase_url or not supabase_key or not remote_url:
        return False
        
    try:
        if BUCKET_NAME in remote_url:
            parts = remote_url.split(f"/{BUCKET_NAME}/")
            if len(parts) > 1:
                filename = urllib.parse.quote(parts[1])
                delete_url = f"{supabase_url}/storage/v1/object/{BUCKET_NAME}/{filename}"
                
                req = urllib.request.Request(delete_url, method="DELETE")
                req.add_header("Authorization", f"Bearer {supabase_key}")
                
                with urllib.request.urlopen(req) as response:
                    return response.status < 400
    except Exception as e:
        print(f"Failed to delete file from Supabase storage: {e}")
        
    return False

