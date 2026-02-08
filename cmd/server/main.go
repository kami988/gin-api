package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/kami988/gin-api/gen/user/v1/userv1connect"
	"github.com/kami988/gin-api/internal/database"
	"github.com/kami988/gin-api/internal/handler"
	"github.com/kami988/gin-api/internal/service"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

func main() {
	// Load environment variables from .env file
	// For production, use proper environment variable management
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Initialize database
	dbConfig := database.NewConfig()
	db, err := database.NewPostgresDB(dbConfig)
	if err != nil {

	}
	defer db.Close()

	// Initialize database schema
	if err := database.InitSchema(db); err != nil {
		log.Fatalf("Failed to initialize database schema: %v", err)
	}

	// Initialize services
	userService := service.NewUserService(db)

	// Initialize handlers
	userHandler := handler.NewUserHandler(userService)

	// Setup Gin router
	router := gin.Default()

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "gin-api",
		})
	})

	// Connect RPC routes
	path, connectHandler := userv1connect.NewUserServiceHandler(userHandler)

	// Mount Connect handler on Gin router
	// Connect uses HTTP/2, so we need to handle it properly
	router.Any(path+"*action", gin.WrapH(connectHandler))

	// Get server port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Create HTTP server with h2c (HTTP/2 Cleartext) support
	// This allows Connect to work without TLS in development
	addr := ":" + port
	log.Printf("Starting server on %s", addr)
	log.Printf("Health check: http://localhost%s/health", addr)
	log.Printf("Connect RPC endpoint: http://localhost%s%s", addr, path)

	// Use h2c for HTTP/2 without TLS
	h2cHandler := h2c.NewHandler(router, &http2.Server{})

	if err := http.ListenAndServe(addr, h2cHandler); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
