import ActivityKit
import Foundation

/// Live Activity attributes for the rest timer
struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Current set number
        var setNumber: Int

        /// Timer end time (for automatic countdown)
        var endTime: Date

        /// Timer duration in seconds
        var duration: TimeInterval

        /// Whether timer is completed
        var isCompleted: Bool
    }

    /// Exercise name (static, doesn't change during activity)
    var exerciseName: String
}
