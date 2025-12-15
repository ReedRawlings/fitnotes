import Foundation
import SwiftData

/// Development-only helper to populate the database with fake data
/// so the UI isn't empty while building features.
///
/// This is compiled only for DEBUG builds.
public enum DevDataSeeder {
    
    /// Seeds the database with demo data if it's currently empty.
    /// Safe to call multiple times; does nothing once data exists.
    public static func seedIfNeeded(modelContext: ModelContext) {
        #if DEBUG
        // If we already have any workouts, assume the dev has real data
        let existingWorkoutsCount = (try? modelContext.fetch(FetchDescriptor<Workout>()).count) ?? 0
        if existingWorkoutsCount > 0 {
            return
        }
        
        // Ensure we have the default exercise library
        let existingExercisesCount = (try? modelContext.fetch(FetchDescriptor<Exercise>()).count) ?? 0
        if existingExercisesCount == 0 {
            ExerciseDatabaseService.shared.createDefaultExercises(modelContext: modelContext)
        }
        
        // Refresh exercises after potential seeding
        guard let bench = exercise(named: "Barbell Bench Press", modelContext: modelContext),
              let row = exercise(named: "Barbell Row", modelContext: modelContext),
              let squat = exercise(named: "Barbell Squat", modelContext: modelContext),
              let deadlift = exercise(named: "Barbell Deadlift", modelContext: modelContext),
              let ohp = exercise(named: "Overhead Press", modelContext: modelContext)
        else {
            return
        }
        
        // Create a couple of example routines
        let pushRoutine = RoutineService.shared.createRoutine(
            name: "Push Day",
            description: "Chest, shoulders, and triceps focus",
            modelContext: modelContext
        )
        _ = RoutineService.shared.addExerciseToRoutine(
            routine: pushRoutine,
            exerciseId: bench.id,
            modelContext: modelContext
        )
        _ = RoutineService.shared.addExerciseToRoutine(
            routine: pushRoutine,
            exerciseId: ohp.id,
            modelContext: modelContext
        )
        
        let strengthRoutine = RoutineService.shared.createRoutine(
            name: "Strength Full Body",
            description: "Heavy compound movements",
            modelContext: modelContext
        )
        _ = RoutineService.shared.addExerciseToRoutine(
            routine: strengthRoutine,
            exerciseId: squat.id,
            modelContext: modelContext
        )
        _ = RoutineService.shared.addExerciseToRoutine(
            routine: strengthRoutine,
            exerciseId: deadlift.id,
            modelContext: modelContext
        )
        _ = RoutineService.shared.addExerciseToRoutine(
            routine: strengthRoutine,
            exerciseId: row.id,
            modelContext: modelContext
        )
        
        // Create a few workouts across the last week with sets
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dates = (-3...0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
        
        for date in dates {
            let workout = WorkoutService.shared.getOrCreateWorkoutForDate(date: date, modelContext: modelContext)
            
            // Simple heuristic: lighter earlier in the week, heavier later
            let dayIndex = dates.firstIndex(of: date) ?? 0
            let baseBenchWeight = 70.0 + Double(dayIndex) * 2.5
            let baseSquatWeight = 100.0 + Double(dayIndex) * 5.0
            
            _ = WorkoutService.shared.addExerciseToWorkoutWithSets(
                workout: workout,
                exerciseId: bench.id,
                setData: [
                    (reps: 8, weight: baseBenchWeight, duration: nil, distance: nil),
                    (reps: 8, weight: baseBenchWeight, duration: nil, distance: nil),
                    (reps: 6, weight: baseBenchWeight + 2.5, duration: nil, distance: nil)
                ],
                modelContext: modelContext
            )
            
            _ = WorkoutService.shared.addExerciseToWorkoutWithSets(
                workout: workout,
                exerciseId: squat.id,
                setData: [
                    (reps: 5, weight: baseSquatWeight, duration: nil, distance: nil),
                    (reps: 5, weight: baseSquatWeight, duration: nil, distance: nil),
                    (reps: 5, weight: baseSquatWeight + 5.0, duration: nil, distance: nil)
                ],
                modelContext: modelContext
            )
        }
        #endif
    }
    
    private static func exercise(
        named name: String,
        modelContext: ModelContext
    ) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { $0.name == name }
        )
        return try? modelContext.fetch(descriptor).first
    }
}


