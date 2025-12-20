//
//  RestTimerActivityAttributes.swift
//  FitNotes
//
//  Shared Activity Attributes for rest timer Live Activity
//  NOTE: This file must be added to BOTH the FitNotes target AND the RestTimerWidget target
//

import ActivityKit
import Foundation

/// Defines the data model for the rest timer Live Activity
/// This struct is shared between the main app and widget extension
public struct RestTimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// The time when the rest timer ends (for countdown)
        public var endTime: Date
        /// Whether the timer has completed
        public var isCompleted: Bool

        public init(endTime: Date, isCompleted: Bool = false) {
            self.endTime = endTime
            self.isCompleted = isCompleted
        }
    }

    /// Name of the exercise (doesn't change during activity)
    public var exerciseName: String
    /// The set number that was just completed
    public var setNumber: Int
    /// Total duration in seconds (for display purposes)
    public var duration: Int

    public init(exerciseName: String, setNumber: Int, duration: Int) {
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.duration = duration
    }
}
