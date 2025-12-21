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
    let typicalReps: Int? // Most common reps in completed sets (for progression recommendations)

    init(date: Date, sets: [WorkoutSet], targetRepMin: Int?, targetRepMax: Int?, useWarmupSet: Bool = false, progressionSetCount: Int? = nil) {
        self.date = date
        self.sets = sets

        // Sort sets by order for consistent processing
        let sortedSets = sets.sorted { $0.order < $1.order }

        // Filter out warm up set (first set by order) when calculating progression metrics
        var workingSets: [WorkoutSet]
        if useWarmupSet && !sortedSets.isEmpty {
            workingSets = Array(sortedSets.dropFirst())
        } else {
            workingSets = sortedSets
        }

        // Limit to first N sets if progressionSetCount is specified
        let setsForCalculation: [WorkoutSet]
        if let count = progressionSetCount, count > 0 {
            setsForCalculation = Array(workingSets.prefix(count))
        } else {
            setsForCalculation = workingSets
        }

        // Calculate top weight (from working sets only)
        self.topWeight = setsForCalculation.compactMap { $0.weight }.max() ?? 0

        // Calculate total volume (convert to kg for consistency, from working sets only)
        self.totalVolume = setsForCalculation.reduce(0.0) { sum, set in
            guard let weight = set.weight, let reps = set.reps else { return sum }
            return sum + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
        }

        // Calculate E1RM from first working set (before fatigue)
        self.estimatedOneRepMax = E1RMCalculator.fromSession(setsForCalculation)

        // Get typical reps (most common reps value in completed working sets)
        let completedSetsReps = setsForCalculation.compactMap { set -> Int? in
            guard set.isCompleted, let reps = set.reps else { return nil }
            return reps
        }

        if !completedSetsReps.isEmpty {
            // Find the most common reps value (mode)
            let repsCounts = Dictionary(grouping: completedSetsReps) { $0 }.mapValues { $0.count }
            self.typicalReps = repsCounts.max(by: { $0.value < $1.value })?.key
        } else {
            self.typicalReps = nil
        }

        // Check if target reps were hit (all working sets meet minimum, exceeding max is OK)
        if let minReps = targetRepMin, targetRepMax != nil {
            self.hitTargetReps = setsForCalculation.allSatisfy { set in
                guard let reps = set.reps, set.isCompleted else { return false }
                // Hitting minimum is sufficient - exceeding max indicates readiness to progress
                return reps >= minReps
            }
        } else {
            self.hitTargetReps = false
        }
    }
}

// MARK: - Progression Status

enum ProgressionStatus {
    case readyToIncreaseReps(recommendedReps: Int)  // Increase reps at current weight
    case readyToIncreaseWeight(recommendedWeight: Double, resetReps: Int)  // Increase weight, reset to min reps
    case progressingTowardTarget
    case belowTarget  // Reps below minimum - suggest lowering weight or adjusting range
    case needsRest  // Weight decreased - suggest taking rest days
    case insufficientData

    var title: String {
        switch self {
        case .readyToIncreaseReps: return "Ready to Progress!"
        case .readyToIncreaseWeight: return "Ready to Progress!"
        case .progressingTowardTarget: return "Progressing Toward Target"
        case .belowTarget: return "Below Target Range"
        case .needsRest: return "Consider Resting"
        case .insufficientData: return "Insufficient Data"
        }
    }

    var message: String {
        getMessage(unit: "kg")
    }

    func getMessage(unit: String) -> String {
        switch self {
        case .readyToIncreaseReps(let reps):
            return "Great work! Try \(reps) reps at the same weight next session."
        case .readyToIncreaseWeight(let weight, let reps):
            let weightStr = String(format: "%.1f", weight)
            return "You've hit the top of your range! Increase weight to \(weightStr)\(unit) and reset reps to \(reps)."
        case .progressingTowardTarget:
            return "You're getting closer! Keep at this weight until you hit all target reps."
        case .belowTarget:
            return "Reps are below your target range. Consider lowering the weight or adjusting your rep range in settings."
        case .needsRest:
            return "You're lifting less than last session. Consider taking a few days rest to recover."
        case .insufficientData:
            return "Complete a few more sessions to get progression recommendations."
        }
    }

