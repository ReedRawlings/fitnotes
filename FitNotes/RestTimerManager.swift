import SwiftUI
import Combine
import ActivityKit
import os.log

/// Manages rest timer updates and completion handling for views
@MainActor
class RestTimerManager: ObservableObject {
    @Published var showCompletionState = false
    @Published var celebrationScale: CGFloat = 1.0

    private var timerUpdateTimer: Timer?
    private var appState: AppState
    private var filterExerciseId: UUID?
    private var currentActivity: Activity<RestTimerAttributes>?

    // Logger for Live Activity debugging
    private let logger = Logger(subsystem: "com.fitnotes.app", category: "LiveActivity")

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
        logger.info("🚀 Starting Live Activity for '\(exerciseName)', Set #\(setNumber), Duration: \(duration)s")

        // Check if Live Activities are supported
        guard #available(iOS 16.2, *) else {
            logger.warning("❌ Live Activities not supported on this iOS version (requires iOS 16.2+)")
            return
        }

        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            logger.warning("❌ Live Activities are disabled by user or system")
            return
        }

        logger.info("✅ Live Activity authorization confirmed")

        // End any existing activity first
        endLiveActivity()

        let attributes = RestTimerAttributes(exerciseName: exerciseName)
        let endTime = Date().addingTimeInterval(duration)
        let initialState = RestTimerAttributes.ContentState(
            setNumber: setNumber,
            endTime: endTime,
            duration: duration,
            isCompleted: false
        )

        logger.info("📊 Live Activity state - Set: \(setNumber), EndTime: \(endTime), Duration: \(duration), IsCompleted: false")

        // Set staleDate to 5 seconds after timer ends so system knows when activity is outdated
        let activityContent = ActivityContent(
            state: initialState,
            staleDate: endTime.addingTimeInterval(5)
        )

        do {
            self.currentActivity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            logger.info("✅ Live Activity successfully created with ID: \(self.currentActivity?.id ?? "unknown")")
            logger.info("📱 Activity state: \(String(describing: self.currentActivity?.activityState))")
        } catch {
            logger.error("❌ Failed to create Live Activity: \(error.localizedDescription)")
            logger.error("🔍 Error details: \(String(describing: error))")
        }
    }

    /// Update Live Activity when timer completes
    func updateLiveActivityToCompleted() {
        guard let activity = currentActivity else {
            logger.warning("⚠️ No active Live Activity to update to completed state")
            return
        }

        logger.info("🔄 Updating Live Activity to completed state, ID: \(activity.id)")

        Task {
            let completedState = RestTimerAttributes.ContentState(
                setNumber: activity.content.state.setNumber,
                endTime: activity.content.state.endTime,
                duration: activity.content.state.duration,
                isCompleted: true
            )

            logger.info("📊 Updated state - Set: \(completedState.setNumber), IsCompleted: \(completedState.isCompleted)")

            do {
                // Activity becomes stale immediately after completion
                await activity.update(.init(state: completedState, staleDate: Date()))
                logger.info("✅ Live Activity updated successfully to completed state")
            } catch {
                logger.error("❌ Failed to update Live Activity: \(error.localizedDescription)")
            }

            // Auto-dismiss after 2 seconds
            logger.info("⏱️ Waiting 2 seconds before dismissing Live Activity...")
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            do {
                await activity.end(nil, dismissalPolicy: .immediate)
                logger.info("✅ Live Activity ended successfully")
            } catch {
                logger.error("❌ Failed to end Live Activity: \(String(describing: error))")
            }

            currentActivity = nil
            logger.info("🗑️ Cleared current activity reference")
        }
    }

    /// End the Live Activity
    func endLiveActivity() {
        guard let activity = currentActivity else {
            logger.debug("ℹ️ No active Live Activity to end")
            return
        }

        logger.info("🛑 Ending Live Activity, ID: \(activity.id)")

        Task {
            do {
                await activity.end(nil, dismissalPolicy: .immediate)
                logger.info("✅ Live Activity ended successfully")
            } catch {
                logger.error("❌ Failed to end Live Activity: \(String(describing: error))")
            }
            currentActivity = nil
            logger.info("🗑️ Cleared current activity reference")
        }
    }

    nonisolated deinit {
        timerUpdateTimer?.invalidate()
    }
}
