import Foundation
import SwiftData

@Model
public final class Exercise {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var category: String // Primary muscle group
    public var type: String // e.g., "Strength", "Cardio", "Flexibility"
    public var notes: String?
    public var unit: String
    public var isCustom: Bool // Whether this is a user-created exercise
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        type: String = "Strength",
        notes: String? = nil,
        unit: String = "kg",
        isCustom: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.notes = notes
        self.unit = unit
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
