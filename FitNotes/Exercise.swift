import Foundation
import SwiftData

@Model
public final class Exercise {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var primaryCategory: String // Primary muscle group
    public var secondaryCategories: [String] // Secondary muscle groups
    public var equipment: String // e.g., "Machine", "Free Weight", "Body"
    public var notes: String?
    public var unit: String
    public var restTimerDuration: Int = 60
    public var autoStartRestTimer: Bool = true
    public var isCustom: Bool // Whether this is a user-created exercise
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        primaryCategory: String,
        secondaryCategories: [String] = [],
        equipment: String = "Free Weight",
        notes: String? = nil,
        unit: String = "kg",
        restTimerDuration: Int = 60,
        autoStartRestTimer: Bool = true,
        isCustom: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.primaryCategory = primaryCategory
        self.secondaryCategories = secondaryCategories
        self.equipment = equipment
        self.notes = notes
        self.unit = unit
        self.restTimerDuration = restTimerDuration
        self.autoStartRestTimer = autoStartRestTimer
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
