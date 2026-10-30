import SwiftUI

/// Shared indicator for a screen's first load (nothing to show yet): spinner + "Loading…".
/// Later reloads use the system pull-to-refresh spinner instead.
struct LoadingIndicator: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(AppColors.primary)
            Text(AppStrings.Common.loading)
                .textStyle(AppTypography.loading)
                .foregroundStyle(AppColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AppAccessibilityID.loading)
    }
}

#Preview {
    LoadingIndicator()
}
