import Foundation
import SwiftData

@Model
public final class Exercise {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var category: String // Primary muscle group
    public var equipment: String // e.g., "Machine", "Free Weight", "Body"
    public var notes: String?
    public var unit: String
    public var isCustom: Bool // Whether this is a user-created exercise
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        equipment: String = "Free Weight",
        notes: String? = nil,
        unit: String = "kg",
        isCustom: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.equipment = equipment
        self.notes = notes
        self.unit = unit
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
