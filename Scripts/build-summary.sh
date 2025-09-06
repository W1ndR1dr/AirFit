#!/usr/bin/env bash
set -euo pipefail

# Minimal build wrapper: generates project, stores full logs, prints summary only.

SCHEME=${SCHEME:-AirFit}
DEST=${DEST:-platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4}
LOGDIR=${LOGDIR:-logs}
mkdir -p "$LOGDIR"
STAMP=$(date +%Y%m%d-%H%M%S)
LOGFILE="$LOGDIR/build-$STAMP.log"

echo "Generating project..."
xcodegen generate >/dev/null 2>&1 || true

echo "Building $SCHEME @ $DEST (logging to $LOGFILE)"
if xcodebuild build -scheme "$SCHEME" -destination "$DEST" >"$LOGFILE" 2>&1; then
  WARN=$(rg -c "warning:" "$LOGFILE" || true)
  echo "BUILD PASSED (warnings: ${WARN:-0})"
else
  ERR=$(rg -c "error:" "$LOGFILE" || true)
  echo "BUILD FAILED (errors: ${ERR:-?}) — see $LOGFILE"
fi

