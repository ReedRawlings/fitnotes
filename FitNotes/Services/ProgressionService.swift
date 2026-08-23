import Foundation
import SwiftData

// MARK: - E1RM Calculator

/// Calculates Estimated 1 Rep Max using the Epley formula
struct E1RMCalculator {
    /// Calculates E1RM using: weight × (1 + reps/30)
    /// Only accurate for reps in 1-10 range. A true single IS the 1RM — no inflation.
    static func calculate(weight: Double, reps: Int) -> Double? {
        guard reps >= 1 && reps <= 10 else { return nil }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// Gets E1RM from a workout set
    static func fromSet(_ set: WorkoutSet) -> Double? {
        guard let weight = set.weight, let reps = set.reps else { return nil }
        return calculate(weight: weight, reps: reps)
    }

    /// Gets E1RM from the best completed set in a session (highest estimated 1RM)
    static func fromSession(_ sets: [WorkoutSet]) -> Double? {
        sets.filter { $0.isCompleted }.compactMap { fromSet($0) }.max()
    }
}

// MARK: - Session Summary

/// Summary of a single workout session for an exercise.
///
/// `sets` must contain **every** set logged for the exercise that day (completed or not) so the
/// warm up set can be identified by its `order`. Progression metrics are then derived from the
/// completed working sets only.
struct SessionSummary {
    let date: Date
    let sets: [WorkoutSet]
    /// Heaviest completed working set, normalised to kg. `nil` when the session has no usable working set.
    let topWeightKg: Double?
    let totalVolume: Double
    let estimatedOneRepMax: Double?
    /// True when there is at least one completed working set and every one of them met the rep minimum.
    let hitTargetReps: Bool
    /// True when there is at least one completed working set and every one of them reached the top of the rep range.
    let hitTopOfRange: Bool
    /// Most common reps across completed working sets. Ties resolve to the LOWER rep count.
    let typicalReps: Int?
    /// Lowest reps across completed working sets (the limiting set).
    let minReps: Int?
    /// Completed working sets used for every metric above.
    let workingSets: [WorkoutSet]

    init(date: Date, sets: [WorkoutSet], targetRepMin: Int?, targetRepMax: Int?, useWarmupSet: Bool = false, progressionSetCount: Int? = nil) {
        self.date = date
        self.sets = sets

        // Sort sets by order for consistent processing
        let sortedSets = sets.sorted { $0.order < $1.order }

        // Drop the warm up set: the lowest-order set of the session, whether or not it was checked off
        let afterWarmup = (useWarmupSet && !sortedSets.isEmpty) ? Array(sortedSets.dropFirst()) : sortedSets

        // Only completed sets count toward progression metrics
        let completedSets = afterWarmup.filter { $0.isCompleted }

        // Limit to first N sets if progressionSetCount is specified
        let setsForCalculation: [WorkoutSet]
        if let count = progressionSetCount, count > 0 {
            setsForCalculation = Array(completedSets.prefix(count))
        } else {
            setsForCalculation = completedSets
        }
        self.workingSets = setsForCalculation

        // Calculate top weight in kg so sessions logged in different units compare correctly
        self.topWeightKg = setsForCalculation.compactMap { set -> Double? in
            guard let weight = set.weight else { return nil }
            return WeightUnitConverter.toKg(weight, from: set.unit)
        }.max()

        // Calculate total volume (convert to kg for consistency, from working sets only)
        self.totalVolume = setsForCalculation.reduce(0.0) { sum, set in
            guard let weight = set.weight, let reps = set.reps else { return sum }
            return sum + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
        }

        // Calculate E1RM from the best working set
        self.estimatedOneRepMax = E1RMCalculator.fromSession(setsForCalculation)

        let repsPerSet = setsForCalculation.compactMap { $0.reps }
        self.typicalReps = SessionSummary.mode(of: repsPerSet)
        self.minReps = repsPerSet.min()

        // Rep targets are only meaningful when at least one working set was completed
        let hasWorkingSets = !setsForCalculation.isEmpty

        // Hitting the minimum on every working set makes the session a candidate for progression
        if let minTarget = targetRepMin, hasWorkingSets {
            self.hitTargetReps = setsForCalculation.allSatisfy { set in
                guard let reps = set.reps else { return false }
                return reps >= minTarget
            }
        } else {
            self.hitTargetReps = false
        }

        // Adding weight requires EVERY working set at the top of the range, not just the typical one
        if let maxTarget = targetRepMax, hasWorkingSets {
            self.hitTopOfRange = setsForCalculation.allSatisfy { set in
                guard let reps = set.reps else { return false }
                return reps >= maxTarget
            }
        } else {
            self.hitTopOfRange = false
        }
    }

