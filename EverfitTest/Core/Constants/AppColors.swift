import SwiftUI

/// Single source of truth for every color in the app.
/// Text, brand and card colors are Figma specs; `screenBackground` and `divider` were measured from the screenshot.
enum AppColors {
    // MARK: Brand
    /// Today's date, completed workout card.
    static let primary = Color(hex: 0x7470EF)

    // MARK: Backgrounds
    static let screenBackground = Color(hex: 0xFFFFFF)
    static let cardBackground = Color(hex: 0xF7F8FC)
    static let divider = Color(hex: 0xEEEFF4)

    // MARK: Text
    /// Day number, workout title, exercise count ("7 exercises").
    static let textPrimary = Color(hex: 0x1E0A3C)
    /// Weekday "MON".
    static let textSecondary = Color(hex: 0x7B7E91)
    /// Future (upcoming) workouts.
    static let textDisabled = Color(hex: 0x7B7E91)
    /// Text and check badge on the purple completed card.
    static let textOnPrimary = Color(hex: 0xFFFFFF)

    // MARK: Workout status
    /// "Missed" label.
    static let statusMissed = Color(hex: 0xFF5E5E)
}
