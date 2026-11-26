import Foundation
import SwiftData

// MARK: - Schema V1 (frozen)
//
// A snapshot of the models that changed after V1 shipped, exactly as they were stored in V1.
// SwiftData identifies an existing store's version by hashing these definitions, so they must
// NEVER be edited. Models that did not change between V1 and V2 (BodyMetric, WorkoutSet,
// UserPreferences, FitnessGoal) are shared with the frozen V2 copies in SchemaV2.swift.
//
// Routine and Workout are frozen too, even though their own properties did not change, because
// their relationships point at the frozen RoutineExercise / WorkoutExercise.

enum FitNotesSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Exercise.self,
            Workout.self,
            FitNotesSchemaV2.BodyMetric.self,
            WorkoutExercise.self,
            FitNotesSchemaV2.WorkoutSet.self,
            RoutineExercise.self,
            Routine.self,
            FitNotesSchemaV2.UserPreferences.self,
            FitNotesSchemaV2.FitnessGoal.self
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
}
