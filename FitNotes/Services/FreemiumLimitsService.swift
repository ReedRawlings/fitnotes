import Foundation
import SwiftData

/// Centralized service for managing freemium usage limits.
/// Free users are limited to:
/// - 2 routines
/// - 2 exercises with progressive overload tracking
/// - 8 weeks (56 days) of insights data
public final class FreemiumLimitsService {
    public static let shared = FreemiumLimitsService()
    private init() {}

    // MARK: - Limit Constants

    /// Maximum number of routines for free users
    public static let maxFreeRoutines = 2

    /// Maximum number of exercises with progressive overload tracking for free users
    public static let maxFreeProgressionExercises = 2

    /// Maximum days of insights data for free users (30 days)
    public static let maxFreeInsightsDays = 30

    // MARK: - Count Methods

    /// Returns the total number of routines
    public func getRoutineCount(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Routine>()
        do {
            let routines = try modelContext.fetch(descriptor)
            return routines.count
        } catch {
            print("Error fetching routine count: \(error)")
            return 0
        }
    }

    /// Returns the number of exercises with progressive overload tracking enabled.
    /// An exercise is considered "tracked" when both targetRepMin and targetRepMax are set.
    public func getProgressionExerciseCount(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Exercise>()
        do {
            let exercises = try modelContext.fetch(descriptor)
            return exercises.filter { exercise in
                exercise.targetRepMin != nil && exercise.targetRepMax != nil
            }.count
        } catch {
            print("Error fetching progression exercise count: \(error)")
            return 0
        }
    }

    // MARK: - Validation Methods

    /// Returns true if the user can create a new routine (is premium or under limit)
    public func canCreateRoutine(isPremium: Bool, modelContext: ModelContext) -> Bool {
        if isPremium { return true }
        return getRoutineCount(modelContext: modelContext) < Self.maxFreeRoutines
    }

    /// Returns true if the user can enable progression tracking for the given exercise.
    /// Always returns true if:
    /// - User is premium
    /// - Exercise already has progression tracking enabled (allow editing)
    /// - User is under the limit
    public func canEnableProgression(for exercise: Exercise, isPremium: Bool, modelContext: ModelContext) -> Bool {
        if isPremium { return true }

        // If this exercise already has progression tracking, allow editing
        if exercise.targetRepMin != nil && exercise.targetRepMax != nil {
            return true
        }

        return getProgressionExerciseCount(modelContext: modelContext) < Self.maxFreeProgressionExercises
    }

    /// Returns true if the given number of days is within the free user limit
    public func isInsightsDaysAllowed(days: Int?, isPremium: Bool) -> Bool {
        if isPremium { return true }
        guard let days = days else { return false } // "All Time" is not allowed for free users
        return days <= Self.maxFreeInsightsDays
    }

    /// Returns the effective days for insights, capped at the free limit if not premium
    public func getEffectiveInsightsDays(requestedDays: Int?, isPremium: Bool) -> Int? {
        if isPremium { return requestedDays }
        guard let days = requestedDays else { return Self.maxFreeInsightsDays }
        return min(days, Self.maxFreeInsightsDays)
    }
}
