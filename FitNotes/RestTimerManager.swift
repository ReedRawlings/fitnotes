import SwiftUI
import Combine
import ActivityKit

/// Manages rest timer updates and completion handling for views
@MainActor
class RestTimerManager: ObservableObject {
    @Published var showCompletionState = false
    @Published var celebrationScale: CGFloat = 1.0

    private var timerUpdateTimer: Timer?
    private var appState: AppState
    private var filterExerciseId: UUID?
    private var currentActivity: Activity<RestTimerAttributes>?

    init(appState: AppState, filterExerciseId: UUID? = nil) {
        self.appState = appState
        self.filterExerciseId = filterExerciseId
    }

    /// Start periodic timer updates to check completion state
    func startTimerUpdates() {
        timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                // Check if we should filter by exercise ID
                if let filterExerciseId = self.filterExerciseId {
                    if let timer = self.appState.activeRestTimer,
                       timer.exerciseId == filterExerciseId,
                       timer.isCompleted && !self.showCompletionState {
                        self.handleTimerCompletion()
                    }
                } else {
                    // No filter - check any timer
                    if let timer = self.appState.activeRestTimer,
                       timer.isCompleted && !self.showCompletionState {
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

        // Update Live Activity to completed state
        updateLiveActivityToCompleted()

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
        endLiveActivity()
    }

    // MARK: - Live Activity Management

    /// Start a Live Activity for the rest timer
    func startLiveActivity(exerciseName: String, setNumber: Int, duration: TimeInterval) {
        print("🔵 RestTimerManager.startLiveActivity called")
        print("🔵 Exercise: \(exerciseName), Set: \(setNumber), Duration: \(duration)s")
        
        // Check if Live Activities are supported
        if #available(iOS 16.2, *) {
            print("✅ iOS version supports Live Activities")
        } else {
            print("🔴 iOS version does NOT support Live Activities")
            return
        }
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // End any existing activity first
        print("🔵 Ending any existing activity...")
        endLiveActivity()

        let attributes = RestTimerAttributes(exerciseName: exerciseName)
        let initialState = RestTimerAttributes.ContentState(
            setNumber: setNumber,
            endTime: Date().addingTimeInterval(duration),
            duration: duration,
            isCompleted: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("Live Activity started: \(activity.id)")
            print("✅ Live Activity started successfully: \(activity.id)")
            print("✅ Activity state: \(activity.activityState)")
            print("✅ Activity content state: \(activity.content.state)")
        } catch {
            print("Failed to start Live Activity: \(error)")
            print("🔴 Failed to start Live Activity")
            print("🔴 Error: \(error)")
            print("🔴 Error localized: \(error.localizedDescription)")
        }
    }

    /// Update Live Activity when timer completes
    func updateLiveActivityToCompleted() {
        guard let activity = currentActivity else { return }

        Task {
            let completedState = RestTimerAttributes.ContentState(
                setNumber: activity.content.state.setNumber,
                endTime: activity.content.state.endTime,
                duration: activity.content.state.duration,
                isCompleted: true
            )

            await activity.update(.init(state: completedState, staleDate: nil))
            print("Live Activity updated to completed")

            // Auto-dismiss after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    /// End the Live Activity
    func endLiveActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            print("Live Activity ended")
        }
    }

    nonisolated deinit {
        timerUpdateTimer?.invalidate()
    }
}
