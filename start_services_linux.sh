#!/usr/bin/env bash
# Start server and ngrok in separate terminals on Linux (or any X11 desktop)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR" || exit 1

echo "Starting PCS services (Linux)..."

# helper to open a new terminal running a command and keep it open
open_terminal() {
  local cmd="$1"
  if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal -- bash -lc "cd '$REPO_DIR' && $cmd; exec bash" &
  elif command -v konsole >/dev/null 2>&1; then
    konsole -e bash -c "cd '$REPO_DIR' && $cmd; exec bash" &
  elif command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal --command="bash -c 'cd '$REPO_DIR' && $cmd; exec bash'" &
  elif command -v xterm >/dev/null 2>&1; then
    xterm -hold -e "bash -c 'cd '$REPO_DIR' && $cmd'" &
  else
    # Fallback: run in background in same shell
    bash -lc "cd '$REPO_DIR' && $cmd" &
  fi
}

if [ -x "$REPO_DIR/run_server.sh" ]; then
  open_terminal "./run_server.sh"
else
  echo "run_server.sh not found or not executable. Create it to start the server."
fi

sleep 3

if [ -x "$REPO_DIR/run_ngrok.sh" ]; then
  open_terminal "./run_ngrok.sh"
else
  echo "run_ngrok.sh not found or not executable. Create it to start ngrok."
fi

echo "Start commands issued."
exit 0
