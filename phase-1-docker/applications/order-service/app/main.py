from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.database import init_db, get_db
from app.routes import orders
from app.routes.orders import seed_data


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    async for db in get_db():
        await seed_data(db)
        break
    yield


app = FastAPI(title="Order Service", version="1.0.0", lifespan=lifespan)

app.include_router(orders.router, prefix="/api/orders", tags=["orders"])


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "order-service"}


@app.get("/")
async def root():
    return {"message": "Order Service API", "version": "1.0.0"}
