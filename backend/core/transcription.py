import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY"),
)

def transcribe_audio(file_path: str) -> str:
    """
    Transcribes an audio file using OpenAI Whisper API.
    """
    try:
        if not os.path.exists(file_path):
            print(f"File not found: {file_path}")
            return ""

        print(f"Transcribing file: {file_path}")
        audio_file = open(file_path, "rb")
        
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
