from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models.user import User
from models.collection import Collection
from models.recording import Recording
from schemas import collection as collection_schema
from core.security import verify_password # If needed, else remove
# get_current_user is in routers.auth
from routers.auth import get_current_user

router = APIRouter(
    prefix="/collections",
    tags=["collections"],
    responses={404: {"description": "Not found"}},
)

@router.post("/", response_model=collection_schema.Collection)
def create_collection(
    collection: collection_schema.CollectionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db_collection = Collection(name=collection.name, user_id=current_user.id)
    db.add(db_collection)
    db.commit()
    db.refresh(db_collection)
    return db_collection

@router.get("/", response_model=List[collection_schema.Collection])
def read_collections(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items = db.query(Collection).filter(Collection.user_id == current_user.id).offset(skip).limit(limit).all()
    return items

@router.get("/{collection_id}", response_model=collection_schema.Collection)
def read_collection(
    collection_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db_collection = db.query(Collection).filter(Collection.id == collection_id, Collection.user_id == current_user.id).first()
    if db_collection is None:
        raise HTTPException(status_code=404, detail="Collection not found")
    return db_collection

@router.delete("/{collection_id}", response_model=collection_schema.Collection)
def delete_collection(
    collection_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db_collection = db.query(Collection).filter(Collection.id == collection_id, Collection.user_id == current_user.id).first()
    if db_collection is None:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    db.delete(db_collection)
    db.commit()
    return db_collection

@router.post("/{collection_id}/recordings/{recording_id}", response_model=collection_schema.Collection)
def add_recording_to_collection(
    collection_id: int,
    recording_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db_collection = db.query(Collection).filter(Collection.id == collection_id, Collection.user_id == current_user.id).first()
    if db_collection is None:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    db_recording = db.query(Recording).filter(Recording.id == recording_id, Recording.user_id == current_user.id).first()
    if db_recording is None:
        raise HTTPException(status_code=404, detail="Recording not found")
        
    if db_recording not in db_collection.recordings:
        db_collection.recordings.append(db_recording)
        db.commit()
        db.refresh(db_collection)
        
    return db_collection

@router.delete("/{collection_id}/recordings/{recording_id}", response_model=collection_schema.Collection)
def remove_recording_from_collection(
    collection_id: int,
    recording_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db_collection = db.query(Collection).filter(Collection.id == collection_id, Collection.user_id == current_user.id).first()
    if db_collection is None:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    db_recording = db.query(Recording).filter(Recording.id == recording_id, Recording.user_id == current_user.id).first()
    if db_recording is None:
        raise HTTPException(status_code=404, detail="Recording not found")

    if db_recording in db_collection.recordings:
        db_collection.recordings.remove(db_recording)
        db.commit()
        db.refresh(db_collection)
        
    return db_collection
