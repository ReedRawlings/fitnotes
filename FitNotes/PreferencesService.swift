import Foundation
import SwiftData

public final class PreferencesService {
    public static let shared = PreferencesService()
    private init() {}
    
    /// Gets or creates the single UserPreferences record
    public func getOrCreatePreferences(modelContext: ModelContext) -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        
        do {
            let preferences = try modelContext.fetch(descriptor)
            if let existing = preferences.first {
                return existing
            } else {
                // Create new preferences with defaults
                let newPreferences = UserPreferences()
                modelContext.insert(newPreferences)
                try modelContext.save()
                return newPreferences
            }
        } catch {
            print("Error fetching preferences: \(error)")
            // Return a new instance if fetch fails
            let newPreferences = UserPreferences()
            modelContext.insert(newPreferences)
            try? modelContext.save()
            return newPreferences
        }
    }
    
    /// Gets the default weight unit
    public func getDefaultWeightUnit(modelContext: ModelContext) -> String {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.defaultWeightUnit
    }
    
    /// Gets the default rest seconds
    public func getDefaultRestSeconds(modelContext: ModelContext) -> Int {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.defaultRestSeconds
    }
    
    /// Gets the default stats display preference
    public func getDefaultStatsDisplayPreference(modelContext: ModelContext) -> StatsDisplayPreference {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.defaultStatsDisplayPreference
    }
    
    /// Gets the keep current routine view preference
    public func getKeepCurrentRoutineView(modelContext: ModelContext) -> Bool {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.keepCurrentRoutineView
    }
    
    /// Gets the keep current workout view preference
    public func getKeepCurrentWorkoutView(modelContext: ModelContext) -> Bool {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.keepCurrentWorkoutView
    }
    
    /// Saves preferences changes
    public func savePreferences(_ preferences: UserPreferences, modelContext: ModelContext) {
        preferences.updatedAt = Date()
        do {
            try modelContext.save()
        } catch {
            print("Error saving preferences: \(error)")
        }
    }
}

