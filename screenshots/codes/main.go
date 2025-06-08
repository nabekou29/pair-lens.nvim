package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

// User represents a user data structure
type User struct {
	ID        int    `json:"id"`
	Name      string `json:"name"`
	Email     string `json:"email"`
	Age       int    `json:"age"`
	Role      string `json:"role"`
	CreatedAt string `json:"created_at"`
}

// Response represents a generic API response
type Response struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Sample users data
var users = []User{
	{ID: 1, Name: "John Doe", Email: "john@example.com", Age: 28, Role: "admin", CreatedAt: "2024-01-15T10:00:00Z"},
	{ID: 2, Name: "Jane Smith", Email: "jane@example.com", Age: 32, Role: "user", CreatedAt: "2024-02-20T14:30:00Z"},
	{ID: 3, Name: "Bob Johnson", Email: "bob@example.com", Age: 25, Role: "moderator", CreatedAt: "2024-03-10T09:15:00Z"},
	{ID: 4, Name: "Alice Brown", Email: "alice@example.com", Age: 29, Role: "user", CreatedAt: "2024-04-05T16:45:00Z"},
	{ID: 5, Name: "Charlie Wilson", Email: "charlie@example.com", Age: 35, Role: "admin", CreatedAt: "2024-05-12T11:20:00Z"},
	{ID: 6, Name: "Diana Lee", Email: "diana@example.com", Age: 27, Role: "user", CreatedAt: "2024-06-01T08:30:00Z"},
}

// Health check endpoint
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := Response{
		Message: "Server is running",
		Data: map[string]string{
			"timestamp": time.Now().Format(time.RFC3339),
			"version":   "1.0.0",
		},
	}
	json.NewEncoder(w).Encode(response)
}

// Get all users endpoint
func getUsersHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := Response{
		Message: "Users retrieved successfully",
		Data:    users,
	}
	json.NewEncoder(w).Encode(response)
}

// Get user by ID endpoint
func getUserHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Simple ID extraction from URL path
	userID := r.URL.Query().Get("id")
	if userID == "" {
		http.Error(w, "User ID is required", http.StatusBadRequest)
		return
	}

	// Find user (simplified logic)
	for _, user := range users {
		if fmt.Sprintf("%d", user.ID) == userID {
			response := Response{
				Message: "User found",
				Data:    user,
			}
			json.NewEncoder(w).Encode(response)
			return
		}
	}

	http.Error(w, "User not found", http.StatusNotFound)
}

// Create user endpoint
func createUserHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	var newUser User
	if err := json.NewDecoder(r.Body).Decode(&newUser); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Generate new ID
	newUser.ID = len(users) + 1
	users = append(users, newUser)

	response := Response{
		Message: "User created successfully",
		Data:    newUser,
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// Middleware for logging requests
func loggingMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		log.Printf("Started %s %s", r.Method, r.URL.Path)

		next.ServeHTTP(w, r)

		log.Printf("Completed %s %s in %v", r.Method, r.URL.Path, time.Since(start))
	}
}

func main() {
	// Setup routes
	http.HandleFunc("/health", loggingMiddleware(healthHandler))
	http.HandleFunc("/users", loggingMiddleware(getUsersHandler))
	http.HandleFunc("/user", loggingMiddleware(getUserHandler))
	http.HandleFunc("/user/create", loggingMiddleware(createUserHandler))

	// Static file serving for frontend assets
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("./static"))))

	// Root endpoint
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		fmt.Fprintf(w, "Welcome to Go Server API\n")
		fmt.Fprintf(w, "Available endpoints:\n")
		fmt.Fprintf(w, "GET /health - Health check\n")
		fmt.Fprintf(w, "GET /users - Get all users\n")
		fmt.Fprintf(w, "GET /user?id=1 - Get user by ID\n")
		fmt.Fprintf(w, "POST /user/create - Create new user\n")
	})

	port := ":8080"
	log.Printf("Server starting on port %s", port)
	log.Printf("Visit http://localhost%s for API documentation", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}
