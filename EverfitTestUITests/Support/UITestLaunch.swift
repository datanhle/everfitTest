import XCTest

extension XCUIApplication {
    /// Launches the app the way every UI test needs it (`.claude/rules/ui-testing.md`):
    /// in-memory store (no cache, no toggles from earlier runs), English text,
    /// en_US locale (weeks start on Sunday there, so the test also proves the app stays Monday-first).
    @MainActor
    static func launchForUITesting() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }
}
