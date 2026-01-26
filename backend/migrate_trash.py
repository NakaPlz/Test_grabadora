import sqlite3
import os

db_path = "sql_app.db"

if not os.path.exists(db_path):
    print(f"Database file {db_path} not found. Nothing to migrate.")
    exit(0)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    print("Attempting to add 'is_deleted' column to 'recordings' table...")
    cursor.execute("ALTER TABLE recordings ADD COLUMN is_deleted BOOLEAN DEFAULT 0")
    conn.commit()
    print("Migration successful: 'is_deleted' column added.")
except Exception as e:
    if "duplicate column name" in str(e):
         print("Column 'is_deleted' already exists.")
    else:
        print(f"Migration failed: {e}")

conn.close()
