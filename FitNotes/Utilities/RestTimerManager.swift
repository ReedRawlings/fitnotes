import SwiftUI
import Combine
import UserNotifications
import ActivityKit
import AudioToolbox

/// Manages rest timer updates, completion handling, and Live Activity.
/// A single shared instance lives on AppState (`appState.restTimerManager`) and owns the
/// countdown polling, completion UI state, notification, chime, and Live Activity together —
/// per-view instances would split that state and the Live Activity never sees completion.
@MainActor
class RestTimerManager: ObservableObject {
    @Published var showCompletionState = false
    @Published var celebrationScale: CGFloat = 1.0

    private var timerUpdateTimer: Timer?
    private var appState: AppState
    private var lastKnownTimerId: UUID?

    // Live Activity tracking
    private var currentActivity: Activity<RestTimerWidgetAttributes>?

    init(appState: AppState) {
        self.appState = appState
    }

    /// Identifies the notification currently being scheduled, so a timer that is ended while the
    /// permission prompt is still up doesn't get a stale "Rest Complete" alert afterwards.
    private var pendingNotificationToken: UUID?

    /// Start periodic timer updates to check completion state.
    /// The manager starts/stops this itself around the timer's lifecycle.
    private func startTimerUpdates() {
        // Never stack a second polling timer on top of a live one
        timerUpdateTimer?.invalidate()
        timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                guard let timer = self.appState.activeRestTimer else {
                    // Nothing to watch: stop polling unless the completion banner is mid-dismiss
                    if !self.showCompletionState {
                        self.stopTimerUpdates()
                    }
                    return
                }

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

    /// Stop timer updates
    private func stopTimerUpdates() {
        timerUpdateTimer?.invalidate()
        timerUpdateTimer = nil
    }

    /// Handle timer completion with chime, celebration animation, and auto-dismiss
    func handleTimerCompletion() {
        guard !showCompletionState else { return }
        showCompletionState = true

        // Update Live Activity to show completion
        updateLiveActivityCompletion()

        // Completion chime (system "Calypso"; respects the silent switch) + success haptic
        AudioServicesPlaySystemSound(SystemSoundID(1022))
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)

        // Celebration animation: scale 1.0 -> 1.05 -> 1.0
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            celebrationScale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                self?.celebrationScale = 1.0
            }
        }

        // Capture the timer ID at completion time
        let completedTimerId = lastKnownTimerId

        // Auto-dismiss after 2 seconds, but only if no new timer has started
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            // Only dismiss if the same timer is still active (no new timer started)
            guard self.lastKnownTimerId == completedTimerId else { return }

            self.appState.cancelRestTimer() // triggers endTimer(), which cleans everything up
            self.showCompletionState = false
            self.celebrationScale = 1.0
        }
    }

    /// Handle skip action
    func skipTimer() {
        appState.cancelRestTimer() // triggers endTimer(), which cleans everything up
        showCompletionState = false
        celebrationScale = 1.0
        lastKnownTimerId = nil
    }

    /// Handle app returning to foreground - dismiss completed timers immediately
    func handleAppBecameActive() {
        if let timer = appState.activeRestTimer, timer.isCompleted {
            appState.cancelRestTimer()
            showCompletionState = false
            celebrationScale = 1.0
            lastKnownTimerId = nil
        }
    }

    // MARK: - Notification Management

    /// Start timer: schedule the notification, start the Live Activity, and begin polling
    func startTimer(exerciseName: String, setNumber: Int, duration: TimeInterval) {
        // Schedule notification for when timer completes
        scheduleNotification(delay: duration)

        // Start Live Activity
        startLiveActivity(exerciseName: exerciseName, setNumber: setNumber, duration: duration)

        // Watch for completion while the timer runs
        startTimerUpdates()
    }

    /// End timer: cancel notification, end the Live Activity, and stop polling
    func endTimer() {
        cancelNotification()
        endLiveActivity()
        stopTimerUpdates()
    }

    /// Schedule notification for timer completion
    /// Permission is requested here, the first time the user starts a rest timer, so the system
    /// prompt appears with obvious context instead of at app launch. Once decided, iOS returns
    /// the stored answer immediately without prompting again.
    private func scheduleNotification(delay: TimeInterval) {
        // Cancel any existing notifications first
        cancelNotification()

        let token = UUID()
        pendingNotificationToken = token
        let endDate = Date().addingTimeInterval(delay)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
            guard granted else { return }

            Task { @MainActor [weak self] in
                guard let self, self.pendingNotificationToken == token else { return }
                let remaining = endDate.timeIntervalSinceNow
                guard remaining > 0.5 else { return }

                let content = UNMutableNotificationContent()
                content.title = "Rest Complete!"
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: false)
                let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }
        }
    }

    /// Cancel pending notification
    private func cancelNotification() {
        pendingNotificationToken = nil
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
