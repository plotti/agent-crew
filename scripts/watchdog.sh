#!/usr/bin/env bash
# Watchdog: schickt dem Router alle zehn Minuten einen Bericht, damit ein hängender Lauf auffällt.
#
#   CREW_TMUX="-L crews:router" scripts/watchdog.sh &
#
# CREW_TMUX ist das tmux-Ziel des Router-Fensters, Standard "-L crews:router" (Server "crews",
# Session "router"). Läuft kein tmux, landet der Bericht in .crew/log/watchdog.txt – dann muss ihn
# jemand von Hand lesen.
#
# Stoppen: pkill -f watchdog.sh

set -u

TARGET="${CREW_TMUX:--L crews:router}"
INTERVAL="${CREW_INTERVAL:-600}"   # Sekunden

crew_dir=""
d="$PWD"
while [ -n "$d" ] && [ "$d" != "/" ]; do
  [ -f "$d/.crew/board.md" ] && crew_dir="$d/.crew" && break
  d="$(dirname "$d")"
done
[ -n "$crew_dir" ] && mkdir -p "$crew_dir/log"

send() {
  # shellcheck disable=SC2086
  tmux $TARGET send-keys -l "$1" 2>/dev/null && tmux $TARGET send-keys Enter 2>/dev/null
}

while :; do
  sleep "$INTERVAL"
  [ -n "$crew_dir" ] && [ ! -f "$crew_dir/board.md" ] && break   # Crew beendet
  send "Watchdog: Bericht."
  [ -n "$crew_dir" ] && echo "$(date '+%H:%M:%S') Watchdog: Bericht." >> "$crew_dir/log/watchdog.txt"
done
