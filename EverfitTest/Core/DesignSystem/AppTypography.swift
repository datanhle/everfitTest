import SwiftUI

/// Every text style in the app (Figma specs), applied with `.textStyle(_:)`.
enum AppTypography {
    /// "MON" — Open Sans 700, 12px, line height 20px, letter spacing 0.3px.
    static let weekday = AppTextStyle(size: 12, weight: .bold, lineHeight: 20, letterSpacing: 0.3)
    /// "20" — Open Sans 400, 16px, line height 24px.
    static let dayNumber = AppTextStyle(size: 16, weight: .regular, lineHeight: 24)
    /// Workout name — Open Sans 700, 15px, line height 100%, layer height 20px.
    static let workoutTitle = AppTextStyle(size: 15, weight: .bold, lineHeight: 15, layoutHeight: 20)
    /// "Missed • 5 exercises" — Open Sans 400, 13px, line height 100%, layer height 18px.
    static let workoutDetail = AppTextStyle(size: 13, weight: .regular, lineHeight: 13, layoutHeight: 18)
    /// "Loading…" next to the spinner — not in Figma; same size as the day number, natural line height.
    static let loading = AppTextStyle(size: 16, weight: .regular)
}
