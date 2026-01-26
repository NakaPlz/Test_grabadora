from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
import os

from database import get_db
from models.user import User
from schemas import recording as schemas_recording
from crud import recording as crud_recording
from routers.auth import get_current_active_user

router = APIRouter(tags=["recordings"])

@router.get("/test")
async def test_endpoint():
    return {"message": "Router works"}

@router.get("/", response_model=List[schemas_recording.Recording])
async def read_recordings(
    skip: int = 0, 
    limit: int = 100, 
    is_deleted: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    recordings = crud_recording.get_recordings_by_user(db, user_id=current_user.id, skip=skip, limit=limit, is_deleted=is_deleted)
    return recordings

@router.post("/", response_model=schemas_recording.Recording)
async def create_recording(
    recording: schemas_recording.RecordingCreate, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    return crud_recording.create_user_recording(db=db, recording=recording, user_id=current_user.id)

@router.get("/{recording_id}", response_model=schemas_recording.Recording)
async def read_recording(
    recording_id: str, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    recording = crud_recording.get_recording(db, recording_id=recording_id)
    if recording is None:
        raise HTTPException(status_code=404, detail="Recording not found")
    if recording.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this recording")
    return recording

@router.delete("/{recording_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recording(
    recording_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    recording = crud_recording.get_recording(db, recording_id=recording_id)
    if recording is None:
        raise HTTPException(status_code=404, detail="Recording not found")
    if recording.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this recording")
    
    # Soft Delete
    crud_recording.update_recording(db, recording_id, schemas_recording.RecordingUpdate(is_deleted=True))
    return None

@router.post("/{recording_id}/restore", response_model=schemas_recording.Recording)
async def restore_recording(
    recording_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    recording = crud_recording.get_recording(db, recording_id=recording_id)
    if not recording:
         raise HTTPException(status_code=404, detail="Recording not found")
    if recording.user_id != current_user.id:
         raise HTTPException(status_code=403, detail="Not authorized")
    
    updated = crud_recording.update_recording(db, recording_id, schemas_recording.RecordingUpdate(is_deleted=False))
    return updated

@router.delete("/{recording_id}/permanent", status_code=status.HTTP_204_NO_CONTENT)
async def permanent_delete_recording(
    recording_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    recording = crud_recording.get_recording(db, recording_id=recording_id)
    if recording is None:
        raise HTTPException(status_code=404, detail="Recording not found")
    if recording.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this recording")
    
    # Delete physical file if exists
    if recording.remote_url and os.path.exists(recording.remote_url):
        try:
            os.remove(recording.remote_url)
        except OSError:
            pass 
            
    crud_recording.delete_recording(db, recording_id)
    return None

@router.patch("/{recording_id}", response_model=schemas_recording.Recording)
async def update_recording(
    recording_id: str,
    recording_update: schemas_recording.RecordingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    recording = crud_recording.get_recording(db, recording_id=recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")
    if recording.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    updated = crud_recording.update_recording(db, recording_id, recording_update)
    return updated

@router.post("/{recording_id}/upload", response_model=schemas_recording.Recording)
async def upload_audio_file(
    recording_id: str,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    recording = crud_recording.get_recording(db, recording_id=recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")
    if recording.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    # Ensure uploads directory exists
    os.makedirs("uploads", exist_ok=True)
    
    file_location = f"uploads/{recording_id}_{file.filename}"
    with open(file_location, "wb+") as file_object:
        file_object.write(file.file.read())
    
    # Update recording with file path/url
    updated_recording = crud_recording.update_recording(
        db, 
        recording_id, 
        schemas_recording.RecordingUpdate(remote_url=file_location, status=schemas_recording.RecordingStatus.uploaded)
    )

    return updated_recording

@router.post("/{recording_id}/transcribe", response_model=schemas_recording.Recording)
async def transcribe_recording(
    recording_id: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    recording = crud_recording.get_recording(db, recording_id=recording_id)
    if not recording:
        raise HTTPException(status_code=404, detail="Recording not found")
    if recording.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Check if we have a file
    if not recording.remote_url:
        raise HTTPException(status_code=400, detail="No audio file uploaded for this recording")

    # Update status to transcribing
    recording = crud_recording.update_recording(
        db, 
        recording_id, 
        schemas_recording.RecordingUpdate(status=schemas_recording.RecordingStatus.transcribing)
    )

    # Trigger Background Transcription
    background_tasks.add_task(process_transcription, recording.remote_url, recording_id)

    return recording

def process_transcription(file_path: str, rec_id: str):
    print(f"[BACKGROUND] Starting transcription for {file_path} (ID: {rec_id})")
    
    # Verify file exists
    if not os.path.exists(file_path):
        print(f"[BACKGROUND] ERROR: File not found at {file_path}")
        return

    try:
        from core.transcription import transcribe_audio
        from core.analysis import analyze_transcript # Import analysis service
        import json
        
        # 1. Transcribe
        text = transcribe_audio(file_path)
        print(f"[BACKGROUND] Transcription result length: {len(text)}")
        
        # 2. Analyze (Summary + Tasks + Mind Map)
        analysis_result = analyze_transcript(text)
        summary_text = analysis_result.get("summary", "")
        tasks_list = analysis_result.get("tasks", [])
        mind_map_code = analysis_result.get("mind_map", "")
        tasks_json_str = json.dumps(tasks_list)
        
        print(f"[BACKGROUND] Analysis complete. Summary len: {len(summary_text)}, Tasks: {len(tasks_list)}, MindMap len: {len(mind_map_code)}")
        
        # 3. Update DB
        from database import SessionLocal
        db = SessionLocal()
        try:
             crud_recording.update_recording(
                db, 
                rec_id, 
                schemas_recording.RecordingUpdate(
                    status=schemas_recording.RecordingStatus.completed,
                    transcript=text,
                    summary=summary_text,
                    tasks_json=tasks_json_str,
                    mind_map_code=mind_map_code
                )
             )
             print(f"[BACKGROUND] Database updated for {rec_id}")
        except Exception as db_exc:
            print(f"[BACKGROUND] DB ERROR: {db_exc}")
        finally:
            db.close()
            
    except Exception as e:
        print(f"[BACKGROUND] CRITICAL ERROR during transcription process: {e}")
