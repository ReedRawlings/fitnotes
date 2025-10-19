import Foundation
import SwiftData

// MARK: - WorkoutService (Individual Day's Exercises)
public final class WorkoutService {
    public static let shared = WorkoutService()
    private init() {}

    public func createWorkout(
        name: String,
        date: Date = Date(),
        notes: String? = nil,
        modelContext: ModelContext
    ) -> Workout {
        let workout = Workout(
            name: name,
            date: date,
            notes: notes
        )
        modelContext.insert(workout)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving workout: \(error)")
        }
        
        return workout
    }
    
    public func addExerciseToWorkout(
        workout: Workout,
        exerciseId: UUID,
        sets: Int = 1,
        reps: Int? = nil,
        weight: Double? = nil,
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        modelContext: ModelContext
    ) -> WorkoutExercise {
        let order = workout.exercises.count + 1
        
        let workoutExercise = WorkoutExercise(
            exerciseId: exerciseId,
            order: order,
            sets: sets,
            reps: reps,
            weight: weight,
            duration: duration,
            distance: distance,
            notes: notes
        )
        
        workoutExercise.workout = workout
        modelContext.insert(workoutExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving workout exercise: \(error)")
        }
        
        return workoutExercise
    }
    
    public func removeExerciseFromWorkout(
        workoutExercise: WorkoutExercise,
        modelContext: ModelContext
    ) {
        modelContext.delete(workoutExercise)
        
        // Reorder remaining exercises
        if let workout = workoutExercise.workout {
            let remainingExercises = workout.exercises
                .filter { $0.id != workoutExercise.id }
                .sorted { $0.order < $1.order }
            
            for (index, exercise) in remainingExercises.enumerated() {
                exercise.order = index + 1
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error removing workout exercise: \(error)")
        }
    }
    
    public func reorderExercises(
        workout: Workout,
        from: IndexSet,
        to: Int,
        modelContext: ModelContext
    ) {
        workout.exercises.move(fromOffsets: from, toOffset: to)
        
        // Update order values
        for (index, exercise) in workout.exercises.enumerated() {
            exercise.order = index + 1
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error reordering exercises: \(error)")
        }
    }
    
    public func getTodaysWorkout(modelContext: ModelContext) -> Workout? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.date >= today && workout.date < tomorrow
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            return workouts.first
        } catch {
            print("Error fetching today's workout: \(error)")
            return nil
        }
    }
    
    public func getWorkoutsForWeek(modelContext: ModelContext) -> [Workout] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? today
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.date >= weekStart && workout.date < weekEnd
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching week's workouts: \(error)")
            return []
        }
    }
    
}

// MARK: - RoutineService (Template Management)
public final class RoutineService {
    public static let shared = RoutineService()
    private init() {}
    
    // MARK: - Routine Template Management
    
    public func createRoutine(
        name: String,
        description: String? = nil,
        modelContext: ModelContext
    ) -> Routine {
        let routine = Routine(
            name: name,
            routineDescription: description
        )
        modelContext.insert(routine)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving routine: \(error)")
        }
        
        return routine
    }
    
    public func addExerciseToRoutine(
        routine: Routine,
        exerciseId: UUID,
        sets: Int = 1,
        reps: Int? = nil,
        weight: Double? = nil,
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        modelContext: ModelContext
    ) -> RoutineExercise {
        let order = routine.exercises.count + 1
        
        let routineExercise = RoutineExercise(
            exerciseId: exerciseId,
            order: order,
            sets: sets,
            reps: reps,
            weight: weight,
            duration: duration,
            distance: distance,
            notes: notes
        )
        
        routineExercise.routine = routine
        modelContext.insert(routineExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving routine exercise: \(error)")
        }
        
        return routineExercise
    }
    
    public func removeExerciseFromRoutine(
        routineExercise: RoutineExercise,
        modelContext: ModelContext
    ) {
        modelContext.delete(routineExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Error removing routine exercise: \(error)")
        }
    }
    
    public func deleteRoutine(
        routine: Routine,
        modelContext: ModelContext
    ) {
        modelContext.delete(routine)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting routine: \(error)")
        }
    }
    
    // MARK: - Last Completed Date Queries
    
    public func getLastUsedDate(for routine: Routine, modelContext: ModelContext) -> Date? {
        let routineId = routine.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.routineTemplateId == routineId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            return workouts.first?.date
        } catch {
            print("Error fetching last used date: \(error)")
            return nil
        }
    }
    
    public func getDaysSinceLastUsed(for routine: Routine, modelContext: ModelContext) -> String {
        guard let lastUsedDate = getLastUsedDate(for: routine, modelContext: modelContext) else {
            return "Never used"
        }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: lastUsedDate, to: Date()).day ?? 0
        
        if days == 0 {
            return "Last used: Today"
        } else if days == 1 {
            return "Last used: 1 day ago"
        } else {
            return "Last used: \(days) days ago"
        }
    }
    
    // MARK: - Create Workout from Routine Template
    
    public func createWorkoutFromTemplate(
        routine: Routine,
        date: Date = Date(),
        notes: String? = nil,
        modelContext: ModelContext
    ) -> Workout {
        let workout = Workout(
            name: routine.name,
            date: date,
            notes: notes,
            routineTemplateId: routine.id
        )
        modelContext.insert(workout)
        
        // Copy exercises from template
        for templateExercise in routine.exercises.sorted(by: { $0.order < $1.order }) {
            let workoutExercise = WorkoutExercise(
                exerciseId: templateExercise.exerciseId,
                order: templateExercise.order,
                sets: templateExercise.sets,
                reps: templateExercise.reps,
                weight: templateExercise.weight,
                duration: templateExercise.duration,
                distance: templateExercise.distance,
                notes: templateExercise.notes
            )
            workoutExercise.workout = workout
            modelContext.insert(workoutExercise)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error creating workout from template: \(error)")
        }
        
        return workout
    }
}