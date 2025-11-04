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
    public var isCustom: Bool // Whether this is a user-created exercise
    public var rpeEnabled: Bool // Rate of Perceived Exertion tracking enabled
    public var rirEnabled: Bool // Reps in Reserve tracking enabled
    public var useRestTimer: Bool = false
    public var defaultRestSeconds: Int = 90  // Standard mode default
    public var useAdvancedRest: Bool = false
    public var customRestSeconds: [Int: Int] = [:]  // Dictionary: setNumber -> seconds
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
        isCustom: Bool = false,
        rpeEnabled: Bool = false,
        rirEnabled: Bool = false,
        useRestTimer: Bool = false,
        defaultRestSeconds: Int = 90,
        useAdvancedRest: Bool = false,
        customRestSeconds: [Int: Int] = [:],
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
        self.isCustom = isCustom
        // Ensure mutual exclusivity: only one can be true at a time
        if rpeEnabled && rirEnabled {
            self.rpeEnabled = true
            self.rirEnabled = false
        } else {
            self.rpeEnabled = rpeEnabled
            self.rirEnabled = rirEnabled
        }
        self.useRestTimer = useRestTimer
        self.defaultRestSeconds = defaultRestSeconds
        self.useAdvancedRest = useAdvancedRest
        self.customRestSeconds = customRestSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Helper method to set RPE/RIR mode with mutual exclusivity
    public func setRPEMode(enabled: Bool) {
        if enabled {
            self.rpeEnabled = true
            self.rirEnabled = false
        } else {
            self.rpeEnabled = false
        }
        self.updatedAt = Date()
    }
    
    public func setRIRMode(enabled: Bool) {
        if enabled {
            self.rirEnabled = true
            self.rpeEnabled = false
        } else {
            self.rirEnabled = false
        }
        self.updatedAt = Date()
    }
}
