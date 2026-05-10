package ascii

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"unicode/utf8"
)

type convertRequest struct {
	Character string `json:"character"`
}

type convertResponse struct {
	Character  string `json:"character"`
	ASCIIValue int    `json:"ascii_value"`
}

type errorResponse struct {
	Error string `json:"error"`
}

func WriteCORSHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

func WriteJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		log.Printf("write json: %v", err)
	}
}

func WriteJSONError(w http.ResponseWriter, status int, message string) {
	WriteJSON(w, status, errorResponse{Error: message})
}

func ConvertHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		WriteCORSHeaders(w)
		w.WriteHeader(http.StatusNoContent)
		return
	}

	WriteCORSHeaders(w)

	if r.Method != http.MethodPost {
		WriteJSONError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var request convertRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		WriteJSONError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}

	character := strings.TrimSpace(request.Character)
	if character == "" {
		WriteJSONError(w, http.StatusBadRequest, "character is required")
		return
	}

	runeValue, size := utf8.DecodeRuneInString(character)
	if runeValue == utf8.RuneError || size == 0 || utf8.RuneCountInString(character) != 1 {
		WriteJSONError(w, http.StatusBadRequest, "send exactly one character")
		return
	}

	if runeValue > 127 {
		WriteJSONError(w, http.StatusBadRequest, "character must be ASCII")
		return
	}

	WriteJSON(w, http.StatusOK, convertResponse{
		Character:  character,
		ASCIIValue: int(runeValue),
	})
}

func HealthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		WriteCORSHeaders(w)
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if r.Method != http.MethodGet {
		WriteCORSHeaders(w)
		WriteJSONError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	WriteCORSHeaders(w)
	WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}