import SwiftUI

/// Full-width day row: date column on the left, workout cards on the right, divider at the bottom.
/// With no workouts (or while loading) only the date is shown, at the same row height.
struct DayCell: View {
    let day: DayItem
    /// Tap on a workout card; passes the workout's `_id`.
    let onTapWorkout: (String) -> Void

    private typealias Metrics = AppSpacing.Calendar

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.dateToCardsSpacing) {
            dateColumn
            VStack(spacing: Metrics.cardSpacing) {
                ForEach(day.workouts) { workout in
                    WorkoutRow(workout: workout) { onTapWorkout(workout.id) }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding([.leading, .top, .bottom], Metrics.rowPadding)
        .padding(.trailing, Metrics.rowTrailingPadding)
        .frame(maxWidth: .infinity, minHeight: Metrics.rowMinHeight, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            AppColors.divider.frame(height: Metrics.dividerHeight)
        }
    }

    private var dateColumn: some View {
        VStack(alignment: .leading, spacing: Metrics.dateLabelSpacing) {
            Text(day.weekdayText)
                .textStyle(AppTypography.weekday)
                .foregroundStyle(day.isToday ? AppColors.primary : AppColors.textSecondary)
            Text(day.dayNumberText)
                .textStyle(AppTypography.dayNumber)
                .foregroundStyle(day.isToday ? AppColors.primary : AppColors.textPrimary)
        }
        .padding(.top, Metrics.dateTopInset)
        .frame(width: Metrics.dateColumnWidth, alignment: .leading)
        .accessibilityElement(children: .combine)
        // Today is shown only by colour; VoiceOver (and UI tests) get it as a value.
        .accessibilityValue(day.isToday ? AppStrings.Accessibility.today : "")
        .accessibilityIdentifier(AppAccessibilityID.Calendar.dayDate)
    }
}

#Preview {
    VStack(spacing: 0) {
        DayCell(day: DayItem(id: .now, weekdayText: "MON", dayNumberText: "20", isToday: false, workouts: [
            WorkoutItem(id: "1", title: "Legs day", exerciseCountText: "5 exercises", status: .missed, isCompleted: false, canToggle: true)
        ]), onTapWorkout: { _ in })
        DayCell(day: DayItem(id: .now, weekdayText: "WED", dayNumberText: "22", isToday: false, workouts: []), onTapWorkout: { _ in })
        DayCell(day: DayItem(id: .now, weekdayText: "FRI", dayNumberText: "24", isToday: true, workouts: [
            WorkoutItem(id: "2", title: "Legs day", exerciseCountText: "7 exercises", status: .assigned, isCompleted: false, canToggle: true),
            WorkoutItem(id: "3", title: "HIIT Tabata 20:10 8x8", exerciseCountText: "15 exercises", status: .assigned, isCompleted: false, canToggle: true)
        ]), onTapWorkout: { _ in })
    }
    .background(AppColors.screenBackground)
}
