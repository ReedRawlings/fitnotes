import Foundation
import SwiftData

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
