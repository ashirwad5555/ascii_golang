package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
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

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/convert", convertHandler)

	handler := withCORS(mux)

	log.Println("backend listening on http://localhost:8080")
	if lanURL, err := localLANURL(8080); err == nil {
		log.Printf("backend network url: %s", lanURL)
	} else {
		log.Printf("backend network url unavailable: %v", err)
	}
	log.Println("android emulator url: http://10.0.2.2:8080")
	log.Fatal(http.ListenAndServe(":8080", handler))
}

func localLANURL(port int) (string, error) {
	interfaces, err := net.Interfaces()
	if err != nil {
		return "", err
	}

	var fallback net.IP

	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			ipNet, ok := addr.(*net.IPNet)
			if !ok || ipNet.IP == nil {
				continue
			}

			ip := ipNet.IP.To4()
			if ip == nil || ip.IsLoopback() || ip.IsLinkLocalUnicast() {
				continue
			}

			if ip.IsPrivate() {
				return fmt.Sprintf("http://%s:%d", ip.String(), port), nil
			}

			if fallback == nil {
				fallback = ip
			}
		}
	}

	if fallback != nil {
		return fmt.Sprintf("http://%s:%d", fallback.String(), port), nil
	}

	return "", fmt.Errorf("no usable LAN IPv4 address found")
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		writeCORSHeaders(w)
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if r.Method != http.MethodGet {
		writeJSONError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func convertHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		writeCORSHeaders(w)
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if r.Method != http.MethodPost {
		writeJSONError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var request convertRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		writeJSONError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}

	character := strings.TrimSpace(request.Character)
	if character == "" {
		writeJSONError(w, http.StatusBadRequest, "character is required")
		return
	}

	runeValue, size := utf8.DecodeRuneInString(character)
	if runeValue == utf8.RuneError || size == 0 || utf8.RuneCountInString(character) != 1 {
		writeJSONError(w, http.StatusBadRequest, "send exactly one character")
		return
	}

	if runeValue > 127 {
		writeJSONError(w, http.StatusBadRequest, "character must be ASCII")
		return
	}

	writeJSON(w, http.StatusOK, convertResponse{
		Character:  character,
		ASCIIValue: int(runeValue),
	})
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		writeCORSHeaders(w)
		next.ServeHTTP(w, r)
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
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		log.Printf("write json: %v", err)
	}
}

func writeJSONError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, errorResponse{Error: message})
}