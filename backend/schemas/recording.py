from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from models.recording import RecordingStatus

class RecordingBase(BaseModel):
    local_path: str
    status: RecordingStatus = RecordingStatus.pending

class RecordingCreate(RecordingBase):
    title: Optional[str] = "Nueva Grabación"
    pass

class RecordingUpdate(BaseModel):
    title: Optional[str] = None
    remote_url: Optional[str] = None
    status: Optional[RecordingStatus] = None
    transcript: Optional[str] = None
    summary: Optional[str] = None
    mind_map_code: Optional[str] = None
    tasks_json: Optional[str] = None
    is_favorite: Optional[bool] = None
    is_deleted: Optional[bool] = None

class Recording(RecordingBase):
    id: str
    user_id: int
    title: str = "Nueva Grabación"
    remote_url: Optional[str] = None
    transcript: Optional[str] = None
    summary: Optional[str] = None
    mind_map_code: Optional[str] = None
    tasks_json: Optional[str] = None
    is_favorite: bool = False
    is_deleted: bool = False
    created_at: datetime

    class Config:
        from_attributes = True
