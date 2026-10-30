import SwiftUI

/// Maps a schedule status to the workout card's look. The only place status → color/text lives.
///
/// Per Figma: assigned (today, not done) shows no status word and completed shows only "Completed";
/// VoiceOver still reads the status and the exercise count for every card.
///
/// | Status    | Card    | Title    | Subtitle                               |
/// |-----------|---------|----------|----------------------------------------|
/// | assigned  | grey    | dark     | "7 exercises"                          |
/// | missed    | grey    | dark     | "Missed" (red) • "5 exercises"         |
/// | completed | purple  | white    | "Completed" (white)                    |
/// | upcoming  | grey    | grey     | "6 exercises" (grey, no status word)   |
extension ScheduleStatus {
    /// Status word shown before the exercise count; assigned and future workouts have none (Figma).
    var label: String? {
        switch self {
        case .missed: AppStrings.Status.missed
        case .completed: AppStrings.Status.completed
        case .assigned, .upcoming: nil
        }
    }

    /// Completed cards show only "Completed" (Figma).
    var showsExerciseCount: Bool { self != .completed }

    var cardBackground: Color {
        self == .completed ? AppColors.primary : AppColors.cardBackground
    }

    var titleColor: Color {
        switch self {
        case .completed: AppColors.textOnPrimary
        case .upcoming: AppColors.textDisabled
        case .assigned, .missed: AppColors.textPrimary
        }
    }

    var labelColor: Color {
        self == .missed ? AppColors.statusMissed : titleColor
    }

    var detailColor: Color { titleColor }

    /// Read by VoiceOver for every status, including the ones with no visible label.
    var accessibilityName: String {
        switch self {
        case .assigned: AppStrings.Status.assigned
        case .completed: AppStrings.Status.completed
        case .missed: AppStrings.Status.missed
        case .upcoming: AppStrings.Status.upcoming
        }
    }
}
