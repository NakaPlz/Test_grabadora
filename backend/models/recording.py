from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum, Boolean
from sqlalchemy.orm import relationship
import enum
from database import Base
from datetime import datetime

class RecordingStatus(str, enum.Enum):
    pending = "pending"
    uploaded = "uploaded"
    transcribing = "transcribing"
    completed = "completed"

class Recording(Base):
    __tablename__ = "recordings"

    id = Column(String, primary_key=True, index=True) # UUID
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String, default="Nueva Grabación")
    local_path = Column(String)
    remote_url = Column(String, nullable=True)
    status = Column(Enum(RecordingStatus))
    transcript = Column(String, default="")
    summary = Column(String, default="")
    mind_map_code = Column(String, default="")
    # For tasks, we might need a separate table or just JSON storage. 
    # For MVP simplicity, let's use a simple string logic or separate table later.
    # Storing JSON in String for SQLite simplicity
    tasks_json = Column(String, default="[]") 
    is_favorite = Column(Boolean, default=False)
    is_deleted = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("models.user.User", back_populates="recordings")
    collections = relationship("models.collection.Collection", secondary="collection_recordings", back_populates="recordings")

# Update User model to include recordings relationship (will do in next step)
