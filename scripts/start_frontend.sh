#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR/frontend"

if [ -f "$DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$DIR/.env"
    set +a
fi

API_BASE_URL="${FRONTEND_API_BASE_URL:-http://localhost:8000/api}"

# Check if desktop or web
if [ "$1" = "web" ]; then
    echo "Starting Flutter Web on http://localhost:3000 ..."
    flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 --dart-define=API_BASE_URL="$API_BASE_URL"
else
    echo "Starting Flutter on Linux desktop..."
    flutter run -d linux --dart-define=API_BASE_URL="$API_BASE_URL"
fi
