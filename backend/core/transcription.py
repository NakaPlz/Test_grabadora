import os
import httpx
import tempfile
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY"),
)

def transcribe_audio(file_path_or_url: str) -> str:
    """
    Transcribes an audio file using OpenAI Whisper API.
    Supports local file paths and remote URLs.
    """
    temp_file_path = None
    try:
        # Check if it's a URL
        if file_path_or_url.startswith("http"):
            print(f"Downloading file from URL for transcription: {file_path_or_url}")
            with httpx.Client() as http_client:
                response = http_client.get(file_path_or_url)
                response.raise_for_status()
                
                # Create a temporary file
                fd, temp_file_path = tempfile.mkstemp(suffix=".wav")
                with os.fdopen(fd, 'wb') as f:
                    f.write(response.content)
            
            target_path = temp_file_path
        else:
            if not os.path.exists(file_path_or_url):
                print(f"File not found: {file_path_or_url}")
                return ""
            target_path = file_path_or_url

        print(f"Transcribing file: {target_path}")
        with open(target_path, "rb") as audio_file:
            transcript = client.audio.transcriptions.create(
                model="whisper-1", 
                file=audio_file, 
                response_format="text"
            )
        
        print(f"Transcription complete (first 50 chars): {transcript[:50]}...")
        return transcript

    except Exception as e:
        print(f"Error during transcription: {e}")
        return ""
    finally:
        # Cleanup temp file if created
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except OSError:
                pass
