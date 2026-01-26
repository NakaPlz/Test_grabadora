import os
import json
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY"),
)

def analyze_transcript(transcript_text: str) -> dict:
    """
    Analyzes the transcript to generate a summary and a list of action items.
    Returns a dict with 'summary' (str) and 'tasks' (list of str).
    """
    if not transcript_text or len(transcript_text) < 10:
        return {"summary": "No hay suficiente texto para analizar.", "tasks": []}

    print("Analyzing transcript...")
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini", # Used mini for speed and cost
            response_format={"type": "json_object"},
            messages=[
                {
                    "role": "system", 
                    "content": """You are an expert secretary and project manager. 
                    Analyze the provided transcription text.
                    1. Create a concise "executive summary" (in Spanish).
                    2. Extract a list of "action items" or "tasks" (in Spanish).
                    3. Create a "mind map" using Mermaid.js syntax (graph TD or mindmap).
                       - Keep it simple and hierarchical.
                       - Use strictly valid Mermaid syntax.
                       - Return the raw Mermaid code string in the "mind_map" field.
                    
                    Return ONLY a JSON object with this structure:
                    {
                        "summary": "The executive summary text...",
                        "tasks": ["Task 1", "Task 2", ...],
                        "mind_map": "graph TD; A[Concept] --> B[Detail]; ..."
                    }
                    """
                },
                {"role": "user", "content": transcript_text}
            ]
        )
        
        content = response.choices[0].message.content
        result = json.loads(content)
        
        # Ensure keys exist
        if "summary" not in result:
            result["summary"] = "Resumen no generado."
        if "tasks" not in result:
            result["tasks"] = []
        if "mind_map" not in result:
            result["mind_map"] = ""
            
        print("Analysis complete.")
        return result

    except Exception as e:
        print(f"Error during analysis: {e}")
        return {"summary": "Error al generar resumen.", "tasks": []}
