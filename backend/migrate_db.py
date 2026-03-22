from database import engine
from sqlalchemy import text, inspect

def run_migration():
    print("Iniciando migración de base de datos...")
    inspector = inspect(engine)
    
    # Check if 'recordings' table exists
    if not inspector.has_table('recordings'):
        print("La tabla 'recordings' no existe. Ejecutando creación inicial...")
        return
        
    columns = [col['name'] for col in inspector.get_columns('recordings')]
    
    with engine.connect() as conn:
        with conn.begin():
            if 'title' not in columns:
                print("Añadiendo columna 'title' a la tabla 'recordings'...")
                try:
                    conn.execute(text("ALTER TABLE recordings ADD COLUMN title VARCHAR DEFAULT 'Nueva Grabación'"))
                    print("Columna 'title' añadida satisfactoriamente.")
                except Exception as e:
                     print(f"Error al añadir columna: {e}")
            else:
                print("La columna 'title' ya existe en la tabla 'recordings'.")
                
if __name__ == "__main__":
    run_migration()
