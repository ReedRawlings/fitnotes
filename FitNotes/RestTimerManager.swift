import SwiftUI
import Combine

/// Manages rest timer updates and completion handling for views
@MainActor
class RestTimerManager: ObservableObject {
    @Published var showCompletionState = false
    @Published var celebrationScale: CGFloat = 1.0

    private var timerUpdateTimer: Timer?
    private var appState: AppState
    private var filterExerciseId: UUID?

    init(appState: AppState, filterExerciseId: UUID? = nil) {
        self.appState = appState
        self.filterExerciseId = filterExerciseId
    }

    /// Start periodic timer updates to check completion state
    func startTimerUpdates() {
        timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Check if we should filter by exercise ID
            if let filterExerciseId = self.filterExerciseId {
                if let timer = self.appState.activeRestTimer,
                   timer.exerciseId == filterExerciseId,
                   timer.isCompleted && !self.showCompletionState {
                    Task { @MainActor in
                        self.handleTimerCompletion()
                    }
                }
            } else {
                // No filter - check any timer
                if let timer = self.appState.activeRestTimer,
                   timer.isCompleted && !self.showCompletionState {
                    Task { @MainActor in
                        self.handleTimerCompletion()
                    }
                }
            }
        }
    }

    /// Stop timer updates
    func stopTimerUpdates() {
        timerUpdateTimer?.invalidate()
        timerUpdateTimer = nil
    }

    /// Handle timer completion with celebration animation and auto-dismiss
    func handleTimerCompletion() {
        showCompletionState = true

        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)

        // Celebration animation: scale 1.0 -> 1.05 -> 1.0
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            celebrationScale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                self.celebrationScale = 1.0
            }
        }

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.appState.cancelRestTimer()
            self.showCompletionState = false
            self.celebrationScale = 1.0
        }
    }

    /// Handle skip action
    func skipTimer() {
        appState.cancelRestTimer()
        showCompletionState = false
        celebrationScale = 1.0
    }

    deinit {
        stopTimerUpdates()
    }
}
