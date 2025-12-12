import Foundation
import SwiftData

// MARK: - BodyMetric Model
@Model
public final class BodyMetric {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var type: String
    public var value: Double
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: String,
        value: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.value = value
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - UserPreferences Model
@Model
public final class UserPreferences {
    @Attribute(.unique) public var id: UUID
    public var defaultWeightUnit: String
    public var defaultRestSeconds: Int
    public var defaultStatsDisplayPreferenceRaw: String
    public var keepCurrentRoutineView: Bool
    public var keepCurrentWorkoutView: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    // Computed property for stats display preference
    public var defaultStatsDisplayPreference: StatsDisplayPreference {
        get {
            StatsDisplayPreference(rawValue: defaultStatsDisplayPreferenceRaw) ?? .rememberLastState
        }
        set {
            defaultStatsDisplayPreferenceRaw = newValue.rawValue
        }
    }
    
    public init(
        id: UUID = UUID(),
        defaultWeightUnit: String = "kg",
        defaultRestSeconds: Int = 90,
        defaultStatsDisplayPreference: StatsDisplayPreference = .rememberLastState,
        keepCurrentRoutineView: Bool = false,
        keepCurrentWorkoutView: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.defaultWeightUnit = defaultWeightUnit
        self.defaultRestSeconds = defaultRestSeconds
        self.defaultStatsDisplayPreferenceRaw = defaultStatsDisplayPreference.rawValue
        self.keepCurrentRoutineView = keepCurrentRoutineView
        self.keepCurrentWorkoutView = keepCurrentWorkoutView
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
