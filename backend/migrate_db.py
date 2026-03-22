from database import engine
from sqlalchemy import text

def run_migration():
    print("Iniciando migración de base de datos...")
    with engine.connect() as conn:
        try:
            # SQL for PostgreSQL (which the user is using on VPS)
            # This is safe to run even if the column exists due to IF NOT EXISTS (Postgres 9.6+)
            conn.execute(text("ALTER TABLE recordings ADD COLUMN IF NOT EXISTS title VARCHAR DEFAULT 'Nueva Grabación'"))
            conn.commit()
            print("Migración completada: Columna 'title' añadida satisfactoriamente.")
        except Exception as e:
            # Fallback for SQLite or older Postgres if IF NOT EXISTS fails
            print(f"Intentando fallback para otros motores de BD...")
            try:
                conn.execute(text("ALTER TABLE recordings ADD COLUMN title VARCHAR DEFAULT 'Nueva Grabación'"))
                conn.commit()
                print("Migración completada (fallback).")
            except Exception as e2:
                print(f"La columna ya existe o hubo un error: {e2}")

if __name__ == "__main__":
    run_migration()
