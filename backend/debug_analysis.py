from core.analysis import analyze_transcript
import os
from dotenv import load_dotenv

load_dotenv()

print(f"API Key present: {'Yes' if os.environ.get('OPENAI_API_KEY') else 'No'}")

sample_text = """
Hola, esto es una prueba de la grabadora.
La idea es que mañana tenemos que reunirnos con el cliente para definir los colores de la app.
También hay que arreglar el bug del login que no permite usuarios nuevos.
Y por último, comprar café para la oficina porque se acabó.
Eso es todo, cambio y fuera.
"""

print(f"Testing analysis with text ({len(sample_text)} chars)...")
result = analyze_transcript(sample_text)

print("\n--- RESULT ---")
print(result)
