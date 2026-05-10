package handler

import (
	"net/http"

	ascii "golang_ascii_backend/internal/ascii"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	ascii.HealthHandler(w, r)
}