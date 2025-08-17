// Package main provides the entry point for the batch application.
// This application serves a Fiber web server with static file support or proxy to Next.js dev server.
package main

import (
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/proxy"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/joho/godotenv"
)

// main is the entry point of the application.
// It initializes the Fiber app and starts the server on port 8088.
func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	fmt.Println("NODE_ENV: ", os.Getenv("NODE_ENV"))
	// Get environment variables
	nodeEnv := getEnv("NODE_ENV", "production")
	frontendURL := getEnv("FRONTEND_URL", "http://localhost:3001")

	// Create a new Fiber instance
	app := fiber.New(fiber.Config{
		AppName: "Batch Application v1.0.0",
	})

	// Add middleware
	app.Use(logger.New())
	app.Use(recover.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,HEAD,PUT,DELETE,PATCH,OPTIONS",
		AllowHeaders: "*",
	}))

	// Configure frontend serving based on environment
	if nodeEnv == "development" {
		log.Printf("Development mode: Proxying to Next.js dev server at %s", frontendURL)
		setupDevelopmentProxy(app, frontendURL)
	} else {
		log.Println("Production mode: Serving static files from ./static/dist")
		// Serve static files from the static directory
		app.Static("/", "./static/dist", fiber.Static{
			Index:  "index.html",
			Browse: false,
		})
	}

	// API routes
	api := app.Group("/api")

	// Health check endpoint
	api.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "ok",
			"message":   "Server is running",
			"timestamp": time.Now().Unix(),
			"version":   "1.0.0",
			"env":       nodeEnv,
		})
	})

	// Readiness probe for Dokploy/Kubernetes
	api.Get("/ready", func(c *fiber.Ctx) error {
		// Add any readiness checks here (database, external services, etc.)
		return c.JSON(fiber.Map{
			"status":  "ready",
			"message": "Application is ready to serve traffic",
		})
	})

	// Liveness probe for Dokploy/Kubernetes
	api.Get("/live", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "alive",
			"message": "Application is alive",
		})
	})

	// Example API endpoint
	api.Get("/hello", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"message": "Hello from Golang Fiber!",
		})
	})

	// Get port from environment variable or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8088"
	}

	// Start server
	log.Printf("Server starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}

// getEnv gets an environment variable with a fallback value.
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// setupDevelopmentProxy sets up proxy to Next.js dev server for development mode.
func setupDevelopmentProxy(app *fiber.App, frontendURL string) {
	// Parse the frontend URL
	_, err := url.Parse(frontendURL)
	if err != nil {
		log.Fatalf("Invalid frontend URL: %v", err)
	}

	// Health check for frontend server
	app.Get("/health/frontend", func(c *fiber.Ctx) error {
		resp, err := http.Get(frontendURL)
		if err != nil {
			return c.Status(503).JSON(fiber.Map{
				"status":  "error",
				"message": "Frontend server is not available",
				"url":     frontendURL,
			})
		}
		defer resp.Body.Close()

		return c.JSON(fiber.Map{
			"status":  "ok",
			"message": "Frontend server is available",
			"url":     frontendURL,
		})
	})

	// Proxy all non-API requests to Next.js dev server
	app.Use(func(c *fiber.Ctx) error {
		path := c.Path()

		// Skip API routes - let them be handled by our API handlers
		if strings.HasPrefix(path, "/api") {
			return c.Next()
		}

		// Proxy to Next.js dev server
		return proxy.Do(c, frontendURL+path+"?"+string(c.Request().URI().QueryString()))
	})
}
