import Foundation
import SwiftData

// MARK: - Schema V2 (frozen)
//
// A snapshot of every model exactly as it was stored in V2 (build 18 and earlier TestFlight
// builds). SwiftData identifies an existing store's version by hashing these definitions, so
// they must NEVER be edited. Only stored properties matter; computed helpers were left out.
//
// V3 changed every model to meet CloudKit's rules (no unique constraints, defaults on every
// non-optional attribute, optional to-many relationships with inverses), so all nine are here.
// V1 also points at the BodyMetric, WorkoutSet, UserPreferences and FitnessGoal copies below,
// because those four did not change between V1 and V2.

enum FitNotesSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Exercise.self,
            Workout.self,
            BodyMetric.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            RoutineExercise.self,
            Routine.self,
            UserPreferences.self,
            FitnessGoal.self
        ]
    }

    @Model
    final class Exercise {
        @Attribute(.unique) var id: UUID
        var name: String
        var primaryCategory: String
        @Attribute var secondaryCategoriesRaw: String = ""
        var equipment: String
        var notes: String?
        var unit: String
        var isCustom: Bool
        var rpeEnabled: Bool
        var rirEnabled: Bool
        var useRestTimer: Bool = false
        var defaultRestSeconds: Int = 90
        var useAdvancedRest: Bool = false
        var useWarmupSet: Bool = false
        @Attribute var customRestSecondsRaw: String = "{}"
        var targetRepMin: Int? = nil
        var targetRepMax: Int? = nil
        var progressionSetCount: Int? = nil
        var lastProgressionDate: Date? = nil
        var incrementValue: Double = 5.0
        var autoProgress: Bool = false
        @Attribute var statsDisplayPreferenceRaw: String = "rememberLastState"
        var statsIsExpanded: Bool = false
        @Attribute var trackingTypeRaw: String = "weightAndReps"
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID = UUID(), name: String, primaryCategory: String, equipment: String = "Free Weight",
             unit: String = "kg", isCustom: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.name = name
            self.primaryCategory = primaryCategory
            self.equipment = equipment
            self.unit = unit
            self.isCustom = isCustom
            self.rpeEnabled = false
            self.rirEnabled = false
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class Routine {
        @Attribute(.unique) var id: UUID
        var name: String
        var routineDescription: String?
        var createdAt: Date
        var updatedAt: Date
        @Relationship(deleteRule: .cascade) var exercises: [RoutineExercise] = []
        var colorRaw: String = "coral"
        var scheduleTypeRaw: String = "none"
        var scheduleDaysRaw: String?
        var scheduleIntervalDays: Int?
        var scheduleStartDate: Date?

        init(id: UUID = UUID(), name: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.name = name
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class Workout {
        @Attribute(.unique) var id: UUID
        var name: String
        var date: Date
        var notes: String?
        var routineTemplateId: UUID?
        var createdAt: Date
        var updatedAt: Date
        @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise] = []
        var finishedAt: Date? = nil

        init(id: UUID = UUID(), name: String, date: Date = Date(), createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.name = name
            self.date = date
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class RoutineExercise {
        @Attribute(.unique) var id: UUID
        var exerciseId: UUID
        var order: Int
        var notes: String?
        var supersetGroupId: UUID? = nil
        var createdAt: Date
        var updatedAt: Date
        var routine: Routine?

        init(id: UUID = UUID(), exerciseId: UUID, order: Int, createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.exerciseId = exerciseId
            self.order = order
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class WorkoutExercise {
        @Attribute(.unique) var id: UUID
        var exerciseId: UUID
        var order: Int
        var notes: String?
        var supersetGroupId: UUID? = nil
        var createdAt: Date
        var updatedAt: Date
        var workout: Workout?

        init(id: UUID = UUID(), exerciseId: UUID, order: Int, createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.exerciseId = exerciseId
            self.order = order
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class WorkoutSet {
        @Attribute(.unique) var id: UUID
        var exerciseId: UUID
        var order: Int
        var reps: Int?
        var weight: Double?
        var unit: String
        var duration: Int?
        var distance: Double?
        var notes: String?
        var isCompleted: Bool
        var completedAt: Date?
        var date: Date
        var rpe: Int?
        var rir: Int?
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID = UUID(), exerciseId: UUID, order: Int, reps: Int?, weight: Double?, unit: String = "kg",
             isCompleted: Bool = false, date: Date = Date(), createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.exerciseId = exerciseId
            self.order = order
            self.reps = reps
            self.weight = weight
            self.unit = unit
            self.isCompleted = isCompleted
            self.date = date
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class BodyMetric {
        @Attribute(.unique) var id: UUID
        var date: Date
        var type: String
        var value: Double
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID = UUID(), date: Date = Date(), type: String, value: Double,
             createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.date = date
            self.type = type
            self.value = value
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class UserPreferences {
        @Attribute(.unique) var id: UUID
        var defaultWeightUnit: String
        var defaultRestSeconds: Int
        var defaultStatsDisplayPreferenceRaw: String
        var keepCurrentRoutineView: Bool
        var keepCurrentWorkoutView: Bool
        var useWarmupSets: Bool
        var autoProgress: Bool
        var hasViewedYearInReview2024: Bool
        var createdAt: Date
        var updatedAt: Date

        init(id: UUID = UUID(), defaultWeightUnit: String = "kg", createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.defaultWeightUnit = defaultWeightUnit
            self.defaultRestSeconds = 90
            self.defaultStatsDisplayPreferenceRaw = "rememberLastState"
            self.keepCurrentRoutineView = false
            self.keepCurrentWorkoutView = false
            self.useWarmupSets = false
            self.autoProgress = false
            self.hasViewedYearInReview2024 = false
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class FitnessGoal {
        @Attribute(.unique) var id: UUID
        var typeRaw: String
        var targetValue: Double
        var exerciseId: UUID?
        var exerciseName: String?
        var weightUnit: String?
        var isActive: Bool
        var createdAt: Date
        var achievedAt: Date?

        init(id: UUID = UUID(), typeRaw: String, targetValue: Double, isActive: Bool = true, createdAt: Date = Date()) {
            self.id = id
            self.typeRaw = typeRaw
            self.targetValue = targetValue
            self.isActive = isActive
            self.createdAt = createdAt
        }
    }
}