    /// Most frequent value in `values`. Ties break toward the LOWER value so the result is
    /// deterministic (Dictionary iteration order is not) and conservative.
    static func mode(of values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        let counts = Dictionary(grouping: values, by: { $0 }).mapValues { $0.count }
        return counts.max { lhs, rhs in
            lhs.value != rhs.value ? lhs.value < rhs.value : lhs.key > rhs.key
        }?.key
    }
}

// MARK: - Progression Status

enum ProgressionStatus {
    case readyToIncreaseReps(recommendedReps: Int)  // Increase reps at current weight
    case readyToIncreaseWeight(recommendedWeight: Double, resetReps: Int)  // Increase weight, reset to min reps
    case progressingTowardTarget
    case belowTarget  // Reps below minimum - suggest lowering weight or adjusting range
    case insufficientData

    var title: String {
        switch self {
        case .readyToIncreaseReps: return "Ready to Progress!"
        case .readyToIncreaseWeight: return "Ready to Progress!"
        case .progressingTowardTarget: return "Progressing Toward Target"
        case .belowTarget: return "Below Target Range"
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
        case .insufficientData:
            return "Complete a few more sessions to get progression recommendations."
        }
    }

    var color: String {
        switch self {
        case .readyToIncreaseReps, .readyToIncreaseWeight: return "green"
        case .progressingTowardTarget: return "blue"
        case .belowTarget: return "orange"
        case .insufficientData: return "gray"
        }
    }
}

// MARK: - Progression Service

class ProgressionService {

    // MARK: - Constants

    private static let volumeTolerance = 0.10  // 10% tolerance
    private static let e1rmTolerance = 0.05    // 5% tolerance
    private static let weightToleranceValue = 0.1  // Ignore differences under 0.1 of the exercise's own unit
    private static let sessionsToAnalyze = 4   // Analyze last 4 sessions
    private static let consecutiveTargetSessions = 2  // Need 2 sessions hitting targets

    /// Weight comparisons all happen in kg, so the tolerance is expressed in kg too.
    /// A 0.1 lbs slop is a slightly larger kg slop — hence the unit-aware conversion.
    private static func weightToleranceKg(unit: String) -> Double {
        WeightUnitConverter.toKg(weightToleranceValue, from: unit)
    }

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
        // Fetch every set for the exercise — the warm up set is identified by its order within the
        // full session, so incomplete sets have to be visible here even though only completed sets
        // feed the progression metrics.
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
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

        // A day only counts as a session once something was checked off
        let sessionDates = groupedByDate.filter { _, sets in sets.contains { $0.isCompleted } }.keys

        // Sort dates descending and take the most recent
        let sortedDates = sessionDates.sorted(by: >).prefix(count)

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

        guard let minReps = exercise.targetRepMin,
              let maxReps = exercise.targetRepMax else { return nil }

        // Only add weight once EVERY working set reached the top of the range.
        // 12/12/8 in an 8-12 range still has work to do at this weight.
        if latestSession.hitTopOfRange, let topWeightKg = latestSession.topWeightKg {
            let nextWeight = calculateNextWeight(currentWeightKg: topWeightKg, exercise: exercise)
            return .readyToIncreaseWeight(recommendedWeight: nextWeight, resetReps: minReps)
        }

