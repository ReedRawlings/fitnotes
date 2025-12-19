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
    public func getLastSessionForExercise(
        exerciseId: UUID,
        modelContext: ModelContext
    ) -> [WorkoutSet]? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.exerciseId == exerciseId
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
    
    /// Saves sets for an exercise on a specific date, replacing any existing sets.
    /// Only completed sets (isCompleted == true) are persisted to history.
    public func saveSets(
        exerciseId: UUID,
        date: Date,
        unit: String = "kg",
        sets: [(weight: Double?, reps: Int?, rpe: Int?, rir: Int?, isCompleted: Bool)],
        modelContext: ModelContext
    ) -> Bool {
        do {
            // First, delete existing sets for this exercise on this date
            let existingSets = getSetsByDate(exerciseId: exerciseId, date: date, modelContext: modelContext)
            for set in existingSets {
                modelContext.delete(set)
            }

            // Only save completed sets to history
            let completedSets = sets.filter { $0.isCompleted }

            // Create new sets (only for completed ones)
            for (index, setData) in completedSets.enumerated() {
                let newSet = WorkoutSet(
                    exerciseId: exerciseId,
                    order: index + 1,
                    reps: setData.reps,
                    weight: setData.weight,
                    unit: unit,
                    notes: nil,
                    isCompleted: true,
                    completedAt: date,
                    date: date,
                    rpe: setData.rpe,
                    rir: setData.rir
                )
                modelContext.insert(newSet)
            }

            try modelContext.save()
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
