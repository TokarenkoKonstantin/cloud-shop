#!/bin/bash
# DevOps Master Project - Создание структуры проекта
# Запускать из корня devops-pet-project

echo "🚀 Создание структуры проекта..."

# Создаём все папки
mkdir -p applications/product-service/cmd
mkdir -p applications/product-service/internal/handler
mkdir -p applications/order-service/app/routes
mkdir -p applications/user-service/app/routes
mkdir -p applications/frontend/src

echo "✅ Папки созданы"

# ============================================
# PRODUCT SERVICE (Go)
# ============================================

cat > applications/product-service/cmd/main.go << 'EOF'
package main

import (
	"log"
	"net/http"
	"os"

	"product-service/internal/handler"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	h := handler.NewHandler()

	http.HandleFunc("/health", h.Health)
	http.HandleFunc("/api/products", h.GetProducts)
	http.HandleFunc("/api/products/", h.GetProduct)

	log.Printf("🚀 Product Service starting on port %s", port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal(err)
	}
}
EOF

cat > applications/product-service/internal/handler/handler.go << 'EOF'
package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

type Product struct {
	ID          int     `json:"id"`
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Price       float64 `json:"price"`
	Stock       int     `json:"stock"`
}

var products = []Product{
	{ID: 1, Name: "iPhone 15", Description: "Apple smartphone", Price: 999.99, Stock: 100},
	{ID: 2, Name: "MacBook Pro", Description: "Apple laptop", Price: 1999.99, Stock: 50},
	{ID: 3, Name: "AirPods Pro", Description: "Wireless earbuds", Price: 249.99, Stock: 200},
}

type Handler struct{}

func NewHandler() *Handler {
	return &Handler{}
}

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "healthy",
		"service": "product-service",
	})
}

func (h *Handler) GetProducts(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)
}

func (h *Handler) GetProduct(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(r.URL.Path, "/")
	id := parts[len(parts)-1]

	w.Header().Set("Content-Type", "application/json")
	for _, p := range products {
		if fmt.Sprintf("%d", p.ID) == id {
			json.NewEncoder(w).Encode(p)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	json.NewEncoder(w).Encode(map[string]string{"error": "Product not found"})
}
EOF

cat > applications/product-service/Dockerfile << 'EOF'
# ===== BUILD STAGE =====
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/main.go

# ===== RUNTIME STAGE =====
FROM alpine:3.18

WORKDIR /app

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

# Copy binary from builder
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Run binary
CMD ["./main"]
EOF

cat > applications/product-service/.dockerignore << 'EOF'
.git
.gitignore
*.md
.env
vendor/
bin/
EOF

echo "✅ Product Service (Go) создан"

# ============================================
# ORDER SERVICE (Python/FastAPI)
# ============================================

cat > applications/order-service/requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
EOF

cat > applications/order-service/app/main.py << 'EOF'
from fastapi import FastAPI
from app.routes import orders

app = FastAPI(
    title="Order Service",
    description="E-commerce Order Management",
    version="1.0.0"
)

app.include_router(orders.router, prefix="/api/orders", tags=["orders"])

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "order-service"
    }

@app.get("/")
async def root():
    return {"message": "Order Service API", "version": "1.0.0"}
EOF

cat > applications/order-service/app/models.py << 'EOF'
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class OrderStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"

class Order(BaseModel):
    id: int
    user_id: int
    product_ids: list[int]
    total_amount: float
    status: OrderStatus = OrderStatus.PENDING
    created_at: datetime = datetime.now()
    updated_at: Optional[datetime] = None

    class Config:
        json_schema_extra = {
            "example": {
                "id": 1,
                "user_id": 123,
                "product_ids": [1, 2],
                "total_amount": 2999.98,
                "status": "pending"
            }
        }
EOF

cat > applications/order-service/app/routes/orders.py << 'EOF'
from fastapi import APIRouter, HTTPException
from app.models import Order, OrderStatus
from typing import List

router = APIRouter()

# In-memory storage (will be replaced with DB later)
orders_db: List[Order] = [
    Order(id=1, user_id=123, product_ids=[1, 2], total_amount=2999.98, status=OrderStatus.PENDING),
    Order(id=2, user_id=456, product_ids=[3], total_amount=249.99, status=OrderStatus.SHIPPED),
]

@router.get("/", response_model=List[Order])
async def get_all_orders():
    return orders_db

@router.get("/{order_id}", response_model=Order)
async def get_order(order_id: int):
    for order in orders_db:
        if order.id == order_id:
            return order
    raise HTTPException(status_code=404, detail="Order not found")

@router.post("/", response_model=Order)
async def create_order(order: Order):
    order.id = len(orders_db) + 1
    orders_db.append(order)
    return order
EOF

cat > applications/order-service/Dockerfile << 'EOF'
# ===== BUILD STAGE =====
FROM python:3.11-slim AS builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ===== RUNTIME STAGE =====
FROM python:3.11-slim

WORKDIR /app

# Create non-root user
RUN useradd -m -u 1000 appuser

# Copy installed packages from builder
COPY --from=builder /root/.local /home/appuser/.local
COPY --from=builder /app .

# Copy application code
COPY app/ ./app/

# Set PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

cat > applications/order-service/.dockerignore << 'EOF'
.git
.gitignore
*.md
.env
__pycache__/
*.pyc
.venv/
venv/
EOF

echo "✅ Order Service (Python) создан"

# ============================================
# USER SERVICE (Python/FastAPI)
# ============================================

cat > applications/user-service/requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
EOF

cat > applications/user-service/app/main.py << 'EOF'
from fastapi import FastAPI
from app.routes import users

app = FastAPI(
    title="User Service",
    description="User Authentication and Management",
    version="1.0.0"
)

app.include_router(users.router, prefix="/api/users", tags=["users"])

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "user-service"
    }

