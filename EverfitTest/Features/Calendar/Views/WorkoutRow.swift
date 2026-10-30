import SwiftUI

/// One workout card inside a day row. Tapping it marks/unmarks the workout;
/// future workouts are shown read-only (no tap, no button trait).
struct WorkoutRow: View {
    let workout: WorkoutItem
    let onTap: () -> Void

    private typealias Metrics = AppSpacing.Calendar

    var body: some View {
        if workout.canToggle {
            Button(action: onTap) {
                card
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: workout.isCompleted)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityHint(workout.isCompleted ? AppStrings.Accessibility.markNotCompleted : AppStrings.Accessibility.markCompleted)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AppAccessibilityID.Calendar.workout(workout.id))
        } else {
            card
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityText)
                .accessibilityIdentifier(AppAccessibilityID.Calendar.workout(workout.id))
        }
    }

    private var accessibilityText: String {
        [workout.title, workout.status.accessibilityName, workout.exerciseCountText].joined(separator: ", ")
    }

    private var card: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: Metrics.cardTextSpacing) {
                Text("long text hereeeeeeeeeeeeeee")
                    .textStyle(AppTypography.workoutTitle)
                    .foregroundStyle(workout.status.titleColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                subtitle
                    .textStyle(AppTypography.workoutDetail)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if workout.status == .completed {
                CheckBadge()
                    .padding(.trailing, Metrics.checkBadgeTrailingInset)
            }
        }
        .padding(Metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(workout.status.cardBackground, in: .rect(cornerRadius: AppSpacing.Radius.card))
        // Whole card is tappable, including the empty space next to the text.
        .contentShape(.rect(cornerRadius: AppSpacing.Radius.card))
    }

    /// One of three shapes, depending on the status.
    private var subtitle: Text {
        let status = workout.status
        let count = Text(workout.exerciseCountText).foregroundStyle(status.detailColor)

        // assigned / upcoming have no status word.
        // Output: "7 exercises"
        guard let label = status.label else { return count }

        let labelText = Text(label).foregroundStyle(status.labelColor)

        // completed shows only its status word.
        // Output: "Completed"
        guard status.showsExerciseCount else { return labelText }

        // missed shows the status word (red) and the count.
        // Output: "Missed • 5 exercises"
        let separator = Text(AppStrings.CalendarScreen.detailSeparator).foregroundStyle(status.detailColor)
        return Text("\(labelText)\(separator)\(count)")
    }
}

/// White round check on the right of a completed (purple) card — Figma icon.
/// The tick is see-through, so it takes the card's purple.
private struct CheckBadge: View {
    var body: some View {
        Image(AppIcons.checkmark)
            .renderingMode(.template)
            .resizable()
            .frame(width: AppSpacing.Calendar.checkBadgeSize, height: AppSpacing.Calendar.checkBadgeSize)
            .foregroundStyle(AppColors.textOnPrimary)
            .accessibilityHidden(true)
    }
}
