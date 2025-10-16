import Foundation
import SwiftData

@Model
public final class WorkoutSet {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID
    public var order: Int
    public var weight: Double
    public var reps: Int
    public var rpe: Double?
    public var restSec: Int?
    public var completed: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var workout: Workout?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        order: Int,
        weight: Double,
        reps: Int,
        rpe: Double? = nil,
        restSec: Int? = nil,
        completed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.restSec = restSec
        self.completed = completed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
