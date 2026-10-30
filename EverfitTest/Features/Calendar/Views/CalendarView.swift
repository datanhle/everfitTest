import SwiftUI

struct CalendarView: View {
    @State private var viewModel: CalendarViewModel

    init(viewModel: CalendarViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // While loading, rows show dates only (Figma "training - empty").
                ForEach(viewModel.days) { day in
                    DayCell(day: day) { workoutID in
                        viewModel.toggleCompletion(workoutID: workoutID)
                    }
                }
            }
        }
        // Keep scrolled rows out of the status bar / home indicator; the background still fills the screen.
        .clipped()
        // First load with no cache: shared indicator over the dated rows. Reloads use the pull-to-refresh spinner.
        .overlay {
            if viewModel.isLoading {
                LoadingIndicator()
            }
        }
        .background(AppColors.screenBackground)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert(AppStrings.Errors.title, isPresented: $viewModel.isShowingError, presenting: viewModel.errorMessage) { _ in
            Button(AppStrings.Errors.close, role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }
}
