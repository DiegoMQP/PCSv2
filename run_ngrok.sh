#!/usr/bin/env bash
set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo "Starting ngrok on port 7070..."
if ! command -v ngrok >/dev/null 2>&1; then
  echo "ngrok not found in PATH. Please install ngrok and ensure it is available as 'ngrok'."
  exit 1
fi

ngrok http 7070
