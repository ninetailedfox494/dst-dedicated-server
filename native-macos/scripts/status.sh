#!/bin/bash
# scripts/status.sh — Check DST server status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

log "═══════════════════════════════════════════════════════"
log "  DST Server Status"
log "═══════════════════════════════════════════════════════"
log ""

# Screen sessions
log "Screen Sessions:"
if screen -ls 2>/dev/null | grep -q dst_master; then
    success "dst_master is running"
    local pid=$(get_session_pid "dst_master")
    [[ -n "$pid" ]] && log "  PID: $pid"
else
    warn "dst_master is not running"
fi

if screen -ls 2>/dev/null | grep -q dst_caves; then
    success "dst_caves is running"
    local pid=$(get_session_pid "dst_caves")
    [[ -n "$pid" ]] && log "  PID: $pid"
else
    warn "dst_caves is not running"
fi

log ""

# Ports
log "Port Status:"
if port_listening 10999 udp; then
    success "Port 10999/UDP (Master) is listening"
else
    warn "Port 10999/UDP (Master) is NOT listening"
fi

if port_listening 10998 udp; then
    success "Port 10998/UDP (Caves) is listening"
else
    warn "Port 10998/UDP (Caves) is NOT listening"
fi

if port_listening 27016 udp; then
    success "Port 27016/UDP (Steam Master) is listening"
else
    warn "Port 27016/UDP (Steam Master) is NOT listening"
fi

log ""

# Process info
log "Process Info:"
if pgrep -f "dontstarve_dedicated_server_nullrenderer" >/dev/null; then
    local count=$(pgrep -f "dontstarve_dedicated_server_nullrenderer" | wc -l)
    success "$count DST process(es) running"
    ps aux | grep -F "dontstarve_dedicated_server_nullrenderer" | grep -v grep | awk '{print "  " $2 " " $11}' || true
else
    warn "No DST processes running"
fi

log ""
log "═══════════════════════════════════════════════════════"
