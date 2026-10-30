import XCTest

/// Page object for the calendar screen: every query and wait the UI tests need.
/// Identifiers mirror `AppAccessibilityID` in the app.
@MainActor
struct CalendarScreen {
    static let timeout: TimeInterval = 15

    let app: XCUIApplication

    var dates: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "calendar.dayDate")
    }

    var loading: XCUIElement {
        app.descendants(matching: .any)["common.loading"]
    }

    func card(_ id: String) -> XCUIElement {
        app.descendants(matching: .any)["calendar.workout.\(id)"]
    }

    /// Tappable cards carry the button trait; read-only (future) cards do not.
    func isTappable(_ id: String) -> Bool {
        app.buttons["calendar.workout.\(id)"].exists
    }

    /// Waits until the first network load has filled the cards.
    func waitForWorkouts(_ workouts: [APIWorkout], file: StaticString = #filePath, line: UInt = #line) {
        guard let first = workouts.first else { return }
        XCTAssertTrue(card(first.id).waitForExistence(timeout: Self.timeout), "Cards never appeared", file: file, line: line)
    }

    /// Scrolls down (the list is lazy: off-screen rows are not in the hierarchy) until `element` is on screen.
    @discardableResult
    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 8) -> XCUIElement {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < maxSwipes {
            app.swipeUp(velocity: .slow)
            swipes += 1
        }
        return element
    }

    /// Every date label (and its value) from top to bottom, collected while scrolling.
    func allDates() -> [(label: String, value: String)] {
        var seen: [(label: String, value: String)] = []
        for _ in 0...4 {
            for element in dates.allElementsBoundByIndex where element.exists {
                let label = element.label
                if !seen.contains(where: { $0.label == label }) {
                    seen.append((label, element.value as? String ?? ""))
                }
            }
            if seen.count == 7 { break }
            app.swipeUp(velocity: .slow)
        }
        return seen
    }

    /// Weekday text ("MON"…) of the row a card sits in: the last date that starts above the card's bottom edge.
    func weekdayText(ofRowContaining card: XCUIElement) -> String? {
        dates.allElementsBoundByIndex
            .filter { $0.exists && $0.frame.minY <= card.frame.maxY }
            .max { $0.frame.minY < $1.frame.minY }
            .flatMap { $0.label.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } }
    }

    /// Pull-to-refresh from the top of the list.
    func pullToRefresh() {
        let top = dates.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        top.press(forDuration: 0.1, thenDragTo: top.withOffset(CGVector(dx: 0, dy: 400)))
    }

    /// Waits until `element.label` equals `label`.
    func waitForLabel(_ element: XCUIElement, toBe label: String, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: Self.timeout)
        XCTAssertEqual(result, .completed, "Label is \"\(element.label)\", expected \"\(label)\"", file: file, line: line)
    }
}
