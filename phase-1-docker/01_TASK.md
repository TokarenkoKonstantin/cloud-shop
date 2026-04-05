# 🐳 Этап 1: Docker и контейнеризация

## 📋 Задача 1.1: Создание микросервисов

### Цель
Написать 3 простых микросервиса и завернуть их в Docker.

---

## 🔹 Шаг 1: Product Service (Go)

### Структура:
```
applications/product-service/
├── cmd/
│   └── main.go
├── internal/
│   └── handler/
│       └── handler.go
├── go.mod
├── go.sum
├── Dockerfile
└── requirements.md
```

### 1. Создай файл `applications/product-service/cmd/main.go`:

```go
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
```

### 2. Создай `applications/product-service/internal/handler/handler.go`:

```go
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
```

### 3. Инициализируй Go модуль:
```bash
cd applications/product-service
go mod init product-service
go mod tidy
```

### 4. Создай `applications/product-service/Dockerfile`:

```dockerfile
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
```

### 5. Создай `.dockerignore`:
```
.git
.gitignore
*.md
.env
vendor/
bin/
```

---

## 🔹 Шаг 2: Order Service (Python/FastAPI)

### Структура:
```
applications/order-service/
├── app/
│   ├── main.py
│   ├── models.py
│   └── routes/
│       └── orders.py
├── requirements.txt
├── Dockerfile
└── .dockerignore
```

### 1. Создай `applications/order-service/requirements.txt`:
```
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
```

### 2. Создай `applications/order-service/app/main.py`:
```python
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
```

### 3. Создай `applications/order-service/app/models.py`:
```python
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
```

### 4. Создай `applications/order-service/app/routes/orders.py`:
```python
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
```

### 5. Создай `applications/order-service/Dockerfile`:
```dockerfile
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
```

### 6. Создай `.dockerignore`:
```
.git
.gitignore
*.md
.env
__pycache__/
*.pyc
.venv/
venv/
```

---

## 🔹 Шаг 3: User Service (Python/FastAPI)

### Структура:
```
applications/user-service/
├── app/
│   ├── main.py
│   ├── models.py
│   ├── auth.py
│   └── routes/
│       └── users.py
├── requirements.txt
├── Dockerfile
└── .dockerignore
```

### 1. Создай `applications/user-service/requirements.txt`:
```
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
```

### 2. Создай `applications/user-service/app/main.py`:
```python
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
```

### 3. Создай `applications/user-service/app/models.py`:
```python
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
```

### 4. Создай `applications/user-service/app/auth.py`:
```python
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
```

### 5. Создай `applications/user-service/app/routes/users.py`:
```python
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
```

### 6. Создай `applications/user-service/Dockerfile`:
```dockerfile
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
```

---

## 🔹 Шаг 4: Frontend (React)

### Структура:
```
applications/frontend/
├── public/
│   └── index.html
├── src/
│   ├── index.js
│   ├── App.js
│   └── components/
│       ├── Products.js
│       ├── Orders.js
│       └── Users.js
├── package.json
├── Dockerfile
└── .dockerignore
```

### 1. Создай React приложение:
```bash
cd applications/
npx create-react-app frontend --template cra-template
cd frontend
```

