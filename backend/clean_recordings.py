import os
import sys
from sqlalchemy.orm import Session
from database import SessionLocal, engine
from models.recording import Recording
from models.user import User

def wipe_data():
    db = SessionLocal()
    try:
        print("WARNING: This will delete ALL recordings from the database.")
        print("Are you sure? (Type 'yes' to confirm)")
        confirm = input("> ")
        if confirm != "yes":
            print("Aborted.")
            return

        num_deleted = db.query(Recording).delete()
        db.commit()
        print(f"Deleted {num_deleted} recordings.")
        
        # Optional: delete files
        folder = "uploads"
        if os.path.exists(folder):
            print("Deleting files in uploads/...")
            for filename in os.listdir(folder):
                file_path = os.path.join(folder, filename)
                try:
                    if os.path.isfile(file_path):
                        os.unlink(file_path)
                except Exception as e:
                    print(f"Error deleting {file_path}: {e}")
            print("Files deleted.")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    wipe_data()
