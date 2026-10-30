#!/bin/bash
# Stop hook: Claude may not finish a turn while the unit tests fail.
# Runs the suite only when Swift files changed since the last green run; exit 2 = keep working.

input=$(cat)
# Already continuing because of this hook: let Claude stop to avoid a loop.
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" || exit 0
stamp="$root/.git/claude-last-green-tests"

# Fingerprint of every Swift source and test file.
hash=$(find EverfitTest EverfitTests -name '*.swift' -type f -print0 | sort -z | xargs -0 shasum | shasum | cut -d' ' -f1)
[ -f "$stamp" ] && [ "$(cat "$stamp")" = "$hash" ] && exit 0

log=$(mktemp -t everfit-tests)
xcodebuild test -project EverfitTest.xcodeproj -scheme EverfitTest \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -only-testing:EverfitTestTests -parallel-testing-enabled NO >"$log" 2>&1
status=$?

if [ $status -eq 0 ] && grep -q 'TEST SUCCEEDED' "$log"; then
    echo "$hash" >"$stamp"
    rm -f "$log"
    exit 0
fi

{
    echo "Unit tests are failing — fix them before finishing (rules: .claude/rules/unit-testing.md)."
    grep -E 'error:|✘' "$log" | grep -v -e 'CoreData' -e 'SwiftData' -e '\[Network\]' | sort -u | head -30
    echo "Full log: $log"
    echo "If it is a simulator flake (\"Failed to create a bundle instance\", \"server died\"), rerun once."
} >&2
exit 2
