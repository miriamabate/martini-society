#!/usr/bin/env bash
# Applica le migrazioni in supabase/migrations (una volta sola ciascuna) e imposta la parola d'ordine.
# Variabili: DATABASE_URL (obbligatoria), CLUB_PASSWORD (facoltativa: se c'è, sostituisce quella attuale)
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

if [ -n "${CLUB_PASSWORD:-}" ]; then
  "${PSQL[@]}" -v pw="$CLUB_PASSWORD" <<'SQL'
begin;
delete from private.club;
insert into private.club values (:'pw');
commit;
SQL
  echo "✓ parola d'ordine impostata"
fi

"${PSQL[@]}" -c "notify pgrst, 'reload schema';"
echo "✓ database aggiornato"
