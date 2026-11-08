#!/usr/bin/env python3
"""Ein Feld aus dem Hook-Eingabe-JSON holen, ohne jq.

Aufruf:  echo "$hook_json" | hook-field.py file_path
         echo "$hook_json" | hook-field.py agent_id
Gibt den Wert aus, oder nichts (Exit 1), wenn das Feld fehlt. Bewusst nachsichtig: bei kaputtem
JSON oder nicht unterstütztem Pfad gibt es nichts aus, damit der Wächter im Zweifel nicht blockiert.
"""
import json
import sys


def main() -> int:
    if len(sys.argv) < 2:
        return 1
    path = sys.argv[1].split(".")
    if any(not p or p.startswith("_") for p in path):
        return 1
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 1
    for key in path:
        if isinstance(data, dict) and key in data:
            data = data[key]
        else:
            return 1
    if data is None or isinstance(data, (dict, list)):
        return 1
    print(data)
    return 0


if __name__ == "__main__":
    sys.exit(main())
