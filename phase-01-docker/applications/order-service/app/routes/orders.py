from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from app.database import get_db
from app.models import Order
from datetime import datetime
from typing import List

router = APIRouter()


@router.get("/", response_model=List[dict])
async def get_all_orders(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Order).order_by(desc(Order.created_at)))
    orders = result.scalars().all()
    return [
        {
            "id": o.id,
            "user_id": o.user_id,
            "product_ids": o.product_ids,
            "total_amount": o.total_amount,
            "status": o.status,
            "created_at": o.created_at.isoformat() if o.created_at else None,
            "updated_at": o.updated_at.isoformat() if o.updated_at else None,
        }
        for o in orders
    ]


@router.get("/{order_id}", response_model=dict)
async def get_order(order_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return {
        "id": order.id,
        "user_id": order.user_id,
        "product_ids": order.product_ids,
        "total_amount": order.total_amount,
        "status": order.status,
        "created_at": order.created_at.isoformat() if order.created_at else None,
        "updated_at": order.updated_at.isoformat() if order.updated_at else None,
    }


@router.post("/", response_model=dict)
async def create_order(order_data: dict, db: AsyncSession = Depends(get_db)):
    order = Order(
        user_id=order_data["user_id"],
        product_ids=order_data["product_ids"],
        total_amount=order_data["total_amount"],
        status=order_data.get("status", "pending"),
    )
    db.add(order)
    await db.commit()
    await db.refresh(order)
    return {
        "id": order.id,
        "user_id": order.user_id,
        "product_ids": order.product_ids,
        "total_amount": order.total_amount,
        "status": order.status,
        "created_at": order.created_at.isoformat(),
        "updated_at": None,
    }


async def seed_data(db: AsyncSession):
    """Seed initial orders if table is empty."""
    result = await db.execute(select(Order))
    if result.scalars().first():
        return  # already seeded
    orders = [
        Order(user_id=123, product_ids=[1, 2], total_amount=2999.98, status="pending"),
        Order(user_id=456, product_ids=[3], total_amount=249.99, status="shipped"),
    ]
    db.add_all(orders)
    await db.commit()
