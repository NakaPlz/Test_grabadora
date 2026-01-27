from sqlalchemy.orm import Session
from models.user import User
from schemas.user import UserCreate
from core.security import get_password_hash

def get_user(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def create_user(db: Session, user: UserCreate, verification_token: str = None):
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email, 
        hashed_password=hashed_password,
        verification_token=verification_token,
        is_verified=False if verification_token else True
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user
