#!/bin/bash
# PostToolUse hook (Edit|Write): checks the hard project rules on the app Swift file Claude just changed.
# Exit 2 sends the violations back to Claude, which must fix them before going on.
# The rules themselves are written in .claude/rules/*.md.

file=$(jq -r '.tool_input.file_path // empty')
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$file" in "$root"/EverfitTest/*.swift) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0
rel=${file#"$root"/}

violations=""
add() { violations+="- $1"$'\n'; }
# Numbered code lines before `#Preview` (previews may use sample literals), comment lines dropped.
code=$(awk '/^#Preview/{exit} {print}' "$file" | grep -nv '^[[:space:]]*//')
find_lines() { printf '%s\n' "$code" | grep -E "$1" | cut -d: -f1 | paste -sd, -; }
check() { # check <regex> <message>
    local lines; lines=$(find_lines "$1")
    [ -n "$lines" ] && add "line $lines: $2"
}

# --- Layering (architecture.md) ---
case "$rel" in EverfitTest/Domain/*)
    check '^[0-9]+:import (SwiftUI|SwiftData|Alamofire|UIKit|Combine)' "Domain imports Foundation only (no SwiftUI/SwiftData/Alamofire/UIKit)." ;;
esac
case "$rel" in EverfitTest/Core/Networking/Client/*|EverfitTest/Core/Networking/Interceptors/*|EverfitTest/Core/Networking/Monitoring/*) ;;
    *) check '^[0-9]+:import Alamofire' "Alamofire is imported only in Core/Networking/{Client,Interceptors,Monitoring}; use NetworkClient/APIRequest/APIError." ;;
esac
case "$rel" in EverfitTest/Data/*) ;;
    *) check '^[0-9]+:import SwiftData' "SwiftData is used only in Data/ (repository + @Model); other layers see Domain types." ;;
esac

# --- Concurrency & safety (swift-code.md) ---
check '^[0-9]+:import Combine' "No Combine: use async/await."
case "$rel" in EverfitTest/Core/Networking/Monitoring/*) ;;
    *) check 'DispatchQueue' "No DispatchQueue/completion handlers: use async/await (.task, Task, actors)." ;;
esac
case "$rel" in EverfitTest/Core/Utilities/SystemDateProvider.swift) ;;
    *) check '([^A-Za-z_.]|^[0-9]+:)Date\(\)' "Never call Date() in app code: inject DateProvider and use .now." ;;
esac
check 'try!|[[:space:]]as![[:space:]]' "No try! / as! in app code: handle the error or use a safe cast."

# --- No hard-coded UI values in Views (design-system.md) ---
case "$rel" in EverfitTest/Features/*/Views/*)
    check '([^A-Za-z]|^[0-9]+:)Color\(|Color\.[a-z]+' "Colors only from AppColors.*."
    check '\.font\(|Font\.system|\.system\(size' "Text styles only via .textStyle(AppTypography.*)."
    check '\.padding\(([^)]*,)?[[:space:]]*[0-9]' "Padding only from AppSpacing.*."
    check '(width|height|minWidth|minHeight|maxWidth|maxHeight|spacing|minLength|cornerRadius|radius):[[:space:]]*[1-9]' "Sizes/spacing/radius only from AppSpacing.* (0 and .infinity are fine)."
    check '(Text|Button|Label|Toggle|Link)\("[^\\]' "User-facing text only from AppStrings.*."
    check 'Image\((systemName:[[:space:]]*)?"' "Icons only from AppIcons.*."
    ;;
esac

# --- Logic must have unit tests (unit-testing.md) ---
case "$rel" in
EverfitTest/Domain/*|EverfitTest/Data/*|EverfitTest/Core/Networking/*|EverfitTest/Features/*/ViewModels/*|EverfitTest/Features/*/Mappers/*)
    types=$(grep -Eo '^[[:space:]]*((nonisolated|final|private|fileprivate|public|internal|@[A-Za-z]+)[[:space:]]+)*(struct|class|enum|protocol|extension|actor)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' "$file" | awk '{print $NF}' | sort -u)
    # Pure data, protocol-only or infrastructure types, and types whose logic is tested through another unit.
    exempt=" DayPlan Workout WorkoutStatus ScheduledDay ScheduledWorkout CachedResponse CompletionRecord RequestMethod RequestEncoding APIResponse APIErrorResponse NetworkClient DefaultInterceptor NetworkLogger APIConstants WorkoutRepository DateProvider "
    tested=""; checked=""
    for type in $types; do
        [[ "$exempt" == *" $type "* ]] && continue
        checked+="$type "
        # Substring match: tests may use the Default… implementation of a protocol.
        grep -rq "$type" "$root/EverfitTests" && tested=yes
    done
    if [ -n "$checked" ] && [ -z "$tested" ]; then
        add "No unit test references ${checked% }. Add EverfitTests/<Layer>/<Type>Tests.swift with the cases from its component-type template in .claude/rules/unit-testing.md (\"Test cases by component type\") plus the 7 required categories."
    fi ;;
esac

[ -z "$violations" ] && exit 0
{
    echo "Project rule violations in $rel — fix them now (see .claude/rules/):"
    printf '%s' "$violations"
} >&2
exit 2
