package handler

import "net/http"

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		writeCORSHeaders(w)
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if r.Method != http.MethodGet {
		writeCORSHeaders(w)
		writeJSON(w, http.StatusMethodNotAllowed, errorResponse{Error: "method not allowed"})
		return
	}

	writeCORSHeaders(w)
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}