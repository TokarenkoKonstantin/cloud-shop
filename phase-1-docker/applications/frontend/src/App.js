import React, { useState, useEffect } from 'react';
import './App.css';

const API_BASE = 'http://product-service:8080';


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
       fetch('/api/products'),
       fetch('/api/orders'),
       fetch('/api/users')

      ]);

      if (productsRes.ok) setProducts(await productsRes.json());
      if (ordersRes.ok) setOrders(await ordersRes.json());
      if (usersRes.ok) setUsers(await usersRes.json());

      setHealth({
        products: productsRes.ok ? '✅' : '❌',
        orders: ordersRes.ok ? '✅' : '❌',
        users: usersRes.ok ? '✅' : '❌'
      });
    } catch (error) {
      console.error('Error fetching services:', error);
      setHealth({ products: '❌', orders: '❌', users: '❌' });
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>🛒 E-commerce Platform</h1>

        <div className="health-status">
          <h2>Service Health</h2>
          <div>Product Service (Go): {health.products}</div>
          <div>Order Service (Python): {health.orders}</div>
          <div>User Service (Python): {health.users}</div>
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
