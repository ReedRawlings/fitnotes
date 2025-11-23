import Foundation
import SwiftData

// MARK: - E1RM Calculator

/// Calculates Estimated 1 Rep Max using the Epley formula
struct E1RMCalculator {
    /// Calculates E1RM using: weight × (1 + reps/30)
    /// Only accurate for reps in 1-10 range
    static func calculate(weight: Double, reps: Int) -> Double? {
        guard reps >= 1 && reps <= 10 else { return nil }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// Gets E1RM from a workout set
    static func fromSet(_ set: WorkoutSet) -> Double? {
        guard let weight = set.weight, let reps = set.reps else { return nil }
        return calculate(weight: weight, reps: reps)
    }

    /// Gets E1RM from first completed set in a session (before fatigue)
    static func fromSession(_ sets: [WorkoutSet]) -> Double? {
        guard let firstSet = sets.first(where: { $0.isCompleted }) else { return nil }
        return fromSet(firstSet)
    }
}

// MARK: - Session Summary

/// Summary of a single workout session for an exercise
struct SessionSummary {
    let date: Date
    let sets: [WorkoutSet]
    let topWeight: Double
    let totalVolume: Double
    let estimatedOneRepMax: Double?
    let hitTargetReps: Bool

    init(date: Date, sets: [WorkoutSet], targetRepMin: Int?, targetRepMax: Int?) {
        self.date = date
        self.sets = sets

        // Calculate top weight
        self.topWeight = sets.compactMap { $0.weight }.max() ?? 0

        // Calculate total volume (convert to kg for consistency)
        self.totalVolume = sets.reduce(0.0) { sum, set in
            guard let weight = set.weight, let reps = set.reps else { return sum }
            return sum + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
        }

        // Calculate E1RM from first set (before fatigue)
        self.estimatedOneRepMax = E1RMCalculator.fromSession(sets)

        // Check if target reps were hit (all sets within range)
        if let minReps = targetRepMin, let maxReps = targetRepMax {
            self.hitTargetReps = sets.allSatisfy { set in
                guard let reps = set.reps, set.isCompleted else { return false }
                return reps >= minReps && reps <= maxReps
            }
        } else {
            self.hitTargetReps = false
        }
    }
}

// MARK: - Progression Status

enum ProgressionStatus {
    case readyToProgress(recommendedWeight: Double)
    case progressingTowardTarget
    case maintainingBelowTarget
    case decliningPerformance(percentDrop: Double)
    case recentlyRegressed
    case insufficientData

    var title: String {
        switch self {
        case .readyToProgress: return "Ready to Progress!"
        case .progressingTowardTarget: return "Progressing Toward Target"
        case .maintainingBelowTarget: return "Maintaining Below Target"
        case .decliningPerformance: return "Performance Declining"
        case .recentlyRegressed: return "Building Confidence"
        case .insufficientData: return "Insufficient Data"
        }
    }

    var message: String {
        getMessage(unit: "kg")
    }

    func getMessage(unit: String) -> String {
        switch self {
        case .readyToProgress(let weight):
            return "You've hit your targets for 2 sessions straight. Try \(String(format: "%.1f", weight)) \(unit) next session."
        case .progressingTowardTarget:
            return "You're getting closer! Keep at this weight until you hit all target reps."
        case .maintainingBelowTarget:
            return "Focus on hitting your target rep range consistently."
        case .decliningPerformance(let percent):
            return "Volume dropped \(String(format: "%.0f", abs(percent)))%. Focus on recovery - sleep, nutrition, and stress management."
        case .recentlyRegressed:
            return "Keep building confidence at this weight for another week before progressing."
        case .insufficientData:
            return "Complete a few more sessions to get progression recommendations."
        }
    }

    var color: String {
        switch self {
        case .readyToProgress: return "green"
        case .progressingTowardTarget: return "blue"
        case .maintainingBelowTarget: return "gray"
        case .decliningPerformance: return "orange"
        case .recentlyRegressed: return "yellow"
        case .insufficientData: return "gray"
        }
    }
}

// MARK: - Progression Service

class ProgressionService {

    // MARK: - Constants

    private static let volumeTolerance = 0.10  // 10% tolerance
    private static let e1rmTolerance = 0.05    // 5% tolerance
    private static let weightTolerance = 0.1   // 0.1 kg tolerance
    private static let sessionsToAnalyze = 4   // Analyze last 4 sessions
    private static let consecutiveTargetSessions = 2  // Need 2 sessions hitting targets

    // MARK: - Public Methods

