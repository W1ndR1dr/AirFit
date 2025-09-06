#!/usr/bin/env bash
set -euo pipefail

# AirFit dev audit: quick build/lint sanity and environment check
# Safe to run repeatedly; gracefully skips steps if tools are missing.

SCHEME=${SCHEME:-AirFit}
DEST=${DEST:-platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4}

echo "== Tooling check =="
for tool in xcodegen xcodebuild swiftlint rg; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "✔ $tool found"
  else
    echo "✘ $tool not found (skipping any steps that require it)"
  fi
done

echo
if command -v xcodegen >/dev/null 2>&1; then
  echo "== Generating Xcode project =="
  xcodegen generate
fi

echo
if command -v swiftlint >/dev/null 2>&1; then
  echo "== SwiftLint (strict) =="
  if swiftlint --strict --config AirFit/.swiftlint.yml AirFit AirFitWatchApp; then
    echo "SwiftLint passed"
  else
    echo "SwiftLint reported issues" >&2
  fi
fi

echo
if command -v xcodebuild >/dev/null 2>&1; then
  echo "== Building ($SCHEME @ $DEST) =="
  set +e
  if command -v xcpretty >/dev/null 2>&1; then
    xcodebuild build -scheme "$SCHEME" -destination "$DEST" | xcpretty --color || true
  else
    xcodebuild build -scheme "$SCHEME" -destination "$DEST" || true
  fi
  set -e
fi

echo
echo "== CI Guards Check =="
if [ -x Scripts/ci-guards.sh ]; then
  echo "Running CI guards..."
  Scripts/ci-guards.sh || echo "CI Guards reported violations (see above)"
else
  echo "CI guards script not found or not executable"
fi

echo
echo "== Repo summary =="
if command -v rg >/dev/null 2>&1; then
  echo "Swift files:" $(rg --files | rg "\.swift$" | wc -l | tr -d ' ')
  echo "Modules:" $(ls -1 AirFit/Modules 2>/dev/null | wc -l | tr -d ' ')
  echo "Test files:" $(rg --files | rg "Test.*\.swift$" | wc -l | tr -d ' ')
fi

echo "Done. Check logs/ directory for detailed reports."
