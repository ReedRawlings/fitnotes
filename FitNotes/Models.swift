import Foundation
import SwiftData

// MARK: - Exercise Model
@Model
public final class Exercise {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var category: String
    public var type: String
    public var notes: String?
    public var mediaURL: String?
    public var unit: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        type: String,
        notes: String? = nil,
        mediaURL: String? = nil,
        unit: String = "kg",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.notes = notes
        self.mediaURL = mediaURL
        self.unit = unit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Workout Model
@Model
public final class Workout {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var notes: String?
    public var templateRef: UUID?
    public var totalVolume: Double
    public var createdAt: Date
    public var updatedAt: Date
    @Relationship(deleteRule: .cascade) public var sets: [WorkoutSet] = []

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        notes: String? = nil,
        templateRef: UUID? = nil,
        totalVolume: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.notes = notes
        self.templateRef = templateRef
        self.totalVolume = totalVolume
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - WorkoutSet Model
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

// MARK: - Program Model
@Model
public final class Program {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var programDescription: String?
    public var days: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        programDescription: String? = nil,
        days: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.programDescription = programDescription
        self.days = days
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
