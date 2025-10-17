import Foundation
import SwiftData

// Exercise model is now in Exercise.swift

// Workout and WorkoutSet models are now in DailyRoutine.swift

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
