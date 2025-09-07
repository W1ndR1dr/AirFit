#!/usr/bin/env bash
set -euo pipefail

ROOT=${1:-"AirFit"}

echo "== Status Snapshot (quick) =="

echo "-- Force ops in app target --"
rg -n "try!| as!|[^\"]!\W" "$ROOT" -S -g '!**/Tests/**' -g '!**/Previews/**' || true

echo "-- Ad-hoc ModelContainer calls --"
rg -n "ModelContainer\s*\(" "$ROOT" -S -g '!**/Tests/**' -g '!**/Previews/**' || true

echo "-- SwiftData imports in UI/ViewModels --"
rg -n "^import\s+SwiftData" "$ROOT/Modules" -S || true

echo "-- NotificationCenter usage in Chat/AI --"
rg -n "NotificationCenter\.default\.(post|addObserver|publisher)" "$ROOT/Modules/Chat" "$ROOT/Modules/AI" -S || true

echo "== Done =="

