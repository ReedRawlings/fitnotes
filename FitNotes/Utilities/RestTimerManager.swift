import SwiftUI
import Combine
import UserNotifications
import ActivityKit

/// Manages rest timer updates, completion handling, and Live Activity for views
@MainActor
class RestTimerManager: ObservableObject {
    @Published var showCompletionState = false
    @Published var celebrationScale: CGFloat = 1.0

    private var timerUpdateTimer: Timer?
    private var appState: AppState
    private var filterExerciseId: UUID?
    private var lastKnownTimerId: UUID?

    // Live Activity tracking
    private var currentActivity: Activity<RestTimerWidgetAttributes>?

    init(appState: AppState, filterExerciseId: UUID? = nil) {
        self.appState = appState
        self.filterExerciseId = filterExerciseId
        requestNotificationPermissions()
    }

    /// Request notification permissions on initialization
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else if granted {
                print("Notification permissions granted")
            }
        }
    }

    /// Start periodic timer updates to check completion state
    func startTimerUpdates() {
        timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                // Check if we should filter by exercise ID
                if let filterExerciseId = self.filterExerciseId {
                    if let timer = self.appState.activeRestTimer,
                       timer.exerciseId == filterExerciseId {
                        // Detect if a NEW timer was started (different ID) - reset completion state
                        if timer.id != self.lastKnownTimerId {
                            self.lastKnownTimerId = timer.id
                            self.showCompletionState = false
                            self.celebrationScale = 1.0
                        }

                        // Check for completion
                        if timer.isCompleted && !self.showCompletionState {
                            self.handleTimerCompletion()
                        }
                    }
                } else {
                    // No filter - check any timer
                    if let timer = self.appState.activeRestTimer {
                        // Detect if a NEW timer was started (different ID) - reset completion state
                        if timer.id != self.lastKnownTimerId {
                            self.lastKnownTimerId = timer.id
                            self.showCompletionState = false
                            self.celebrationScale = 1.0
                        }

                        // Check for completion
                        if timer.isCompleted && !self.showCompletionState {
                            self.handleTimerCompletion()
                        }
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

        // Update Live Activity to show completion
        updateLiveActivityCompletion()

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

        // Capture the timer ID at completion time
        let completedTimerId = lastKnownTimerId

        // Auto-dismiss after 2 seconds, but only if no new timer has started
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Only dismiss if the same timer is still active (no new timer started)
            guard self.lastKnownTimerId == completedTimerId else { return }

            self.appState.cancelRestTimer()
            self.showCompletionState = false
            self.celebrationScale = 1.0
            self.endLiveActivity()
        }
    }

    /// Handle skip action
    func skipTimer() {
        appState.cancelRestTimer()
        showCompletionState = false
        celebrationScale = 1.0
        lastKnownTimerId = nil
        cancelNotification()
        endLiveActivity()
    }

    /// Handle app returning to foreground - dismiss completed timers immediately
    func handleAppBecameActive() {
        if let timer = appState.activeRestTimer {
            // Check if this timer matches our filter (if any)
            if let filterExerciseId = filterExerciseId {
                guard timer.exerciseId == filterExerciseId else { return }
            }

            // If timer is completed, dismiss it immediately
            if timer.isCompleted {
                appState.cancelRestTimer()
                showCompletionState = false
                celebrationScale = 1.0
                lastKnownTimerId = nil
                endLiveActivity()
            }
        }
    }

    // MARK: - Notification Management

    /// Start timer and schedule notification
    func startTimer(exerciseName: String, setNumber: Int, duration: TimeInterval) {
        // Schedule notification for when timer completes
        scheduleNotification(delay: duration)

        // Start Live Activity
        startLiveActivity(exerciseName: exerciseName, setNumber: setNumber, duration: duration)
    }

    /// End timer and cancel notification
    func endTimer() {
        cancelNotification()
        endLiveActivity()
    }

    /// Schedule notification for timer completion
    private func scheduleNotification(delay: TimeInterval) {
        // Cancel any existing notifications first
        cancelNotification()

        let content = UNMutableNotificationContent()
        content.title = "Rest Complete!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled for \(delay) seconds from now")
            }
        }
    }

    /// Cancel pending notification
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }

    // MARK: - Live Activity Management

    /// Start a Live Activity for the rest timer
    private func startLiveActivity(exerciseName: String, setNumber: Int, duration: TimeInterval) {
        // End any existing activity first
        endLiveActivity()

        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        let attributes = RestTimerWidgetAttributes(
            exerciseName: exerciseName,
            setNumber: setNumber,
            duration: Int(duration)
        )

        let endTime = Date().addingTimeInterval(duration)
        let initialState = RestTimerWidgetAttributes.ContentState(
            endTime: endTime,
            isCompleted: false
        )

        do {
            let activity = try Activity<RestTimerWidgetAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: endTime.addingTimeInterval(60)),
                pushType: nil
            )
            currentActivity = activity
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }

    /// Update the Live Activity to show completion state
    private func updateLiveActivityCompletion() {
        guard let activity = currentActivity else { return }

        let completedState = RestTimerWidgetAttributes.ContentState(
            endTime: Date(),
            isCompleted: true
        )

        Task {
            await activity.update(
                ActivityContent(state: completedState, staleDate: Date().addingTimeInterval(60))
            )
            print("Updated Live Activity to completed state")
        }
    }

    /// End the current Live Activity
    private func endLiveActivity() {
        guard let activity = currentActivity else { return }

        let finalState = RestTimerWidgetAttributes.ContentState(
            endTime: Date(),
            isCompleted: true
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            print("Ended Live Activity: \(activity.id)")
        }

        currentActivity = nil
    }

    /// End all rest timer Live Activities (cleanup on app launch)
    static func endAllActivities() {
        Task {
            for activity in Activity<RestTimerWidgetAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
                print("Cleaned up stale Live Activity: \(activity.id)")
            }
        }
    }

    nonisolated deinit {
        timerUpdateTimer?.invalidate()
    }
}
