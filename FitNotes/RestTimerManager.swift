import SwiftUI
import Combine
import UserNotifications

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
        cancelNotification()
    }

    // MARK: - Notification Management

    /// Start timer and schedule notification
    func startTimer(exerciseName: String, setNumber: Int, duration: TimeInterval) {
        // Schedule notification for when timer completes
        scheduleNotification(delay: duration)
    }

    /// End timer and cancel notification
    func endTimer() {
        cancelNotification()
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

    nonisolated deinit {
        timerUpdateTimer?.invalidate()
    }
}
