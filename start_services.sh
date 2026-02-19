#!/bin/bash
# macOS-only launcher: open Terminal windows and run POSIX scripts.
echo "Starting PCS Services (macOS)..."

# Resolve repository directory (script location)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$REPO_DIR" || exit 1

# Start server: require a POSIX script run_server.sh (no .bat fallbacks on macOS)
if [ -x "./run_server.sh" ]; then
  osascript <<EOF
tell application "Terminal"
  do script "cd \"$REPO_DIR\" && ./run_server.sh"
end tell
EOF
else
  echo "Warning: run_server.sh not found or not executable. Skipping server start."
  osascript <<EOF
tell application "Terminal"
  do script "cd \"$REPO_DIR\"; echo 'run_server.sh not found. Create a POSIX script to start the server.'; exec $SHELL"
end tell
EOF
fi

sleep 5

# Start ngrok: require a POSIX script run_ngrok.sh (no .bat fallbacks on macOS)
if [ -x "./run_ngrok.sh" ]; then
  osascript <<EOF
tell application "Terminal"
  do script "cd \"$REPO_DIR\" && ./run_ngrok.sh"
end tell
EOF
else
  echo "Warning: run_ngrok.sh not found or not executable. Skipping ngrok start."
  osascript <<EOF
tell application "Terminal"
  do script "cd \"$REPO_DIR\"; echo 'run_ngrok.sh not found. Create a POSIX script to start ngrok (or install ngrok and create a small wrapper).'; exec $SHELL"
end tell
EOF
fi

echo "Done. Opened Terminal windows as needed."
exit 0
