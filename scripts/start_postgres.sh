#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

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

PG_DIR="$HOME/.roomie_postgres_data"
PG_BIN_DIR=""

if [ -d "/usr/lib/postgresql/18/bin" ]; then
    PG_BIN_DIR="/usr/lib/postgresql/18/bin"
elif [ -d "/usr/lib/postgresql/16/bin" ]; then
    PG_BIN_DIR="/usr/lib/postgresql/16/bin"
else
    PG_BIN_DIR="/usr/bin"
fi

PORT="${POSTGRES_PORT:-5433}"
DB_NAME="${POSTGRES_DB:-roomie_db}"
DB_USER="${POSTGRES_USER:-$USER}"
export PGPASSWORD="${POSTGRES_PASSWORD:-}"

if [ ! -d "$PG_DIR" ]; then
    echo "Initializing PostgreSQL cluster at $PG_DIR..."
    "$PG_BIN_DIR/initdb" -D "$PG_DIR" -U "$DB_USER" --auth-local=trust --auth-host=trust
fi

# Check if postgres is already running on port
if "$PG_BIN_DIR/pg_isready" -p "$PORT" -h localhost >/dev/null 2>&1; then
    echo "PostgreSQL is already running on port $PORT."
else
    echo "Starting PostgreSQL on port $PORT..."
    "$PG_BIN_DIR/pg_ctl" -D "$PG_DIR" -o "-p $PORT -k /tmp" -l "$PG_DIR/logfile.log" start
    sleep 2
fi

# Create database if not exists
if ! "$PG_BIN_DIR/psql" -h localhost -p "$PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo "Creating database $DB_NAME..."
    "$PG_BIN_DIR/createdb" -h localhost -p "$PORT" -U "$DB_USER" "$DB_NAME"
fi

echo "PostgreSQL is ready on localhost:$PORT with database '$DB_NAME'."
