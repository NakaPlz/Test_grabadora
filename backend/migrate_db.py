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
    
    # Check if 'users' table exists and add plan_type
    if inspector.has_table('users'):
        user_columns = [col['name'] for col in inspector.get_columns('users')]
        with engine.connect() as conn:
            with conn.begin():
                if 'plan_type' not in user_columns:
                    print("Añadiendo columna 'plan_type' a la tabla 'users'...")
                    try:
                        conn.execute(text("ALTER TABLE users ADD COLUMN plan_type VARCHAR DEFAULT 'free'"))
                        print("Columna 'plan_type' añadida satisfactoriamente.")
                    except Exception as e:
                         print(f"Error al añadir columna plan_type: {e}")
                else:
                    print("La columna 'plan_type' ya existe en la tabla 'users'.")
                
if __name__ == "__main__":
    run_migration()
