import Foundation
import SwiftData

public final class PreferencesService {
    public static let shared = PreferencesService()
    private init() {}

    // MARK: - Onboarding UserDefaults Keys
    private enum OnboardingKeys {
        static let weightUnit = "onboarding_weightUnit"
        static let defaultRestTimer = "onboarding_defaultRestTimer"
        static let autoProgress = "onboarding_autoProgress"
    }

    /// Gets or creates the single UserPreferences record.
    /// On first creation, reads onboarding values from UserDefaults.
    public func getOrCreatePreferences(modelContext: ModelContext) -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()

        do {
            let preferences = try modelContext.fetch(descriptor)
            if let existing = preferences.first {
                return existing
            } else {
                // Create new preferences, reading from onboarding UserDefaults
                let onboardingUnit = UserDefaults.standard.string(forKey: OnboardingKeys.weightUnit) ?? "lbs"
                let onboardingRestSeconds = UserDefaults.standard.integer(forKey: OnboardingKeys.defaultRestTimer)
                // If onboardingRestSeconds is 0 and key doesn't exist, default to 90
                let restSeconds = UserDefaults.standard.object(forKey: OnboardingKeys.defaultRestTimer) != nil
                    ? onboardingRestSeconds
                    : 90
                // Read autoProgress from onboarding, default to true if not set
                let onboardingAutoProgress = UserDefaults.standard.object(forKey: OnboardingKeys.autoProgress) != nil
                    ? UserDefaults.standard.bool(forKey: OnboardingKeys.autoProgress)
                    : true

                let newPreferences = UserPreferences(
                    defaultWeightUnit: onboardingUnit,
                    defaultRestSeconds: restSeconds,
                    autoProgress: onboardingAutoProgress
                )
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

    /// Returns true if rest timer should be enabled by default for new exercises.
    /// This is true when the user has set a non-zero rest timer during onboarding.
    public func shouldEnableRestTimerByDefault(modelContext: ModelContext) -> Bool {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.defaultRestSeconds > 0
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

    /// Gets the global warm up sets preference
    public func getUseWarmupSets(modelContext: ModelContext) -> Bool {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.useWarmupSets
    }

    /// Gets the global auto progress preference
    public func getAutoProgress(modelContext: ModelContext) -> Bool {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.autoProgress
    }

    /// Gets whether user has viewed the 2024 year in review
    public func getHasViewedYearInReview2024(modelContext: ModelContext) -> Bool {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        return preferences.hasViewedYearInReview2024
    }

    /// Marks the 2024 year in review as viewed
    public func markYearInReview2024AsViewed(modelContext: ModelContext) {
        let preferences = getOrCreatePreferences(modelContext: modelContext)
        preferences.hasViewedYearInReview2024 = true
        savePreferences(preferences, modelContext: modelContext)
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

