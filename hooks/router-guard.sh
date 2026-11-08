#!/usr/bin/env bash
# Crew-Wächter: der Router darf schreiben, wo Koordination hingehört – sonst nirgends.
#
# Läuft als PreToolUse-Hook auf Write|Edit|NotebookEdit. Drei Bedingungen müssen alle zutreffen,
# damit blockiert wird:
#   1. Im aktuellen Projekt läuft eine Crew (.crew/board.md existiert).
#   2. Der Aufruf kommt NICHT aus einem Subagenten (kein agent_id im Hook-Eingabe-JSON).
#      Arbeiter sind Subagenten und dürfen Code schreiben – sie werden nie blockiert.
#   3. Die Zieldatei liegt ausserhalb von .crew/.
#
# Bei jedem Fehler (kein jq, kein python3, unlesbares JSON) gibt der Wächter auf: er blockiert
# nichts, was er nicht sicher beurteilen kann. Ein Wächter, der den Lauf kaputt macht, ist
# schlimmer als keiner.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIELD="$HERE/../scripts/hook-field.py"
input="$(cat)"

read_field() {
  if command -v python3 >/dev/null 2>&1 && [ -f "$FIELD" ]; then
    printf '%s' "$input" | python3 "$FIELD" "$1" 2>/dev/null
  elif command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r "$2 // empty" 2>/dev/null
  fi
}

agent_id="$(read_field agent_id '.agent_id')"
[ -n "$agent_id" ] && exit 0          # Arbeiter: nie blockieren

cwd="$(read_field cwd '.cwd')"
[ -n "$cwd" ] || exit 0
[ -f "$cwd/.crew/board.md" ] || exit 0  # keine Crew in diesem Projekt: nichts zu bewachen

target="$(read_field tool_input.file_path '.tool_input.file_path')"
[ -n "$target" ] || exit 0

case "$target" in
  /*) ;;
  *) target="$cwd/$target" ;;
esac

case "$target" in
  "$cwd/.crew"/*|"$cwd/.crew") exit 0 ;;
esac

echo "Crew-Wächter: Der Router schreibt keinen Feature-Code. '$target' liegt ausserhalb von .crew/." \
     "Schreibe stattdessen ein Ticket (.crew/tickets/<name>/rd.md) und starte einen Arbeiter" \
     "(Subagent agent-crew:worker) – der darf ins Projekt schreiben. Erlaubt sind für dich nur" \
     "Dateien unter .crew/." >&2
exit 2
