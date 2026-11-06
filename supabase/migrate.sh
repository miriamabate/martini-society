#!/usr/bin/env bash
# Applica le migrazioni in supabase/migrations (una volta sola ciascuna) e aggiorna la lista delle email del club.
# Variabili: DATABASE_URL (obbligatoria), CLUB_EMAILS (email ammesse, separate da virgola: sostituisce la lista attuale)
set -euo pipefail
: "${DATABASE_URL:?Manca DATABASE_URL (secret SUPABASE_DB_URL)}"
DIR="$(cd "$(dirname "$0")" && pwd)"
export PGOPTIONS="${PGOPTIONS:-} -c client_min_messages=warning"
PSQL=(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1)

"${PSQL[@]}" -c "create schema if not exists private;
  create table if not exists private.migrations (name text primary key, applied_at timestamptz not null default now());"

for f in "$DIR"/migrations/*.sql; do
  n="$(basename "$f")"
  if [ "$("${PSQL[@]}" -tAc "select 1 from private.migrations where name = '$n'")" = "1" ]; then
    echo "✓ $n già applicata"
  else
    echo "→ applico $n"
    "${PSQL[@]}" --single-transaction -f "$f" -c "insert into private.migrations (name) values ('$n')"
  fi
done

if [ -n "${CLUB_EMAILS:-}" ]; then
  emails="$(printf '%s' "$CLUB_EMAILS" | tr ',; ' '\n\n\n' | tr 'A-Z' 'a-z' | grep -E '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$' | sort -u || true)"
  if [ -z "$emails" ]; then echo "✗ CLUB_EMAILS non contiene email valide" >&2; exit 1; fi
  {
    echo "begin; delete from private.members;"
    while IFS= read -r e; do printf "insert into private.members values ('%s');\n" "$e"; done <<< "$emails"
    echo "commit;"
  } | "${PSQL[@]}"
  echo "✓ lista del club aggiornata: $(printf '%s\n' "$emails" | wc -l | tr -d ' ') email"
fi

"${PSQL[@]}" -c "notify pgrst, 'reload schema';"
echo "✓ database aggiornato"
