import Foundation
import SwiftData

public enum StatsDisplayPreference: String, Codable {
    case alwaysCollapsed
    case alwaysExpanded
    case rememberLastState
}

/// What a set of this exercise records. Reps-only exercises (jump rope, jump squats, burpees)
/// hide the weight column and progress/PR on reps instead of weight.
public enum ExerciseTrackingType: String, Codable, CaseIterable {
    case weightAndReps
    case repsOnly

    public var displayName: String {
        switch self {
        case .weightAndReps: return "Weight & Reps"
        case .repsOnly: return "Reps Only"
        }
    }
}

@Model
public final class Exercise {
    public var id: UUID = UUID()
    public var name: String = ""
    public var primaryCategory: String = "" // Primary muscle group

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

    public var equipment: String = "Free Weight" // e.g., "Machine", "Free Weight", "Body"
    public var notes: String?
    public var unit: String = "kg"
    public var isCustom: Bool = false // Whether this is a user-created exercise
    public var rpeEnabled: Bool = false // Rate of Perceived Exertion tracking enabled
    public var rirEnabled: Bool = false // Reps in Reserve tracking enabled
    public var useRestTimer: Bool = false
    public var defaultRestSeconds: Int = 90  // Standard mode default
    public var useAdvancedRest: Bool = false
    public var useWarmupSet: Bool = false  // First set treated as warm up, excluded from progression

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
    public var progressionSetCount: Int? = nil  // Number of sets to use for progression (nil = all sets)
    public var lastProgressionDate: Date? = nil  // When weight was last increased
    public var incrementValue: Double = 5.0  // Default increment for +/- buttons on custom keyboard (range: 1-100)
    public var autoProgress: Bool = false  // Automatically apply progression recommendations when loading sets

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

    // Added in schema V2. Stored as a String for reliable SwiftData serialization.
    @Attribute public var trackingTypeRaw: String = "weightAndReps"

    public var trackingType: ExerciseTrackingType {
        get { ExerciseTrackingType(rawValue: trackingTypeRaw) ?? .weightAndReps }
        set { trackingTypeRaw = newValue.rawValue }
    }

    public var isRepsOnly: Bool { trackingType == .repsOnly }

    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

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
        useWarmupSet: Bool = false,
        customRestSeconds: [Int: Int] = [:],
        targetRepMin: Int? = nil,
        targetRepMax: Int? = nil,
        progressionSetCount: Int? = nil,
        lastProgressionDate: Date? = nil,
        incrementValue: Double = 5.0,
        autoProgress: Bool = false,
        statsDisplayPreference: StatsDisplayPreference = StatsDisplayPreference.rememberLastState,
        statsIsExpanded: Bool = false,
        trackingType: ExerciseTrackingType = .weightAndReps,
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
        self.useWarmupSet = useWarmupSet
        // Encode customRestSeconds to JSON string
        if let data = try? JSONEncoder().encode(customRestSeconds),
           let string = String(data: data, encoding: .utf8) {
            self.customRestSecondsRaw = string
        } else {
            self.customRestSecondsRaw = "{}"
        }
        self.targetRepMin = targetRepMin
        self.targetRepMax = targetRepMax
        self.progressionSetCount = progressionSetCount
        self.lastProgressionDate = lastProgressionDate
        self.incrementValue = incrementValue
        self.autoProgress = autoProgress
        self.statsDisplayPreferenceRaw = statsDisplayPreference.rawValue
        self.statsIsExpanded = statsIsExpanded
        self.trackingTypeRaw = trackingType.rawValue
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