### 2. Обнови `applications/frontend/src/App.js`:
```javascript
import React, { useState, useEffect } from 'react';
import './App.css';

const API_BASE = process.env.REACT_APP_API_BASE || 'http://localhost:8080';

function App() {
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);
  const [users, setUsers] = useState([]);
  const [health, setHealth] = useState({});

  useEffect(() => {
    fetchServices();
  }, []);

  const fetchServices = async () => {
    try {
      const [productsRes, ordersRes, usersRes] = await Promise.all([
        fetch(`${API_BASE}/api/products`),
        fetch(`${API_BASE}/api/orders`),
        fetch(`${API_BASE}/api/users`)
      ]);
      
      if (productsRes.ok) setProducts(await productsRes.json());
      if (ordersRes.ok) setOrders(await ordersRes.json());
      if (usersRes.ok) setUsers(await usersRes.json());
      
      setHealth({
        products: productsRes.ok ? 'healthy' : 'error',
        orders: ordersRes.ok ? 'healthy' : 'error',
        users: usersRes.ok ? 'healthy' : 'error'
      });
    } catch (error) {
      console.error('Error fetching services:', error);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>🛒 E-commerce Platform</h1>
        
        <div className="health-status">
          <h2>Service Health</h2>
          <div>Product Service: {health.products === 'healthy' ? '✅' : '❌'}</div>
          <div>Order Service: {health.orders === 'healthy' ? '✅' : '❌'}</div>
          <div>User Service: {health.users === 'healthy' ? '✅' : '❌'}</div>
        </div>

        <div className="services">
          <div className="service-section">
            <h2>Products ({products.length})</h2>
            <pre>{JSON.stringify(products, null, 2)}</pre>
          </div>

          <div className="service-section">
            <h2>Orders ({orders.length})</h2>
            <pre>{JSON.stringify(orders, null, 2)}</pre>
          </div>

          <div className="service-section">
            <h2>Users ({users.length})</h2>
            <pre>{JSON.stringify(users, null, 2)}</pre>
          </div>
        </div>
      </header>
    </div>
  );
}

export default App;
```

### 3. Обнови `applications/frontend/src/App.css`:
```css
.App {
  text-align: center;
}

.App-header {
  background-color: #282c34;
  min-height: 100vh;
  padding: 20px;
  color: white;
}

.health-status {
  background: #3a3f4b;
  padding: 20px;
  border-radius: 10px;
  margin: 20px auto;
  max-width: 400px;
}

.health-status div {
  margin: 10px 0;
  font-size: 18px;
}

.services {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
  text-align: left;
}

.service-section {
  background: #3a3f4b;
  padding: 15px;
  border-radius: 10px;
}

.service-section pre {
  background: #1e1e1e;
  padding: 10px;
  border-radius: 5px;
  overflow-x: auto;
  font-size: 12px;
  max-height: 300px;
  overflow-y: auto;
}
```

### 4. Создай `applications/frontend/Dockerfile`:
```dockerfile
# ===== BUILD STAGE =====
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ===== RUNTIME STAGE =====
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx config (optional, for custom config)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 5. Создай `.dockerignore`:
```
node_modules
build
.git
.gitignore
*.md
.env
.env.local
```

---

## 🔹 Шаг 5: Docker Compose

### Создай корневой `docker-compose.yml`:

```yaml
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

  # Frontend (React + Nginx)
  frontend:
    build:
      context: ./applications/frontend
      dockerfile: Dockerfile
    container_name: frontend
    ports:
      - "3000:80"
    environment:
      - REACT_APP_API_BASE=http://localhost:8080
    networks:
      - ecommerce-network
    depends_on:
      - product-service
      - order-service
      - user-service

networks:
  ecommerce-network:
    driver: bridge
```

---

## ✅ Твои задачи

1. **Создай структуру папок:**
   ```bash
   mkdir -p devops-pet-project/applications/{product-service,order-service,user-service,frontend}
   ```

2. **Скопируй код выше** в соответствующие файлы

3. **Собери и запусти:**
   ```bash
   cd devops-pet-project
   docker-compose up --build
   ```

4. **Проверь работу:**
   - Product Service: http://localhost:8080/health
   - Order Service: http://localhost:8081/health
   - User Service: http://localhost:8082/health
   - Frontend: http://localhost:3000

5. **Протестируй API:**
   ```bash
   curl http://localhost:8080/api/products
   curl http://localhost:8081/api/orders
   curl http://localhost:8082/api/users
   ```

---

## 📝 Что сделать дальше

Когда всё запустится:
1. Покажи мне вывод `docker ps`
2. Покажи вывод `docker-compose logs` (если будут ошибки)
3. Скриншот браузера с фронтендом

**После этого объясню:**
- Почему multi-stage билды
- Зачем non-root пользователь
- Как оптимизировать образы
- Что дальше (Kubernetes!)
