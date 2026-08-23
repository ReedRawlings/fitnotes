import Foundation
import SwiftData

// MARK: - ExerciseSessionSummary
public struct ExerciseSessionSummary: Identifiable {
    public let id = UUID()
    public let date: Date
    public let setsSummary: String
    public let workoutId: UUID
    
    public init(date: Date, setsSummary: String, workoutId: UUID) {
        self.date = date
        self.setsSummary = setsSummary
        self.workoutId = workoutId
    }
}

// MARK: - ExerciseService
public final class ExerciseService {
    public static let shared = ExerciseService()
    private init() {}
    
    // MARK: - Get Last Session for Exercise

    /// Returns the most recent set of WorkoutSet records for this exercise (grouped by date).
    /// Used to pre-populate new workouts.
    /// Only considers completed sets so hydrated placeholder sets (e.g. from a skipped
    /// routine day) are never treated as the "last session".
    public func getLastSessionForExercise(
        exerciseId: UUID,
        modelContext: ModelContext
    ) -> [WorkoutSet]? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.exerciseId == exerciseId &&
                workoutSet.isCompleted == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let allSets = try modelContext.fetch(descriptor)

            // Group by date (most recent first)
            let groupedByDate = Dictionary(grouping: allSets) { Calendar.current.startOfDay(for: $0.date) }

            // Get the most recent date
            guard let mostRecentDate = groupedByDate.keys.max() else {
                return nil
            }

