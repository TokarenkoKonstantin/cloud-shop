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
