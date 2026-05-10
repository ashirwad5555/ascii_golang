package handler

import (
	"encoding/json"
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

func convertHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		writeCORSHeaders(w)
		w.WriteHeader(http.StatusNoContent)
		return
	}

	writeCORSHeaders(w)

	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, errorResponse{Error: "method not allowed"})
		return
	}

	var request convertRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "invalid JSON body"})
		return
	}

	character := strings.TrimSpace(request.Character)
	if character == "" {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "character is required"})
		return
	}

	runeValue, size := utf8.DecodeRuneInString(character)
	if runeValue == utf8.RuneError || size == 0 || utf8.RuneCountInString(character) != 1 {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "send exactly one character"})
		return
	}

	if runeValue > 127 {
		writeJSON(w, http.StatusBadRequest, errorResponse{Error: "character must be ASCII"})
		return
	}

	writeJSON(w, http.StatusOK, convertResponse{
		Character:  character,
		ASCIIValue: int(runeValue),
	})
}

func writeCORSHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}