import Foundation
import SwiftData

@Model
public final class Exercise {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var category: String // Primary muscle group
    public var secondaryMuscles: [String] // Secondary muscle groups
    public var type: String // e.g., "Strength", "Cardio", "Flexibility"
    public var equipment: String // e.g., "Dumbbells", "Bodyweight", "Barbell"
    public var difficulty: String // e.g., "Beginner", "Intermediate", "Advanced"
    public var instructions: String?
    public var notes: String?
    public var mediaURL: String?
    public var unit: String
    public var isCustom: Bool // Whether this is a user-created exercise
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        secondaryMuscles: [String] = [],
        type: String = "Strength",
        equipment: String = "Bodyweight",
        difficulty: String = "Beginner",
        instructions: String? = nil,
        notes: String? = nil,
        mediaURL: String? = nil,
        unit: String = "kg",
        isCustom: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.secondaryMuscles = secondaryMuscles
        self.type = type
        self.equipment = equipment
        self.difficulty = difficulty
        self.instructions = instructions
        self.notes = notes
        self.mediaURL = mediaURL
        self.unit = unit
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
