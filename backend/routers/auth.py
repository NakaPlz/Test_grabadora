from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from database import get_db
from crud import user as crud_user
from schemas import user as schemas_user
from core.security import verify_password, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES

router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")

import secrets
from fastapi import BackgroundTasks
from core.email import send_verification_email

@router.post("/signup", response_model=schemas_user.User)
async def create_user(
    user: schemas_user.UserCreate, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    # Normalize email to lowercase
    user.email = user.email.lower()
    db_user = crud_user.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    token = secrets.token_urlsafe(32)
    new_user = crud_user.create_user(db=db, user=user, verification_token=token)
    
    background_tasks.add_task(send_verification_email, new_user.email, token)
    
    return new_user

@router.get("/verify")
def verify_email(token: str, db: Session = Depends(get_db)):
    # Find user by verification token (needs a new CRUD or direct query)
    # Since we didn't add get_user_by_token, we can do a direct query here or add it to CRUD.
    # Direct query for simplicity as it's specific to this flow.
    from models.user import User
    user = db.query(User).filter(User.verification_token == token).first()
    
    if not user:
        raise HTTPException(status_code=400, detail="Invalid verification token")
    
    if user.is_verified:
        return {"message": "Email already verified"}
        
    user.is_verified = True
    user.verification_token = None
    db.commit()
    
    return {"message": "Email verified successfully"}

@router.post("/token", response_model=schemas_user.Token)
async def login_for_access_token(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    # Normalize email to lowercase
    email = form_data.username.lower()
    user = crud_user.get_user_by_email(db, email=email)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_verified:
        raise HTTPException(
            status_code=400,
            detail="Email not verified. Please check your inbox.",
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        from jose import jwt, JWTError
        from core.security import SECRET_KEY, ALGORITHM
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = crud_user.get_user_by_email(db, email=username)
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_user(current_user: schemas_user.User = Depends(get_current_user)):
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user
