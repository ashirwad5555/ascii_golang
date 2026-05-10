package handler

import "net/http"

func Handler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/health" {
		healthHandler(w, r)
		return
	}

	convertHandler(w, r)
}