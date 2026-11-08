#!/usr/bin/env bash
# Board-Stand einer Crew zeigen.
#
#   board.sh            Board, Tickets, Branch-Alter, hängende Kandidaten
#   board.sh --brief    nur eine Zeile (für den SessionStart-Hook; schweigt, wenn keine Crew läuft)
#
# Sucht .crew/ im aktuellen Verzeichnis und in den darüberliegenden.

set -u

BRIEF=0
[ "${1:-}" = "--brief" ] && BRIEF=1

dir="$PWD"
crew=""
root=""
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  if [ -f "$dir/.crew/board.md" ]; then crew="$dir/.crew"; root="$dir"; break; fi
  dir="$(dirname "$dir")"
done

if [ -z "$crew" ]; then
  [ "$BRIEF" = 1 ] && exit 0
  echo "Keine Crew in diesem Verzeichnis (kein .crew/board.md gefunden)."
  exit 0
fi

board="$crew/board.md"

if [ "$BRIEF" = 1 ]; then
  offen=$(grep -c -E '\| (offen|läuft|ready|blockiert) ' "$board" || true)
  if [ "$offen" -gt 0 ]; then
    echo "Crew läuft in $root: $offen Ticket(s) offen. Stand mit /agent-crew:board."
  fi
  exit 0
fi

echo "Crew in $root"
echo
cat "$board"
echo

if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Arbeiter-Branches (letzte Änderung zuoberst):"
  git -C "$root" for-each-ref --sort=-committerdate \
    --format='  %(refname:short)  %(committerdate:relative)  %(subject)' refs/heads/wk/ 2>/dev/null || true
  echo
  echo "Hängende Kandidaten (Branch seit über 30 Minuten ohne Commit):"
  haengt=0
  now=$(date +%s)
  while read -r ref ts; do
    [ -n "$ref" ] || continue
    alter=$(( (now - ts) / 60 ))
    if [ "$alter" -gt 30 ]; then
      echo "  ${ref#refs/heads/} – seit $alter Minuten kein Commit"
      haengt=1
    fi
  done <<EOF
$(git -C "$root" for-each-ref --format='%(refname) %(committerdate:unix)' refs/heads/wk/ 2>/dev/null)
EOF
  [ "$haengt" = 0 ] && echo "  keine"
  echo
fi

echo "Tickets:"
for t in $(ls "$crew/tickets" 2>/dev/null); do
  rd="-"; ev="-"
  [ -f "$crew/tickets/$t/rd.md" ] && rd="ok"
  [ -f "$crew/tickets/$t/eval.md" ] && ev="ok"
  printf '  %-14s rd.md %-3s eval.md %s\n' "$t" "$rd" "$ev"
done
