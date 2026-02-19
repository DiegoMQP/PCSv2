#!/usr/bin/env bash
set -e
# Simple POSIX launcher to compile and run the Java server using Maven.
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

MVN_CMD="mvn"
if [ -n "$MAVEN_HOME" ]; then
  MVN_CMD="$MAVEN_HOME/bin/mvn"
fi

echo "Starting PCS Server (POSIX)..."
echo "Using mvn: $MVN_CMD"

if ! command -v "$MVN_CMD" >/dev/null 2>&1; then
  echo "Warning: mvn not found in PATH or MAVEN_HOME. Please install Maven or set MAVEN_HOME."
fi

"$MVN_CMD" compile exec:java -Dexec.mainClass="Server.Main"

echo "Server process finished."
read -r -p "Press Enter to exit..."
