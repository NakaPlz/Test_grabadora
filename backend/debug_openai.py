from core.transcription import transcribe_audio
import os

print("--- DEBUG OPENAI CONNECTION ---")
api_key = os.environ.get("OPENAI_API_KEY")
print(f"API KEY LOADING: {'SUCCESS' if api_key else 'FAILED'}")
if api_key:
    print(f"Key starts with: {api_key[:5]}...")

# Create a dummy file
dummy_path = "debug_audio.txt"
with open(dummy_path, "w") as f:
    f.write("This is not audio")

print("\n--- ATTEMPTING TRANSCRIPTION (Should fail gracefully on non-audio) ---")
try:
    result = transcribe_audio(dummy_path)
    print(f"Result: {result}")
except Exception as e:
    print(f"EXCEPTION: {e}")

print("\n--- END DEBUG ---")
