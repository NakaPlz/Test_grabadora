import os
import json
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY"),
)

def generate_summary(transcript_text: str) -> str:
    if not transcript_text or len(transcript_text) < 10:
        return "No hay suficiente texto para analizar."
    
    print("Generating summary...")
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system", 
                    "content": "You are an expert secretary. Create a concise executive summary in Spanish for the provided transcription text."
                },
                {"role": "user", "content": transcript_text}
            ]
        )
        return response.choices[0].message.content or "Resumen no generado."
    except Exception as e:
        print(f"Error during summary generation: {e}")
        return "Error al generar resumen."

def generate_tasks(transcript_text: str) -> list:
    if not transcript_text or len(transcript_text) < 10:
        return []
        
    print("Generating tasks...")
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            response_format={"type": "json_object"},
            messages=[
                {
                    "role": "system", 
                    "content": "You are a project manager. Extract a list of action items or tasks from the transcription in Spanish. Return ONLY a JSON object with this structure: {\"tasks\": [\"Task 1\", \"Task 2\"]}"
                },
                {"role": "user", "content": transcript_text}
            ]
        )
        content = response.choices[0].message.content
        if content:
             result = json.loads(content)
             return result.get("tasks", [])
        return []
    except Exception as e:
        print(f"Error during tasks generation: {e}")
        return []

def generate_mind_map(transcript_text: str) -> str:
    if not transcript_text or len(transcript_text) < 10:
        return ""
        
    print("Generating mind map...")
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system", 
                    "content": "You are an expert analyst. Create a mind map using valid Mermaid.js syntax (graph TD or mindmap) based on the transcription text. Return ONLY the raw Mermaid code string without Markdown code blocks (` ``` `) or any other explanation."
                },
                {"role": "user", "content": transcript_text}
            ]
        )
        content = response.choices[0].message.content
        if not content:
            return ""
        
        # Strip markdown format if present
        content = content.strip()
        if content.startswith("```"):
             lines = content.split("\n")
             if len(lines) > 2:
                 content = "\n".join(lines[1:-1])
        return content.strip()
    except Exception as e:
        print(f"Error during mind map generation: {e}")
        return ""
