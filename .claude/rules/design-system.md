---
paths:
  - "EverfitTest/Features/**/*.swift"
  - "EverfitTest/Core/DesignSystem/**"
  - "EverfitTest/Core/Constants/**"
  - "EverfitTest/Resources/**"
---

# Design system — no hard-coded UI values

> **Hard rules — MUST be followed, never "just this once".** Items marked 🔒 are checked by `.claude/hooks/check-swift-rules.sh` after every Edit/Write; a violation is sent back and must be fixed before continuing.

🔒 Enforced in `Features/*/Views/` (code before `#Preview`): no `Color(...)`/`Color.x`, `.font(...)`, numeric `.padding`, numeric width/height/spacing/radius (0 and `.infinity` allowed), literal `Text("…")`/`Button("…")`, literal `Image(systemName: "…")`.

## Tokens — the only sources of UI values
| Value | Use only | File |
|---|---|---|
| Color | `AppColors.*` | `Core/Constants/AppColors.swift` |
| Text style (font, size, line height, tracking) | `.textStyle(AppTypography.*)` | `Core/DesignSystem/AppTypography.swift` |
| Spacing, padding, size, radius | `AppSpacing.*`, screen metrics in `AppSpacing.<Feature>` | `Core/DesignSystem/AppSpacing.swift` |
| Icon / image name | `AppIcons.*` | `Core/DesignSystem/AppIcons.swift` |
| User-facing text (incl. accessibility, errors) | `AppStrings.<Area>.*` (`String(localized:)`) | `Core/Constants/AppStrings.swift` |

- Need a value that does not exist? **Add the token first** (named by meaning, not by value: `cardBackground`, not `grey100`), with a doc comment citing its Figma source, then use it.
- Reuse an existing token when the design value matches; never add a near-duplicate.
- Remove tokens that are no longer used.
- `#Preview` blocks may use sample literals (titles, counts) for sample data only.

## Building a new screen from Figma
1. Get the frame(s) for every state: loaded, loading, empty, error, and each item status.
2. Read **both Typography and Layout** in Dev Mode Inspect for each text layer. A layer can have a fixed height taller than its line → set `layoutHeight` on the style; spacing measured in Figma is between layers, not lines.
3. Map every value to an existing token or add one; screen-specific metrics go in `AppSpacing.<Feature>`.
4. Build Views from UI models (`<Thing>Item`) produced by the feature's presentation mapper; status → color/label lives in a `<Status>+Style.swift` extension in the feature's `Mappers/`, the only place that maps status to look.
5. States: first load shows the screen's structure with the shared `LoadingIndicator` as an `.overlay` on top of it (never blank); reloads keep content and use pull-to-refresh; error shows an alert (`AppStrings.Errors`), keeping current content; empty shows the structure with no items. Reuse shared components from `Core/DesignSystem` (e.g. `LoadingIndicator`) instead of building per-screen versions.
6. Accessibility: combine related labels into one element; VoiceOver reads every meaningful value even when the design hides it visually; tappable cards get a hint and the button trait, read-only ones do not.
7. Verify against the design on the simulator (below) for each state.

## Typography (`AppTextStyle`)
- Every label uses `.textStyle(AppTypography.x)`, never `.font(...)`. A style = font weight + size + line height + letter spacing + optional `layoutHeight`.
- Fonts in `Resources/Fonts` are registered at runtime via CoreText (no Info.plist `UIAppFonts`); only the bundled weights exist (Open Sans Regular 400, Bold 700) — add the file before using another weight. Use CoreText, not UIKit: the target also builds for macOS/visionOS.
- Line height `nil` = Figma "Auto" (font's natural height, ≈136% for Open Sans). A smaller line height trims the line box evenly above/below, like Figma.

## Layout notes
- A SwiftUI `ScrollView` draws into the safe area; `.clipped()` (before `.background`) keeps content out of the status bar while the background stays full-screen.
- Verify UI: build, then `xcrun simctl launch "iPhone 17" datleanh.com.EverfitTest` and `xcrun simctl io "iPhone 17" screenshot <png>`. Screenshots are 3x (≈2.29 px/pt at 920px display width). Terminate the app before running UI tests.
- Design source for the app: Figma file `APChc5i8CKTSn7CZg7Gg36`. The Figma MCP is view-only here (`create_session`/`get_design_context` fail), so values come from the user's Dev Mode Inspect.
