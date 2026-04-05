from datetime import datetime, timedelta
from typing import Optional
import hashlib
import os

SECRET_KEY = os.getenv("JWT_SECRET", "dev-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30


def get_password_hash(password: str) -> str:
    # Simple SHA256 for dev — replace with bcrypt in production
    return hashlib.sha256(password.encode()).hexdigest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return get_password_hash(plain_password) == hashed_password


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    try:
        from jose import jwt
    except ImportError:
        import base64, json, time
        # Fallback: simple base64 token without real JWT
        to_encode = {**data}
        if expires_delta:
            to_encode["exp"] = int((datetime.utcnow() + expires_delta).timestamp())
        else:
            to_encode["exp"] = int((datetime.utcnow() + timedelta(minutes=15)).timestamp())
        payload = json.dumps(to_encode).encode()
        return base64.b64encode(payload).decode()

    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
