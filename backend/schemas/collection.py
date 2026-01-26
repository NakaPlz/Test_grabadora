from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from schemas.recording import Recording

class CollectionBase(BaseModel):
    name: str

class CollectionCreate(CollectionBase):
    pass

class CollectionUpdate(CollectionBase):
    pass

class Collection(CollectionBase):
    id: int
    user_id: int
    created_at: datetime
    recordings: List[Recording] = []

    class Config:
        from_attributes = True
