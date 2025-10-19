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
    
    /// Returns the most recent set of WorkoutSet records for this exercise (grouped by workout session).
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
            
            // Group by workout session (most recent first)
            let groupedByWorkout = Dictionary(grouping: allSets) { $0.workoutId }
            
            // Get the most recent workout session
            guard let mostRecentWorkoutId = groupedByWorkout.keys.min(by: { workoutId1, workoutId2 in
                let sets1 = groupedByWorkout[workoutId1] ?? []
                let sets2 = groupedByWorkout[workoutId2] ?? []
                let date1 = sets1.first?.date ?? Date.distantPast
                let date2 = sets2.first?.date ?? Date.distantPast
                return date1 < date2
            }) else {
                return nil
            }
            
            // Return sets from the most recent workout, sorted by order
            let lastSessionSets = groupedByWorkout[mostRecentWorkoutId] ?? []
            return lastSessionSets.sorted { $0.order < $1.order }
            
        } catch {
            print("Error fetching last session for exercise: \(error)")
            return nil
        }
    }
    
    // MARK: - Get Exercise History
    
    /// Returns all historical sessions for this exercise, sorted by date (most recent first).
    /// Used in the "View History" modal.
    public func getExerciseHistory(
        exerciseId: UUID,
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
            
            // Group by workout session
            let groupedByWorkout = Dictionary(grouping: allSets) { $0.workoutId }
            
            // Create summaries for each workout session
            var summaries: [ExerciseSessionSummary] = []
            
            for (workoutId, sets) in groupedByWorkout {
                let sortedSets = sets.sorted { $0.order < $1.order }
                let date = sortedSets.first?.date ?? Date()
                
                // Create summary string like "225kg × 5/5/3"
                let setsSummary = createSetsSummary(from: sortedSets)
                
                let summary = ExerciseSessionSummary(
                    date: date,
                    setsSummary: setsSummary,
                    workoutId: workoutId
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
    
    private func createSetsSummary(from sets: [WorkoutSet]) -> String {
        guard !sets.isEmpty else { return "No sets" }
        
        // Group by weight to create summary like "225kg × 5/5/3"
        let weight = sets.first?.weight ?? 0
        let reps = sets.map { "\($0.reps)" }.joined(separator: "/")
        
        if weight > 0 {
            return "\(Int(weight))kg × \(reps)"
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
}
