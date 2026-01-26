from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

# Association table
collection_recordings = Table(
    "collection_recordings",
    Base.metadata,
    Column("collection_id", Integer, ForeignKey("collections.id")),
    Column("recording_id", String, ForeignKey("recordings.id"))
)

class Collection(Base):
    __tablename__ = "collections"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("models.user.User", back_populates="collections")
    recordings = relationship("models.recording.Recording", secondary=collection_recordings, back_populates="collections")