    var color: String {
        switch self {
        case .readyToIncreaseReps, .readyToIncreaseWeight: return "green"
        case .progressingTowardTarget: return "blue"
        case .belowTarget: return "orange"
        case .needsRest: return "yellow"
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
            useWarmupSet: exercise.useWarmupSet,
            progressionSetCount: exercise.progressionSetCount,
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

        // Check if recently regressed from higher weight
        if didRecentlyRegress(sessions: sessions) {
            return .needsRest
        }

        // Check if ready to progress (rep increase or weight increase)
        if let progressionRecommendation = getProgressionRecommendation(
            latestSession: latestSession,
            exercise: exercise
        ) {
            return progressionRecommendation
        }

        // Check if progressing toward target
        if isProgressingTowardTarget(sessions: sessions) {
            return .progressingTowardTarget
        }

        // Default: below target
        return .belowTarget
    }

    /// Gets recent workout sessions for an exercise
    static func getRecentSessions(
        exerciseId: UUID,
        count: Int,
        targetRepMin: Int?,
        targetRepMax: Int?,
        useWarmupSet: Bool,
        progressionSetCount: Int?,
        modelContext: ModelContext
    ) -> [SessionSummary] {
        // Fetch only completed sets for progression analysis
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId && $0.isCompleted == true },
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
                targetRepMax: targetRepMax,
                useWarmupSet: useWarmupSet,
                progressionSetCount: progressionSetCount
            )
        }
    }

    // MARK: - Private Helper Methods

    /// Gets progression recommendation based on latest session
    /// Returns rep increase recommendation if below max, weight increase if at max
    private static func getProgressionRecommendation(
        latestSession: SessionSummary,
        exercise: Exercise
    ) -> ProgressionStatus? {
        // Must have hit target reps in latest session
        guard latestSession.hitTargetReps else { return nil }
        
        // Must have typical reps value
        guard let typicalReps = latestSession.typicalReps,
              let minReps = exercise.targetRepMin,
              let maxReps = exercise.targetRepMax else { return nil }
        
        // If at or above max reps, suggest weight increase and reset to min reps
        if typicalReps >= maxReps {
            let nextWeight = calculateNextWeight(currentWeight: latestSession.topWeight, unit: exercise.unit, exercise: exercise)
            return .readyToIncreaseWeight(recommendedWeight: nextWeight, resetReps: minReps)
        }
        
        // If below max reps, suggest rep increase
        if typicalReps >= minReps && typicalReps < maxReps {
            let nextReps = typicalReps + 1
            // Make sure we don't exceed max (though this should be handled above)
            let recommendedReps = min(nextReps, maxReps)
            return .readyToIncreaseReps(recommendedReps: recommendedReps)
        }
        
        return nil
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
    private static func calculateNextWeight(currentWeight: Double, unit: String, exercise: Exercise) -> Double {
        // Determine increment based on exercise category and unit
        let increment: Double
        let upperBodyCategories = ["Chest", "Back", "Shoulders", "Biceps", "Triceps"]

        if unit.lowercased() == "lbs" {
            // For lbs: upper body gets 5 lbs, lower body gets 10 lbs
            increment = upperBodyCategories.contains(exercise.primaryCategory) ? 5.0 : 10.0
        } else {
            // For kg: upper body gets 2.5 kg, lower body gets 5 kg
            increment = upperBodyCategories.contains(exercise.primaryCategory) ? 2.5 : 5.0
        }

        return currentWeight + increment
    }

    // MARK: - Live Progression Analysis

    /// Analyzes progression based on current (uncommitted) sets vs historical completed sets.
    /// This allows showing progression recommendations BEFORE sets are checked off.
    static func analyzeLiveProgression(
        exercise: Exercise,
        currentSets: [(weight: Double?, reps: Int?)],
        modelContext: ModelContext
    ) -> ProgressionStatus {
        // Must have target rep range configured
        guard let minReps = exercise.targetRepMin,
              let maxReps = exercise.targetRepMax else {
            return .insufficientData
        }

        // Filter current sets based on exercise settings
        var workingSets = currentSets

        // Skip warm up set if enabled
        if exercise.useWarmupSet && !workingSets.isEmpty {
            workingSets = Array(workingSets.dropFirst())
        }

        // Limit to progression set count if configured
        if let setCount = exercise.progressionSetCount, setCount > 0 {
            workingSets = Array(workingSets.prefix(setCount))
        }

        // Need at least one working set with data
        let setsWithData = workingSets.filter { $0.weight != nil && $0.reps != nil }
        guard !setsWithData.isEmpty else {
            return .insufficientData
        }

        // Get the last completed session (excluding today)
        let lastSession = getLastCompletedSession(
            exerciseId: exercise.id,
            targetRepMin: minReps,
            targetRepMax: maxReps,
            useWarmupSet: exercise.useWarmupSet,
            progressionSetCount: exercise.progressionSetCount,
            modelContext: modelContext
        )

        // Calculate current session metrics from input
        let currentWeight = setsWithData.compactMap { $0.weight }.max() ?? 0
        let currentReps = setsWithData.compactMap { $0.reps }

        // Get typical reps (mode) from current input
        guard !currentReps.isEmpty else {
            return .insufficientData
        }
        let repsCounts = Dictionary(grouping: currentReps) { $0 }.mapValues { $0.count }
        let typicalReps = repsCounts.max(by: { $0.value < $1.value })?.key ?? currentReps[0]

        // Check if all current sets hit minimum target reps
        let allHitMinimum = setsWithData.allSatisfy { set in
            guard let reps = set.reps else { return false }
            return reps >= minReps
        }

        // If no previous session, check if current input meets targets
        guard let lastSession = lastSession else {
            if allHitMinimum && typicalReps >= maxReps {
                // First session and already at max reps - suggest this is a good starting point
                return .insufficientData // Not enough history to recommend weight increase
            } else if allHitMinimum {
                return .progressingTowardTarget
            }
            return .insufficientData
        }

        // Compare current input against last session
        let lastWeight = lastSession.topWeight
        let lastTypicalReps = lastSession.typicalReps ?? minReps

        // Check if user increased weight
        let weightIncreased = currentWeight > lastWeight + weightTolerance

        // Check if user is at same weight
        let sameWeight = abs(currentWeight - lastWeight) <= weightTolerance

        // If weight increased, check if they reset reps appropriately
        if weightIncreased {
            if allHitMinimum {
                // Good! They increased weight and are hitting minimum reps
                return .progressingTowardTarget
            } else {
                // Weight went up but reps dropped below minimum - might be too aggressive
                return .belowTarget
            }
        }

        // If at same weight, check rep progression
        if sameWeight {
            if typicalReps >= maxReps && allHitMinimum {
                // At top of rep range - ready to increase weight!
                let nextWeight = calculateNextWeight(currentWeight: currentWeight, unit: exercise.unit, exercise: exercise)
                return .readyToIncreaseWeight(recommendedWeight: nextWeight, resetReps: minReps)
            } else if typicalReps > lastTypicalReps && allHitMinimum {
                // Reps increased - progressing!
                if typicalReps < maxReps {
                    return .readyToIncreaseReps(recommendedReps: typicalReps + 1)
                }
                return .progressingTowardTarget
            } else if allHitMinimum {
                // Maintaining at same weight/reps
                return .progressingTowardTarget
            } else {
                // Same weight but reps below minimum
                return .belowTarget
            }
        }

        // Weight decreased from last session
        if currentWeight < lastWeight - weightTolerance {
            return .needsRest
        }

        return .belowTarget
    }

    /// Gets the most recent completed session (excluding today) for comparison
    private static func getLastCompletedSession(
        exerciseId: UUID,
        targetRepMin: Int,
        targetRepMax: Int,
        useWarmupSet: Bool,
        progressionSetCount: Int?,
        modelContext: ModelContext
    ) -> SessionSummary? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        // Fetch completed sets from before today
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate {
                $0.exerciseId == exerciseId &&
                $0.isCompleted == true &&
                $0.date < startOfToday
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let allSets = try? modelContext.fetch(descriptor), !allSets.isEmpty else {
            return nil
        }

        // Group by date and get most recent
        let groupedByDate = Dictionary(grouping: allSets) { set in
            calendar.startOfDay(for: set.date)
        }

        guard let mostRecentDate = groupedByDate.keys.max(),
              let sets = groupedByDate[mostRecentDate] else {
            return nil
        }

        return SessionSummary(
            date: mostRecentDate,
            sets: sets,
            targetRepMin: targetRepMin,
            targetRepMax: targetRepMax,
            useWarmupSet: useWarmupSet,
            progressionSetCount: progressionSetCount
        )
    }
}
