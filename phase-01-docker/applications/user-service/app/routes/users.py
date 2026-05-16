from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models import User
from app.auth import get_password_hash, create_access_token
from datetime import timedelta, datetime
from typing import List
import time

router = APIRouter()


@router.post("/register", response_model=dict)
async def register(user_data: dict, db: AsyncSession = Depends(get_db)):
    # Check if user exists
    result = await db.execute(
        select(User).where(
            (User.email == user_data["email"]) | (User.username == user_data["username"])
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="User already exists")

    user = User(
        email=user_data["email"],
        username=user_data["username"],
        hashed_password=get_password_hash(user_data["password"]),
        is_active=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return {
        "id": user.id,
        "email": user.email,
        "username": user.username,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }


@router.post("/login", response_model=dict)
async def login(credentials: dict, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == credentials["email"]))
    user = result.scalar_one_or_none()
    if not user or not verify_password(credentials["password"], user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(
        data={"sub": user.email, "user_id": user.id},
        expires_delta=timedelta(minutes=30),
    )
    return {"access_token": token}


@router.get("/", response_model=List[dict])
async def get_all_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User))
    users = result.scalars().all()
    return [
        {
            "id": u.id,
            "email": u.email,
            "username": u.username,
            "is_active": u.is_active,
            "created_at": u.created_at.isoformat() if u.created_at else None,
        }
        for u in users
    ]


@router.get("/{user_id}", response_model=dict)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "id": user.id,
        "email": user.email,
        "username": user.username,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }


async def seed_data(db: AsyncSession):
    """Seed admin user if table is empty."""
    result = await db.execute(select(User))
    if result.scalars().first():
        return
    user = User(
        email="admin@example.com",
        username="admin",
        hashed_password=get_password_hash("admin123"),
        is_active=True,
    )
    db.add(user)
    await db.commit()
