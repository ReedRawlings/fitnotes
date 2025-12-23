import Foundation
import SwiftData

// MARK: - GoalType Enum
public enum GoalType: String, Codable, CaseIterable {
    case weeklyWorkouts = "weekly_workouts"     // Target X workouts per week
    case weeklyVolume = "weekly_volume"          // Target X volume per week
    case specificLift = "specific_lift"          // Target X weight on a specific exercise

    public var displayName: String {
        switch self {
        case .weeklyWorkouts: return "Weekly Workouts"
        case .weeklyVolume: return "Weekly Volume"
        case .specificLift: return "Lift Target"
        }
    }

    public var icon: String {
        switch self {
        case .weeklyWorkouts: return "calendar.badge.checkmark"
        case .weeklyVolume: return "chart.bar.fill"
        case .specificLift: return "dumbbell.fill"
        }
    }

    public var unitLabel: String {
        switch self {
        case .weeklyWorkouts: return "workouts/week"
        case .weeklyVolume: return "kg/week"
        case .specificLift: return ""  // Will be dynamic based on exercise
        }
    }
}

// MARK: - FitnessGoal Model
@Model
public final class FitnessGoal {
    @Attribute(.unique) public var id: UUID
    public var typeRaw: String              // GoalType raw value
    public var targetValue: Double          // Target number (workouts, volume, or weight)
    public var exerciseId: UUID?            // Only for specificLift type
    public var exerciseName: String?        // Cached exercise name for display
    public var weightUnit: String?          // For specificLift type (kg or lbs)
    public var isActive: Bool
    public var createdAt: Date
    public var achievedAt: Date?

    public var goalType: GoalType {
        get { GoalType(rawValue: typeRaw) ?? .weeklyWorkouts }
        set { typeRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        type: GoalType,
        targetValue: Double,
        exerciseId: UUID? = nil,
        exerciseName: String? = nil,
        weightUnit: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        achievedAt: Date? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.targetValue = targetValue
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.weightUnit = weightUnit
        self.isActive = isActive
        self.createdAt = createdAt
        self.achievedAt = achievedAt
    }
}

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
    public var useWarmupSets: Bool
    public var autoProgress: Bool  // Global setting to auto-apply progression recommendations
    public var hasViewedYearInReview2024: Bool
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
        useWarmupSets: Bool = false,
        autoProgress: Bool = false,
        hasViewedYearInReview2024: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.defaultWeightUnit = defaultWeightUnit
        self.defaultRestSeconds = defaultRestSeconds
        self.defaultStatsDisplayPreferenceRaw = defaultStatsDisplayPreference.rawValue
        self.keepCurrentRoutineView = keepCurrentRoutineView
        self.keepCurrentWorkoutView = keepCurrentWorkoutView
        self.useWarmupSets = useWarmupSets
        self.autoProgress = autoProgress
        self.hasViewedYearInReview2024 = hasViewedYearInReview2024
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