            // Return sets from the most recent date, sorted by order
            let lastSessionSets = groupedByDate[mostRecentDate] ?? []
            return lastSessionSets.sorted { $0.order < $1.order }

        } catch {
            print("Error fetching last session for exercise: \(error)")
            return nil
        }
    }

    /// Returns the most recent session for this exercise, excluding a specific date.
    /// Used for volume comparison during active workouts.
    /// Only returns completed sets for accurate historical comparison.
    public func getLastSessionForExerciseExcludingDate(
        exerciseId: UUID,
        excludeDate: Date,
        modelContext: ModelContext
    ) -> [WorkoutSet]? {
        let startOfExcludedDay = Calendar.current.startOfDay(for: excludeDate)
        let endOfExcludedDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfExcludedDay) ?? excludeDate

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.exerciseId == exerciseId &&
                workoutSet.isCompleted == true &&
                (workoutSet.date < startOfExcludedDay || workoutSet.date >= endOfExcludedDay)
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let allSets = try modelContext.fetch(descriptor)

            // Group by date (most recent first)
            let groupedByDate = Dictionary(grouping: allSets) { Calendar.current.startOfDay(for: $0.date) }

            // Get the most recent date (excluding today)
            guard let mostRecentDate = groupedByDate.keys.max() else {
                return nil
            }

            // Return sets from the most recent date, sorted by order
            let lastSessionSets = groupedByDate[mostRecentDate] ?? []
            return lastSessionSets.sorted { $0.order < $1.order }

        } catch {
            print("Error fetching last session for exercise (excluding date): \(error)")
            return nil
        }
    }
    
    // MARK: - Get Exercise History

    /// Returns all historical sessions for this exercise, sorted by date (most recent first).
    /// Used in the "View History" modal.
    public func getExerciseHistory(
        exerciseId: UUID,
        unit: String,
        modelContext: ModelContext
    ) -> [ExerciseSessionSummary] {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.exerciseId == exerciseId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allSets = try modelContext.fetch(descriptor)
            
            // Group by date
            let groupedByDate = Dictionary(grouping: allSets) { Calendar.current.startOfDay(for: $0.date) }
            
            // Create summaries for each date
            var summaries: [ExerciseSessionSummary] = []
            
            for (date, sets) in groupedByDate {
                let sortedSets = sets.sorted { $0.order < $1.order }
                
                // Create summary string like "225kg × 5/5/3"
                let setsSummary = createSetsSummary(from: sortedSets, unit: unit)
                
                let summary = ExerciseSessionSummary(
                    date: date,
                    setsSummary: setsSummary,
                    workoutId: UUID() // Generate a unique ID for each date group
                )
                summaries.append(summary)
            }
            
            // Sort by date (most recent first)
            return summaries.sorted { $0.date > $1.date }
            
        } catch {
            print("Error fetching exercise history: \(error)")
            return []
        }
    }
    
    // MARK: - Helper Methods

    /// Calculates total volume from a collection of sets.
    /// Volume = sum of (weight × reps) for all sets with both weight and reps.
    /// Weights are converted to kg for consistency.
    public func calculateVolumeFromSets(_ sets: [WorkoutSet]) -> Double {
        sets.reduce(0) { total, set in
            guard let weight = set.weight, let reps = set.reps else { return total }
            return total + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
        }
    }

    private func createSetsSummary(from sets: [WorkoutSet], unit: String) -> String {
        guard !sets.isEmpty else { return "No sets" }

        // Group by weight to create summary like "225kg × 5/5/3"
        let weight = sets.first?.weight ?? 0
        let reps = sets.compactMap { $0.reps }.map { "\($0)" }.joined(separator: "/")

        if weight > 0 {
            return "\(Int(weight))\(unit) × \(reps)"
        } else {
            return "\(reps) reps"
        }
    }
    
    // MARK: - Get Exercise by ID
    
    public func getExercise(by id: UUID, modelContext: ModelContext) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.id == id
            }
        )
        
        do {
            let exercises = try modelContext.fetch(descriptor)
            return exercises.first
        } catch {
            print("Error fetching exercise: \(error)")
            return nil
        }
    }
    
    // MARK: - Get Sets by Date
    
    /// Returns all sets for a specific exercise on a specific date
    public func getSetsByDate(
        exerciseId: UUID,
        date: Date,
        modelContext: ModelContext
    ) -> [WorkoutSet] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.exerciseId == exerciseId &&
                workoutSet.date >= startOfDay &&
                workoutSet.date < endOfDay
            },
            sortBy: [SortDescriptor(\.order, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching sets by date: \(error)")
            return []
        }
    }
    
    // MARK: - Save Sets
    
    /// Saves sets for an exercise on a specific date by diffing against existing sets.
    /// Existing sets are updated in place (preserving their id, notes, duration, distance,
    /// and completedAt when completion state is unchanged); new trailing sets are inserted,
    /// and surplus sets beyond the incoming count are deleted.
    /// All sets are persisted (both completed and incomplete) to support mid-workout state.
    /// When calculating history/progression, filter for isCompleted == true at read time.
    public func saveSets(
        exerciseId: UUID,
        date: Date,
        unit: String = "kg",
        sets: [(weight: Double?, reps: Int?, rpe: Int?, rir: Int?, isCompleted: Bool)],
        modelContext: ModelContext
    ) -> Bool {
        // Normalize date to start of day to prevent duplicates from time-of-day mismatches
        let normalizedDate = Calendar.current.startOfDay(for: date)

        do {
            // Existing sets for this exercise on this date, sorted by order (see getSetsByDate)
            let existingSets = getSetsByDate(exerciseId: exerciseId, date: normalizedDate, modelContext: modelContext)

            var hasChanges = false

            for (index, setData) in sets.enumerated() {
                let order = index + 1

                // Match WorkoutSet init validation: RPE/RIR outside 0-10 are treated as nil
                let validatedRpe = setData.rpe.flatMap { (0...10).contains($0) ? $0 : nil }
                let validatedRir = setData.rir.flatMap { (0...10).contains($0) ? $0 : nil }

                if index < existingSets.count {
                    // Match by position: update the existing set in place
                    let existingSet = existingSets[index]
                    var setChanged = false

                    if existingSet.order != order {
                        existingSet.order = order
                        setChanged = true
                    }
                    if existingSet.weight != setData.weight {
                        existingSet.weight = setData.weight
                        setChanged = true
                    }
                    if existingSet.reps != setData.reps {
                        existingSet.reps = setData.reps
                        setChanged = true
                    }
                    if existingSet.rpe != validatedRpe {
                        existingSet.rpe = validatedRpe
                        setChanged = true
                    }
                    if existingSet.rir != validatedRir {
                        existingSet.rir = validatedRir
                        setChanged = true
                    }
                    if existingSet.unit != unit {
                        existingSet.unit = unit
                        setChanged = true
                    }
                    // Only touch completedAt when completion state actually changes
                    if existingSet.isCompleted != setData.isCompleted {
                        existingSet.isCompleted = setData.isCompleted
                        existingSet.completedAt = setData.isCompleted ? date : nil
                        setChanged = true
                    }

                    if setChanged {
                        existingSet.updatedAt = Date()
                        hasChanges = true
                    }
                } else {
                    // Genuinely new trailing set: insert it
                    let newSet = WorkoutSet(
                        exerciseId: exerciseId,
                        order: order,
                        reps: setData.reps,
                        weight: setData.weight,
                        unit: unit,
                        notes: nil,
                        isCompleted: setData.isCompleted,
                        completedAt: setData.isCompleted ? date : nil,
                        date: normalizedDate,
                        rpe: validatedRpe,
                        rir: validatedRir
                    )
                    modelContext.insert(newSet)
                    hasChanges = true
                }
            }

            // Delete only the sets beyond the incoming count
            if existingSets.count > sets.count {
                for surplusSet in existingSets[sets.count...] {
                    modelContext.delete(surplusSet)
                }
                hasChanges = true
            }

            // Single save, skipped entirely when nothing changed
            if hasChanges {
                try modelContext.save()
            }
            return true
        } catch {
            print("Error saving sets: \(error)")
            return false
        }
    }
    
    // MARK: - Update Set
    
    /// Updates a specific set's weight and reps
    public func updateSet(
        setId: UUID,
        weight: Double?,
        reps: Int?,
        modelContext: ModelContext
    ) -> Bool {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.id == setId
            }
        )
        
        do {
            let sets = try modelContext.fetch(descriptor)
            guard let set = sets.first else { return false }
            
            set.weight = weight
            set.reps = reps
            set.updatedAt = Date()
            
            try modelContext.save()
            return true
        } catch {
            print("Error updating set: \(error)")
            return false
        }
    }
    
    // MARK: - Delete Set

    /// Deletes a specific set
    public func deleteSet(
        setId: UUID,
        modelContext: ModelContext
    ) -> Bool {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.id == setId
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)
            guard let set = sets.first else { return false }

            modelContext.delete(set)
            try modelContext.save()
            return true
        } catch {
            print("Error deleting set: \(error)")
            return false
        }
    }

    // MARK: - Delete Sets for Exercise on Date

    /// Deletes all sets for a specific exercise on a specific date.
    /// Used when removing an exercise from a workout.
    public func deleteSetsForExerciseOnDate(
        exerciseId: UUID,
        date: Date,
        modelContext: ModelContext
    ) {
        let existingSets = getSetsByDate(exerciseId: exerciseId, date: date, modelContext: modelContext)
        for set in existingSets {
            modelContext.delete(set)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting sets for exercise on date: \(error)")
        }
    }
}
