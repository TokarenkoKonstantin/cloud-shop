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
		"db":      "in-memory",
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
