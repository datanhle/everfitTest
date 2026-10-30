/// Accessibility identifiers used by UI tests to find elements (`.claude/rules/ui-testing.md`).
/// Not shown or read to the user. Mirrored as plain strings in `EverfitTestUITests/Support`.
nonisolated enum AppAccessibilityID {
    static let loading = "common.loading"

    enum Calendar {
        static let dayDate = "calendar.dayDate"

        /// One card per workout, keyed by its API `_id`.
        static func workout(_ id: String) -> String {
            "calendar.workout.\(id)"
        }
    }
}
