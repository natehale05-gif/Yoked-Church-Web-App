#!/usr/bin/env bash
# Start the Firestore emulator, run the security-rule suite against it,
# and shut it down. One command rather than a remembered two-terminal
# dance, because rules that are annoying to test stop getting tested.
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -d node_modules ]; then
  echo "Installing test dependencies..."
  # `ci` when there's a lockfile, so CI installs exactly what was tested.
  if [ -f package-lock.json ]; then
    npm ci --no-audit --no-fund
  else
    npm install --no-audit --no-fund
  fi
fi

# `--project demo-*` keeps the emulator from asking for credentials or
# touching a real project.
exec npx --yes firebase-tools emulators:exec \
  --only firestore \
  --project demo-yoked-church \
  --config ../firebase.json \
  "node $(pwd)/rules.test.js"
