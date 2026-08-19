package ksd

// Local REST API for ksd (127.0.0.1 only; Lima forwards the port to WORLD 1).

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
)

type Server struct {
	m   *Manager
	log *slog.Logger
}

func NewServer(m *Manager, log *slog.Logger) *Server { return &Server{m: m, log: log} }

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}

func writeErr(w http.ResponseWriter, code int, err error) {
	writeJSON(w, code, map[string]string{"error": err.Error()})
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	s.inspectorRoutes(mux)
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]bool{"ok": true})
	})
	mux.HandleFunc("POST /sessions", func(w http.ResponseWriter, r *http.Request) {
		var req struct {
			Image, Workspace string
			Budget           int64
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeErr(w, 400, err)
			return
		}
		sess, err := s.m.CreateSession(req.Image, req.Workspace, req.Budget)
		if err != nil {
			s.log.Error("create failed", "error", err)
			writeErr(w, 500, err)
			return
		}
		writeJSON(w, 201, sess)
	})
	mux.HandleFunc("GET /sessions", func(w http.ResponseWriter, r *http.Request) {
		list, err := s.m.List()
		if err != nil {
			writeErr(w, 500, err)
			return
		}
		if list == nil {
			list = []Session{}
		}
		writeJSON(w, 200, list)
	})
	// gc plans by default and only deletes when explicitly asked (ADR-011).
	// ksd owns the store, so gc runs here rather than opening the database a
	// second time from the CLI.
	mux.HandleFunc("POST /gc", func(w http.ResponseWriter, r *http.Request) {
		plan, err := s.m.GCPlan()
		if err != nil {
			writeErr(w, 500, err)
			return
		}
		if r.URL.Query().Get("apply") == "1" {
			if err := s.m.GCApply(plan); err != nil {
				writeErr(w, 500, err)
				return
			}
		}
		writeJSON(w, 200, plan)
	})
	mux.HandleFunc("GET /sessions/{id}", func(w http.ResponseWriter, r *http.Request) {
		sess, err := s.m.Get(r.PathValue("id"))
		if err != nil {
			writeErr(w, 404, err)
			return
		}
		writeJSON(w, 200, sess)
	})
	mux.HandleFunc("POST /sessions/{id}/checkpoint", func(w http.ResponseWriter, r *http.Request) {
		var req struct{ Stop bool }
		_ = json.NewDecoder(r.Body).Decode(&req)
		if err := s.m.Checkpoint(r.PathValue("id"), req.Stop); err != nil {
			s.log.Error("checkpoint failed", "error", err)
			writeErr(w, 500, err)
			return
		}
		writeJSON(w, 200, map[string]bool{"ok": true})
	})
	mux.HandleFunc("GET /sessions/{id}/file", func(w http.ResponseWriter, r *http.Request) {
		present, err := s.m.FileExists(r.PathValue("id"), r.URL.Query().Get("path"))
		if err != nil {
			writeErr(w, 500, err)
			return
		}
		writeJSON(w, 200, map[string]bool{"present": present})
	})
	mux.HandleFunc("POST /sessions/{id}/fork", func(w http.ResponseWriter, r *http.Request) {
		n := 1
		if q := r.URL.Query().Get("n"); q != "" {
			if _, err := fmt.Sscanf(q, "%d", &n); err != nil || n < 1 || n > 16 {
				writeErr(w, 400, fmt.Errorf("bad n=%q", q))
				return
			}
		}
		var steers []string
		if q := r.URL.Query().Get("steers"); q != "" {
			_ = json.Unmarshal([]byte(q), &steers)
		}
		children, err := s.m.Fork(r.PathValue("id"), n, steers)
		if err != nil {
			s.log.Error("fork failed", "error", err)
			writeErr(w, 500, err)
			return
		}
		writeJSON(w, 201, children)
	})
	mux.HandleFunc("POST /sessions/{id}/resume", func(w http.ResponseWriter, r *http.Request) {
		sess, err := s.m.ResumeSession(r.PathValue("id"))
		if err != nil {
			s.log.Error("resume failed", "error", err)
			writeErr(w, 500, err)
			return
		}
		writeJSON(w, 200, sess)
	})
	mux.HandleFunc("DELETE /sessions/{id}", func(w http.ResponseWriter, r *http.Request) {
		if err := s.m.Kill(r.PathValue("id")); err != nil {
			writeErr(w, 500, err)
			return
		}
		writeJSON(w, 200, map[string]bool{"ok": true})
	})
	return mux
}