    /// Analyzes progression status for an exercise
    static func analyzeProgressionStatus(
        exercise: Exercise,
        modelContext: ModelContext
    ) -> ProgressionStatus {
        // Get recent sessions
        let sessions = getRecentSessions(
            exerciseId: exercise.id,
            count: sessionsToAnalyze,
            targetRepMin: exercise.targetRepMin,
            targetRepMax: exercise.targetRepMax,
            modelContext: modelContext
        )

        // Need at least 2 sessions for analysis
        guard sessions.count >= 2 else {
            return .insufficientData
        }

        // Check if targets are configured
        guard exercise.targetRepMin != nil, exercise.targetRepMax != nil else {
            return .insufficientData
        }

        let latestSession = sessions[0]
        let previousSession = sessions[1]

        // Check for declining performance (volume drop)
        if isVolumeDeclined(current: latestSession, previous: previousSession) {
            let percentDrop = ((latestSession.totalVolume - previousSession.totalVolume) / previousSession.totalVolume) * 100
            return .decliningPerformance(percentDrop: percentDrop)
        }

        // Check if recently regressed from higher weight
        if didRecentlyRegress(sessions: sessions) {
            return .recentlyRegressed
        }

        // Check if ready to progress
        if isReadyToProgress(sessions: sessions, exercise: exercise) {
            let nextWeight = calculateNextWeight(currentWeight: latestSession.topWeight, exercise: exercise)
            return .readyToProgress(recommendedWeight: nextWeight)
        }

        // Check if progressing toward target
        if isProgressingTowardTarget(sessions: sessions) {
            return .progressingTowardTarget
        }

        // Default: maintaining below target
        return .maintainingBelowTarget
    }

    /// Gets recent workout sessions for an exercise
    static func getRecentSessions(
        exerciseId: UUID,
        count: Int,
        targetRepMin: Int?,
        targetRepMax: Int?,
        modelContext: ModelContext
    ) -> [SessionSummary] {
        // Fetch all sets for this exercise
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId && $0.isCompleted },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let allSets = try? modelContext.fetch(descriptor) else {
            return []
        }

        // Group sets by date
        let calendar = Calendar.current
        let groupedByDate = Dictionary(grouping: allSets) { set in
            calendar.startOfDay(for: set.date)
        }

        // Sort dates descending and take the most recent
        let sortedDates = groupedByDate.keys.sorted(by: >).prefix(count)

        // Create session summaries
        return sortedDates.compactMap { date in
            guard let sets = groupedByDate[date] else { return nil }
            return SessionSummary(
                date: date,
                sets: sets,
                targetRepMin: targetRepMin,
                targetRepMax: targetRepMax
            )
        }
    }

    // MARK: - Private Helper Methods

    /// Check if last 2 sessions hit targets and metrics are flat (ready to progress)
    private static func isReadyToProgress(sessions: [SessionSummary], exercise: Exercise) -> Bool {
        guard sessions.count >= consecutiveTargetSessions else { return false }

        // Get last 2 sessions
        let recentSessions = Array(sessions.prefix(consecutiveTargetSessions))

        // Both sessions must have hit target reps
        guard recentSessions.allSatisfy({ $0.hitTargetReps }) else { return false }

        let latest = recentSessions[0]
        let previous = recentSessions[1]

        // Volume should be flat
        guard isVolumeFlat(session1: latest, session2: previous) else { return false }

        // E1RM should be flat
        guard isE1RMFlat(session1: latest, session2: previous) else { return false }

        // Weight should be flat (same weight used)
        guard isWeightFlat(session1: latest, session2: previous) else { return false }

        return true
    }

    /// Check if volume is improving between sessions
    private static func isProgressingTowardTarget(sessions: [SessionSummary]) -> Bool {
        guard sessions.count >= 2 else { return false }

        // Compare last 2 sessions
        let latest = sessions[0]
        let previous = sessions[1]

        // Volume should be increasing (not flat, not declining)
        return latest.totalVolume > previous.totalVolume * (1 + volumeTolerance)
    }

    /// Check if volume has declined significantly
    private static func isVolumeDeclined(current: SessionSummary, previous: SessionSummary) -> Bool {
        return current.totalVolume < previous.totalVolume * (1 - volumeTolerance)
    }

    /// Check if volume is flat (within tolerance)
    private static func isVolumeFlat(session1: SessionSummary, session2: SessionSummary) -> Bool {
        let ratio = session1.totalVolume / session2.totalVolume
        return abs(ratio - 1.0) <= volumeTolerance
    }

    /// Check if E1RM is flat (within tolerance)
    private static func isE1RMFlat(session1: SessionSummary, session2: SessionSummary) -> Bool {
        guard let e1rm1 = session1.estimatedOneRepMax,
              let e1rm2 = session2.estimatedOneRepMax else { return false }

        let ratio = e1rm1 / e1rm2
        return abs(ratio - 1.0) <= e1rmTolerance
    }

    /// Check if weight is flat (same weight used)
    private static func isWeightFlat(session1: SessionSummary, session2: SessionSummary) -> Bool {
        return abs(session1.topWeight - session2.topWeight) <= weightTolerance
    }

    /// Check if user recently regressed from a higher weight
    private static func didRecentlyRegress(sessions: [SessionSummary]) -> Bool {
        guard sessions.count >= 3 else { return false }

        let currentWeight = sessions[0].topWeight

        // Check if any of the older sessions (2-4 sessions ago) used higher weight
        let olderSessions = Array(sessions.dropFirst(2))
        return olderSessions.contains { $0.topWeight > currentWeight + weightTolerance }
    }

    /// Calculate the next recommended weight
    private static func calculateNextWeight(currentWeight: Double, exercise: Exercise) -> Double {
        // Determine increment based on exercise category
        let increment: Double

        // Upper body exercises get smaller increments (2.5kg)
        // Lower body exercises get larger increments (5kg)
        let upperBodyCategories = ["Chest", "Back", "Shoulders", "Arms", "Biceps", "Triceps"]

        if upperBodyCategories.contains(exercise.primaryCategory) {
            increment = 2.5
        } else {
            increment = 5.0
        }

        return currentWeight + increment
    }
}
