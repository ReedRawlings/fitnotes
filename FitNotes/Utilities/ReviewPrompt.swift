import Foundation

/// Decides when to ask for an App Store rating. iOS shows the dialog at most three times a year
/// and may show nothing at all; this policy keeps the ask to a good moment (right after finishing
/// a workout) and away from new users.
enum ReviewPrompt {
    static let minimumWorkouts = 3
    static let minimumDaysBetweenRequests = 120

    private static let lastRequestDateKey = "reviewPrompt.lastRequestDate"
    private static let lastRequestVersionKey = "reviewPrompt.lastRequestVersion"

    static func shouldRequest(
        workoutCount: Int,
        lastRequestDate: Date?,
        lastRequestVersion: String?,
        currentVersion: String,
        now: Date = Date()
    ) -> Bool {
        guard workoutCount >= minimumWorkouts else { return false }
        // Once per app version at most
        guard lastRequestVersion != currentVersion else { return false }
        if let lastRequestDate,
           let days = Calendar.current.dateComponents([.day], from: lastRequestDate, to: now).day,
           days < minimumDaysBetweenRequests {
            return false
        }
        return true
    }

    /// Checks the stored history and, if it's a good time, records the request and returns true.
    static func consumeRequestIfDue(workoutCount: Int, defaults: UserDefaults = .standard) -> Bool {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        guard shouldRequest(
            workoutCount: workoutCount,
            lastRequestDate: defaults.object(forKey: lastRequestDateKey) as? Date,
            lastRequestVersion: defaults.string(forKey: lastRequestVersionKey),
            currentVersion: version
        ) else { return false }
        defaults.set(Date(), forKey: lastRequestDateKey)
        defaults.set(version, forKey: lastRequestVersionKey)
        return true
    }
}
