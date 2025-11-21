import Foundation
import SwiftData

public enum StatsDisplayPreference: String, Codable {
    case alwaysCollapsed
    case alwaysExpanded
    case rememberLastState
}

@Model
public final class Exercise {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var primaryCategory: String // Primary muscle group

    // Persistent storage - uses comma-separated String for reliable SwiftData serialization
    @Attribute public var secondaryCategoriesRaw: String = ""

    // Computed property - provides type-safe array access
    public var secondaryCategories: [String] {
        get {
            secondaryCategoriesRaw.isEmpty ? [] : secondaryCategoriesRaw.split(separator: ",").map { String($0) }
        }
        set {
            secondaryCategoriesRaw = newValue.joined(separator: ",")
        }
    }

    public var equipment: String // e.g., "Machine", "Free Weight", "Body"
    public var notes: String?
    public var unit: String
    public var isCustom: Bool // Whether this is a user-created exercise
    public var rpeEnabled: Bool // Rate of Perceived Exertion tracking enabled
    public var rirEnabled: Bool // Reps in Reserve tracking enabled
    public var useRestTimer: Bool = false
    public var defaultRestSeconds: Int = 90  // Standard mode default
    public var useAdvancedRest: Bool = false

    // Persistent storage - uses JSON String for reliable SwiftData serialization
    @Attribute public var customRestSecondsRaw: String = "{}"

    // Computed property - provides type-safe dictionary access
    public var customRestSeconds: [Int: Int] {
        get {
            guard let data = customRestSecondsRaw.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([Int: Int].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                customRestSecondsRaw = string
            }
        }
    }

    // Progressive overload tracking
    public var targetRepMin: Int? = nil  // Bottom of target range (e.g., 5 in "5-8 reps")
    public var targetRepMax: Int? = nil  // Top of target range (e.g., 8 in "5-8 reps")
    public var lastProgressionDate: Date? = nil  // When weight was last increased
    public var incrementValue: Double = 5.0  // Default increment for +/- buttons on custom keyboard (range: 1-100)

    // Stats display preferences
    // Persistent storage - uses String for reliable SwiftData serialization
    @Attribute public var statsDisplayPreferenceRaw: String = "rememberLastState"
    public var statsIsExpanded: Bool = false

    // Computed property - provides type-safe enum access
    public var statsDisplayPreference: StatsDisplayPreference {
        get {
            StatsDisplayPreference(rawValue: statsDisplayPreferenceRaw) ?? .rememberLastState
        }
        set {
            statsDisplayPreferenceRaw = newValue.rawValue
        }
    }

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
        targetRepMin: Int? = nil,
        targetRepMax: Int? = nil,
        lastProgressionDate: Date? = nil,
        incrementValue: Double = 5.0,
        statsDisplayPreference: StatsDisplayPreference = StatsDisplayPreference.rememberLastState,
        statsIsExpanded: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.primaryCategory = primaryCategory
        self.secondaryCategoriesRaw = secondaryCategories.joined(separator: ",")
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
        // Encode customRestSeconds to JSON string
        if let data = try? JSONEncoder().encode(customRestSeconds),
           let string = String(data: data, encoding: .utf8) {
            self.customRestSecondsRaw = string
        } else {
            self.customRestSecondsRaw = "{}"
        }
        self.targetRepMin = targetRepMin
        self.targetRepMax = targetRepMax
        self.lastProgressionDate = lastProgressionDate
        self.incrementValue = incrementValue
        self.statsDisplayPreferenceRaw = statsDisplayPreference.rawValue
        self.statsIsExpanded = statsIsExpanded
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
