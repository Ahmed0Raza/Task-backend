from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session
from app.middleware.auth import get_db
from app.tables.user import User
from app.schemas.auth import SignupModel, LoginModel
from passlib.hash import bcrypt
from jose import jwt
from app.config.settings import settings  

def signup(data: SignupModel, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already exists")

    hashed_password = bcrypt.hash(data.password)

    new_user = User(
        first_name=data.firstName,
        last_name=data.lastName,
        email=data.email,
        password=hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    token = jwt.encode(
        {"id": new_user.id, "email": new_user.email},
        settings.JWT_SECRET,
        algorithm="HS256"
    )

    return {"token": token}

def login(data: LoginModel, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not bcrypt.verify(data.password, user.password):
        raise HTTPException(status_code=400, detail="Invalid credentials")

    token = jwt.encode(
        {"id": user.id, "email": user.email},
        settings.JWT_SECRET,
        algorithm="HS256"
    )

    return {"token": token}
