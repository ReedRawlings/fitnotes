import Foundation
import SwiftData

// MARK: - Weight Unit Conversion

/// Utility for converting between weight units
public enum WeightUnitConverter {
    private static let lbsToKgRatio = 0.453592
    private static let kgToLbsRatio = 2.20462

    /// Converts a weight value to kilograms
    /// - Parameters:
    ///   - weight: The weight value to convert
    ///   - unit: The unit of the weight ("kg" or "lbs")
    /// - Returns: Weight in kilograms
    public static func toKg(_ weight: Double, from unit: String) -> Double {
        guard unit.lowercased() == "lbs" else { return weight }
        return weight * lbsToKgRatio
    }

    /// Converts a weight value from kilograms to a target unit
    /// - Parameters:
    ///   - weight: The weight value in kilograms
    ///   - unit: The target unit ("kg" or "lbs")
    /// - Returns: Weight in the target unit
    public static func fromKg(_ weight: Double, to unit: String) -> Double {
        guard unit.lowercased() == "lbs" else { return weight }
        return weight * kgToLbsRatio
    }

    /// Calculates volume in kg (converts weight to kg first)
    /// - Parameters:
    ///   - weight: The weight value
    ///   - reps: Number of repetitions
    ///   - unit: Unit of the weight ("kg" or "lbs")
    /// - Returns: Volume in kg units
    public static func volumeInKg(_ weight: Double, reps: Int, unit: String) -> Double {
        let weightInKg = toKg(weight, from: unit)
        return weightInKg * Double(reps)
    }
}

// MARK: - Routine Model (Reusable Templates)
@Model
public final class Routine {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var routineDescription: String?
    public var createdAt: Date
    public var updatedAt: Date
    @Relationship(deleteRule: .cascade) public var exercises: [RoutineExercise] = []

    public init(
        id: UUID = UUID(),
        name: String,
        routineDescription: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.routineDescription = routineDescription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Workout Model (Individual Day's Exercises)
@Model
public final class Workout {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var date: Date
    public var notes: String?
    public var routineTemplateId: UUID? // Reference to the template routine
    public var createdAt: Date
    public var updatedAt: Date
    @Relationship(deleteRule: .cascade) public var exercises: [WorkoutExercise] = []

    public init(
        id: UUID = UUID(),
        name: String,
        date: Date = Date(),
        notes: String? = nil,
        routineTemplateId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.notes = notes
        self.routineTemplateId = routineTemplateId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - RoutineExercise (for Routine templates)
@Model
public final class RoutineExercise {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID
    public var order: Int
    public var sets: Int
    public var reps: Int?
    public var weight: Double?
    public var duration: Int? // For time-based exercises
    public var distance: Double? // For distance-based exercises
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var routine: Routine?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        order: Int,
        sets: Int = 1,
        reps: Int? = nil,
        weight: Double? = nil,
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - WorkoutSet (Individual Set Data)
@Model
public final class WorkoutSet {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID       // Which exercise
    public var order: Int             // Set number (1, 2, 3...)
    public var reps: Int?
    public var weight: Double?
    public var unit: String           // Weight unit (kg or lbs) - stored when set was logged
    public var duration: Int?         // For cardio/timed
    public var distance: Double?      // For distance-based
    public var notes: String?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var date: Date             // When this was logged (used for grouping by day)
    public var rpe: Int?               // Rate of Perceived Exertion (0-10)
    public var rir: Int?               // Reps in Reserve (0-10)
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        order: Int,
        reps: Int?,
        weight: Double?,
        unit: String = "kg",
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        date: Date = Date(),
        rpe: Int? = nil,
        rir: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
        self.reps = reps
        self.weight = weight
        self.unit = unit
        self.duration = duration
        self.distance = distance
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.date = date
        // Validate RPE/RIR range (0-10)
        if let rpeValue = rpe, (rpeValue < 0 || rpeValue > 10) {
            self.rpe = nil
        } else {
            self.rpe = rpe
        }
        if let rirValue = rir, (rirValue < 0 || rirValue > 10) {
            self.rir = nil
        } else {
            self.rir = rir
        }
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - WorkoutExercise (for individual workouts)
@Model
public final class WorkoutExercise {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID
    public var order: Int
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var workout: Workout?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        order: Int,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
