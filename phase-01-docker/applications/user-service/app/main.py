from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import init_db, get_db
from app.routes import users
from app.routes.users import seed_data


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    async for db in get_db():
        await seed_data(db)
        break
    yield


app = FastAPI(title="User Service", version="1.0.0", lifespan=lifespan)

app.include_router(users.router, prefix="/api/users", tags=["users"])


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "user-service"}


@app.get("/")
async def root():
    return {"message": "User Service API", "version": "1.0.0"}