@app.get("/")
async def root():
    return {"message": "User Service API", "version": "1.0.0"}
EOF

cat > applications/user-service/app/models.py << 'EOF'
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class User(BaseModel):
    id: int
    email: str
    username: str
    hashed_password: str
    is_active: bool = True
    created_at: datetime = datetime.now()

class UserCreate(BaseModel):
    email: str
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
EOF

cat > applications/user-service/app/auth.py << 'EOF'
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext

SECRET_KEY = "your-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
EOF

cat > applications/user-service/app/routes/users.py << 'EOF'
from fastapi import APIRouter, HTTPException
from app.models import User, UserCreate, UserResponse, Token
from app.auth import get_password_hash, verify_password, create_access_token
from datetime import timedelta
from typing import List

router = APIRouter()

# In-memory storage
users_db: List[User] = [
    User(
        id=1,
        email="admin@example.com",
        username="admin",
        hashed_password=get_password_hash("admin123"),
        is_active=True
    ),
]

@router.post("/register", response_model=UserResponse)
async def register(user_data: UserCreate):
    # Check if user exists
    for user in users_db:
        if user.email == user_data.email or user.username == user_data.username:
            raise HTTPException(status_code=400, detail="User already exists")

    new_user = User(
        id=len(users_db) + 1,
        email=user_data.email,
        username=user_data.username,
        hashed_password=get_password_hash(user_data.password),
        is_active=True
    )
    users_db.append(new_user)
    return new_user

@router.post("/login", response_model=Token)
async def login(email: str, password: str):
    for user in users_db:
        if user.email == email and verify_password(password, user.hashed_password):
            access_token = create_access_token(
                data={"sub": user.email, "user_id": user.id},
                expires_delta=timedelta(minutes=30)
            )
            return {"access_token": access_token}
    raise HTTPException(status_code=401, detail="Invalid credentials")

@router.get("/", response_model=List[UserResponse])
async def get_all_users():
    return users_db

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    for user in users_db:
        if user.id == user_id:
            return user
    raise HTTPException(status_code=404, detail="User not found")
EOF

cat > applications/user-service/Dockerfile << 'EOF'
# ===== BUILD STAGE =====
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ===== RUNTIME STAGE =====
FROM python:3.11-slim

WORKDIR /app

RUN useradd -m -u 1000 appuser

COPY --from=builder /root/.local /home/appuser/.local
COPY --from=builder /app .

COPY app/ ./app/

ENV PATH=/home/appuser/.local/bin:$PATH

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

cat > applications/user-service/.dockerignore << 'EOF'
.git
.gitignore
*.md
.env
__pycache__/
*.pyc
.venv/
venv/
EOF

echo "✅ User Service (Python) создан"

# ============================================
# DOCKER COMPOSE
# ============================================

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Product Service (Go)
  product-service:
    build:
      context: ./applications/product-service
      dockerfile: Dockerfile
    container_name: product-service
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - ENV=development
    networks:
      - ecommerce-network
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  # Order Service (Python)
  order-service:
    build:
      context: ./applications/order-service
      dockerfile: Dockerfile
    container_name: order-service
    ports:
      - "8081:8000"
    environment:
      - ENV=development
    networks:
      - ecommerce-network
    depends_on:
      - product-service
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  # User Service (Python)
  user-service:
    build:
      context: ./applications/user-service
      dockerfile: Dockerfile
    container_name: user-service
    ports:
      - "8082:8000"
    environment:
      - ENV=development
    networks:
      - ecommerce-network
    depends_on:
      - product-service
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

networks:
  ecommerce-network:
    driver: bridge
EOF

echo "✅ docker-compose.yml создан"

# ============================================
# ИНИЦИАЛИЗАЦИЯ GO МОДУЛЯ
# ============================================

echo "🔄 Инициализация Go модуля..."
cd applications/product-service
go mod init product-service
go mod tidy
cd ../..

echo "✅ Go модуль инициализирован"

echo ""
echo "========================================"
echo "🎉 СТРУКТУРА ПРОЕКТА СОЗДАНА!"
echo "========================================"
echo ""
echo "Следующие шаги:"
echo "1. Создай React frontend:"
echo "   cd applications"
echo "   npx create-react-app frontend --template cra-template"
echo ""
echo "2. Обнови frontend/src/App.js и App.css"
echo "3. Создай Dockerfile для frontend"
echo ""
echo "4. Запусти всё:"
echo "   docker-compose up --build"
echo ""
echo "========================================"
