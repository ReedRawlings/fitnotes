import Foundation
import SwiftData

@Model
public final class DailyRoutine {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var date: Date
    public var notes: String?
    public var isCompleted: Bool
    public var createdAt: Date
    public var updatedAt: Date
    @Relationship(deleteRule: .cascade) public var exercises: [RoutineExercise] = []

    public init(
        id: UUID = UUID(),
        name: String,
        date: Date = Date(),
        notes: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

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
    public var isCompleted: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var dailyRoutine: DailyRoutine?

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
        isCompleted: Bool = false,
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
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
