#!/usr/bin/env bash
set -euo pipefail

RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
NC=$(printf '\033[0m')

fail() { echo "${RED}CI Guard Failed:${NC} $*"; exit 1; }
warn() { echo "${YELLOW}CI Guard Warning:${NC} $*"; }
pass() { echo "${GREEN}✓${NC} $*"; }

# Guard 1: No force ops in app target (allow tests and previews)
echo "Checking for force operations..."
FORCE_OPS=$(rg -n --no-heading --glob 'AirFit/**/*.swift' 'try!| as!| !\.' \
  -g '!AirFit/**/Tests/**' -g '!AirFit/**/test/**' \
  -g '!AirFit/Services/ExerciseDatabase.swift' \
  -S | \
  rg -v '#Preview|swiftlint:disable:this force_try' || true)
if [ -n "$FORCE_OPS" ]; then
  echo "$FORCE_OPS"
  fail "Force operations detected in app sources. Replace try!/as!/!. with safe handling."
fi
pass "No force operations found"

# Guard 2: No ad-hoc ModelContainer creation outside allowed files
echo "Checking for ad-hoc ModelContainer creation..."
MODEL_CONTAINERS=$(rg -n --no-heading --glob 'AirFit/**/*.swift' 'ModelContainer\s*\(' -S \
  -g '!AirFit/Application/**' \
  -g '!AirFit/AirFitTests/**' \
  -g '!AirFit/**/Previews/**' \
  -g '!AirFit/Services/ExerciseDatabase.swift' || true)
if [ -n "$MODEL_CONTAINERS" ]; then
  echo "$MODEL_CONTAINERS"
  fail "Ad-hoc ModelContainer creation detected outside allowed locations."
fi
pass "No ad-hoc ModelContainer creation found"

# Guard 3: No NotificationCenter for chat streaming in AI/Chat modules
echo "Checking for NotificationCenter usage in chat streaming..."
CHAT_NOTIFY=$(rg -n --no-heading -S \
  '(NotificationCenter\.default\.(post|addObserver))' \
  AirFit/Modules/AI AirFit/Modules/Chat 2>/dev/null || true)
if [ -n "$CHAT_NOTIFY" ]; then
  echo "$CHAT_NOTIFY"
  fail "Chat streaming must use ChatStreamingStore; remove NotificationCenter coupling."
fi
pass "No NotificationCenter coupling in chat streaming"

# Guard 4: No SwiftData import in Modules' Views/ViewModels
echo "Checking for SwiftData imports in UI layers..."
SWIFTDATA_UI=$(rg -n --no-heading -S 'import\s+SwiftData' \
  AirFit/Modules/**/Views AirFit/Modules/**/ViewModels 2>/dev/null || true)
if [ -n "$SWIFTDATA_UI" ]; then
  echo "$SWIFTDATA_UI"
  fail "SwiftData import not allowed in UI/ViewModels; use repositories/services."
fi
pass "No SwiftData imports in UI layers"

# Guard 5: Require @MainActor on ViewModels
echo "Checking for @MainActor on ViewModels..."
VM_NO_MAIN=$(rg -n --no-heading -S 'class\s+\w+ViewModel' AirFit/Modules/**/ViewModels 2>/dev/null \
  | rg -v '@MainActor' || true)
if [ -n "$VM_NO_MAIN" ]; then
  echo "$VM_NO_MAIN"
  fail "ViewModels must be @MainActor."
fi
pass "All ViewModels have @MainActor"

# Guard 6: Networking must go through NetworkClientProtocol
echo "Checking for direct URLSession usage..."
RAW_NETWORK=$(rg -n --no-heading -S 'URLSession\.|dataTask\(' AirFit \
  -g '!AirFit/Services/Network/**' -g '!AirFit/**/Tests/**' 2>/dev/null || true)
if [ -n "$RAW_NETWORK" ]; then
  echo "$RAW_NETWORK"
  fail "Use NetworkClientProtocol; do not call URLSession directly."
fi
pass "No direct URLSession usage found"

# Guard 7: No hardcoded API keys or secrets
echo "Checking for hardcoded secrets..."
SECRETS=$(rg -n --no-heading -S 'sk-|api_key.*=|Bearer [A-Za-z0-9]' AirFit \
  -g '!AirFit/**/Tests/**' -g '!AirFit/**/Previews/**' 2>/dev/null || true)
if [ -n "$SECRETS" ]; then
  echo "$SECRETS"
  fail "Hardcoded secrets detected. Use APIKeyManager and Keychain."
fi
pass "No hardcoded secrets found"

echo ""
echo "${GREEN}All CI guards passed successfully!${NC}"
