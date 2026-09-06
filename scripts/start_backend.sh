#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR/backend"

# Load .env if present
if [ -f "$DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$DIR/.env"
    set +a
elif [ -f "$DIR/backend/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$DIR/backend/.env"
    set +a
fi

# If using local postgres, ensure local cluster is running
if [[ -z "$DATABASE_URL" || "$DATABASE_URL" == *"localhost"* || "$DATABASE_URL" == *"127.0.0.1"* ]]; then
    "$DIR/scripts/start_postgres.sh"
else
    echo "Using configured remote cloud database."
fi

HOST="${BACKEND_HOST:-0.0.0.0}"
PORT="${BACKEND_PORT:-8000}"

echo "Starting RoomieSplit FastAPI backend on http://$HOST:$PORT ..."
PYTHONPATH=. "$DIR/backend/.venv/bin/uvicorn" app.main:app --host "$HOST" --port "$PORT" --reload