        // Otherwise keep the weight and chase the top of the range
        guard let typicalReps = latestSession.typicalReps, typicalReps >= minReps else { return nil }
        let recommendedReps = min(typicalReps + 1, maxReps)
        return .readyToIncreaseReps(recommendedReps: recommendedReps)
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
    private static func isWeightFlat(session1: SessionSummary, session2: SessionSummary, unit: String) -> Bool {
        guard let weight1 = session1.topWeightKg, let weight2 = session2.topWeightKg else { return false }
        return abs(weight1 - weight2) <= weightToleranceKg(unit: unit)
    }

    /// Calculate the next recommended weight, expressed in the exercise's own unit
    /// - Parameter currentWeightKg: The current top working weight, normalised to kg
    private static func calculateNextWeight(currentWeightKg: Double, exercise: Exercise) -> Double {
        // Determine increment based on exercise category and unit
        let increment: Double
        let upperBodyCategories = ["Chest", "Back", "Shoulders", "Biceps", "Triceps"]
        let unit = exercise.unit

        if unit.lowercased() == "lbs" {
            // For lbs: upper body gets 5 lbs, lower body gets 10 lbs
            increment = upperBodyCategories.contains(exercise.primaryCategory) ? 5.0 : 10.0
        } else {
            // For kg: upper body gets 2.5 kg, lower body gets 5 kg
            increment = upperBodyCategories.contains(exercise.primaryCategory) ? 2.5 : 5.0
        }

        // Convert to the display unit before adding the increment, so the increment and the
        // weight are always in the same unit
        return WeightUnitConverter.fromKg(currentWeightKg, to: unit) + increment
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

        // Calculate current session metrics from input.
        // Live input is entered in the exercise's own unit; normalise to kg for comparisons.
        let currentWeight = setsWithData.compactMap { $0.weight }.max() ?? 0
        let currentWeightKg = WeightUnitConverter.toKg(currentWeight, from: exercise.unit)
        let currentReps = setsWithData.compactMap { $0.reps }

        // Get typical reps (mode, ties favouring the lower count) from current input
        guard let typicalReps = SessionSummary.mode(of: currentReps) else {
            return .insufficientData
        }

        // Check if all current sets hit minimum target reps
        let allHitMinimum = setsWithData.allSatisfy { set in
            guard let reps = set.reps else { return false }
            return reps >= minReps
        }

        // Adding weight requires every set at the top of the range, not just the typical set
        let allAtTopOfRange = setsWithData.allSatisfy { set in
            guard let reps = set.reps else { return false }
            return reps >= maxReps
        }

        // If no previous session, check if current input meets targets
        guard let lastSession = lastSession, let lastWeightKg = lastSession.topWeightKg else {
            if allHitMinimum && allAtTopOfRange {
                // First session and already at max reps - suggest this is a good starting point
                return .insufficientData // Not enough history to recommend weight increase
            } else if allHitMinimum {
                return .progressingTowardTarget
            }
            return .insufficientData
        }

        // Compare current input against last session (both in kg)
        let lastTypicalReps = lastSession.typicalReps ?? minReps
        let tolerance = weightToleranceKg(unit: exercise.unit)

        // Check if user increased weight
        let weightIncreased = currentWeightKg > lastWeightKg + tolerance

        // Check if user is at same weight
        let sameWeight = abs(currentWeightKg - lastWeightKg) <= tolerance

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
            if allAtTopOfRange && allHitMinimum {
                // Every set is at the top of the rep range - ready to increase weight!
                let nextWeight = calculateNextWeight(currentWeightKg: currentWeightKg, exercise: exercise)
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

        // Weight decreased from last session — a deliberately lighter day is not a failure state
        if currentWeightKg < lastWeightKg - tolerance {
            return allHitMinimum ? .progressingTowardTarget : .belowTarget
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

        // Fetch every set from before today — incomplete sets are needed to locate the warm up set
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate {
                $0.exerciseId == exerciseId &&
                $0.date < startOfToday
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let allSets = try? modelContext.fetch(descriptor), !allSets.isEmpty else {
            return nil
        }

        // Group by date and get the most recent day that actually had a completed set
        let groupedByDate = Dictionary(grouping: allSets) { set in
            calendar.startOfDay(for: set.date)
        }

        guard let mostRecentDate = groupedByDate.filter({ _, sets in sets.contains { $0.isCompleted } }).keys.max(),
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
