from sqlalchemy.orm import Session
from models.recording import Recording, RecordingStatus
from schemas.recording import RecordingCreate, RecordingUpdate
import uuid

def get_recording(db: Session, recording_id: str):
    return db.query(Recording).filter(Recording.id == recording_id).first()

def get_recordings_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100, is_deleted: bool = False):
    return db.query(Recording).filter(Recording.user_id == user_id, Recording.is_deleted == is_deleted).offset(skip).limit(limit).all()

def create_user_recording(db: Session, recording: RecordingCreate, user_id: int):
    # Generate UUID for the recording ID
    db_recording = Recording(
        id=str(uuid.uuid4()),
        **recording.model_dump(),
        user_id=user_id
    )
    db.add(db_recording)
    db.commit()
    db.refresh(db_recording)
    return db_recording

def update_recording(db: Session, recording_id: str, recording_update: RecordingUpdate):
    db_recording = get_recording(db, recording_id)
    if not db_recording:
        return None
    
    update_data = recording_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_recording, key, value)
    
    db.add(db_recording)
    db.commit()
    db.refresh(db_recording)
    return db_recording

def delete_recording(db: Session, recording_id: str):
    db_recording = get_recording(db, recording_id)
    if not db_recording:
        return False
    
    db.delete(db_recording)
    db.commit()
    return True
