import Foundation
import SwiftData

// MARK: - WorkoutService (Individual Day's Exercises)
public final class WorkoutService {
    public static let shared = WorkoutService()
    private init() {}
    
    private func saveContextAsync(_ modelContext: ModelContext, logMessage: String) {
        // Use asyncAfter to defer the save to the next run loop, allowing UI to update first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            do {
                try modelContext.save()
            } catch {
                print("\(logMessage): \(error)")
            }
        }
    }

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
        // Prevent duplicates: if the exercise is already in this workout, return the existing item
        if let existing = workout.exercises.first(where: { $0.exerciseId == exerciseId }) {
            return existing
        }
        let order = workout.exercises.count + 1
        
        let workoutExercise = WorkoutExercise(
            exerciseId: exerciseId,
            order: order,
            notes: notes
        )
        
        workoutExercise.workout = workout
        workout.exercises.append(workoutExercise)  // Add to workout's exercises array
        modelContext.insert(workoutExercise)
        
        // Note: Sets are now managed independently through ExerciseService
        // This method is kept for backward compatibility but sets should be added via ExerciseService
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving workout exercise: \(error)")
        }
        
        return workoutExercise
    }
    
    public func addExerciseToWorkoutWithSets(
        workout: Workout,
        exerciseId: UUID,
        setData: [(reps: Int, weight: Double, duration: Int?, distance: Double?)],
        notes: String? = nil,
        modelContext: ModelContext
    ) -> WorkoutExercise {
        // Prevent duplicates: if the exercise is already in this workout, return the existing item
        if let existing = workout.exercises.first(where: { $0.exerciseId == exerciseId }) {
            return existing
        }
        let order = workout.exercises.count + 1
        
        let workoutExercise = WorkoutExercise(
            exerciseId: exerciseId,
            order: order,
            notes: notes
        )
        
        workoutExercise.workout = workout
        workout.exercises.append(workoutExercise)  // Add to workout's exercises array
        modelContext.insert(workoutExercise)
        
        // Create sets from the provided setData
        for (index, setInfo) in setData.enumerated() {
            let workoutSet = WorkoutSet(
                exerciseId: exerciseId,
                order: index + 1,
                reps: setInfo.reps,
                weight: setInfo.weight,
                duration: setInfo.duration,
                distance: setInfo.distance,
                notes: notes,
                date: workout.date
            )
            modelContext.insert(workoutSet)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving workout exercise with sets: \(error)")
        }
        
        return workoutExercise
    }
    
    public func addSetToExercise(
        workoutExercise: WorkoutExercise,
        reps: Int,
        weight: Double = 0,
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        modelContext: ModelContext
    ) -> WorkoutSet {
        // Note: This method is deprecated. Use ExerciseService.saveSets instead.
        // Keeping for backward compatibility but sets should be managed via ExerciseService
        let workoutSet = WorkoutSet(
            exerciseId: workoutExercise.exerciseId,
            order: 1,
            reps: reps,
            weight: weight,
            duration: duration,
            distance: distance,
            notes: notes,
            date: workoutExercise.workout?.date ?? Date()
        )
        
        modelContext.insert(workoutSet)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving workout set: \(error)")
        }
        
        return workoutSet
    }
    
    public func removeSetFromExercise(
        workoutSet: WorkoutSet,
        workoutExercise: WorkoutExercise,
        modelContext: ModelContext
    ) {
        // Note: This method is deprecated. Use ExerciseService.deleteSet instead.
        // Keeping for backward compatibility but sets should be managed via ExerciseService
        modelContext.delete(workoutSet)
        
        do {
            try modelContext.save()
        } catch {
            print("Error removing workout set: \(error)")
        }
    }
    
    public func removeExerciseFromWorkout(
        workoutExercise: WorkoutExercise,
        modelContext: ModelContext
    ) {
        // Remove from workout's exercises array first
        if let workout = workoutExercise.workout {
            workout.exercises.removeAll { $0.id == workoutExercise.id }
        }
        
        // Delete the workout exercise
        modelContext.delete(workoutExercise)
        
        // Reorder remaining exercises
        if let workout = workoutExercise.workout {
            let remainingExercises = workout.exercises
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
        
        saveContextAsync(modelContext, logMessage: "Error reordering exercises")
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
    
    public func getOrCreateWorkoutForDate(date: Date, modelContext: ModelContext) -> Workout {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.date >= startOfDay && workout.date < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            if let existingWorkout = workouts.first {
                return existingWorkout
            }
        } catch {
            print("Error fetching workout for date: \(error)")
        }
        
        // Create new workout if none exists
        let workoutName = "Workout - \(date.formatted(date: .abbreviated, time: .omitted))"
        return createWorkout(
            name: workoutName,
            date: date,
            modelContext: modelContext
        )
    }
    
    // MARK: - Duplicate Exercise Checking
    
    /// Checks if an exercise already exists in a workout
    public func exerciseExistsInWorkout(
        workout: Workout,
        exerciseId: UUID
    ) -> Bool {
        return workout.exercises.contains { $0.exerciseId == exerciseId }
    }
    
    /// Checks if an exercise already exists in a routine
    public func exerciseExistsInRoutine(
        routine: Routine,
        exerciseId: UUID
    ) -> Bool {
        return routine.exercises.contains { $0.exerciseId == exerciseId }
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
    
    private func saveContextAsync(_ modelContext: ModelContext, logMessage: String) {
        // Use asyncAfter to defer the save to the next run loop, allowing UI to update first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            do {
                try modelContext.save()
            } catch {
                print("\(logMessage): \(error)")
            }
        }
    }
    
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
        // Prevent duplicates: if the exercise is already in this routine, return the existing item
        if let existing = routine.exercises.first(where: { $0.exerciseId == exerciseId }) {
            return existing
        }
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
        // Maintain bidirectional relationship so UI updates immediately
        routine.exercises.append(routineExercise)
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
    
    public func reorderRoutineExercises(
        routine: Routine,
        from: IndexSet,
        to: Int,
        modelContext: ModelContext
    ) {
        routine.exercises.move(fromOffsets: from, toOffset: to)
        
        // Update order values
        for (index, exercise) in routine.exercises.enumerated() {
            exercise.order = index + 1
        }
        
        saveContextAsync(modelContext, logMessage: "Error reordering routine exercises")
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
        // Generate session-specific workout name
        let sessionName = "Workout - \(date.formatted(date: .abbreviated, time: .omitted))"
        
        let workout = Workout(
            name: sessionName,
            date: date,
            notes: notes,
            routineTemplateId: routine.id
        )
        modelContext.insert(workout)
        
        // Copy exercises from template and hydrate initial sets
        for templateExercise in routine.exercises.sorted(by: { $0.order < $1.order }) {
            let workoutExercise = WorkoutExercise(
                exerciseId: templateExercise.exerciseId,
                order: templateExercise.order,
                notes: templateExercise.notes
            )
            workoutExercise.workout = workout
            workout.exercises.append(workoutExercise)  // Explicitly maintain bidirectional relationship
            modelContext.insert(workoutExercise)

            // Hydrate sets for the workout exercise so they are visible immediately
            hydrateInitialSets(
                for: templateExercise,
                on: workout,
                modelContext: modelContext
            )
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error creating workout from template: \(error)")
        }
        
        return workout
    }
    
    // MARK: - Add Routine Exercises to Existing Workout
    
    public func addExercisesFromRoutineToWorkout(
        workout: Workout,
        routine: Routine,
        modelContext: ModelContext
    ) -> [WorkoutExercise] {
        var addedExercises: [WorkoutExercise] = []
        
        // Get the next order number for new exercises
        let currentExerciseCount = workout.exercises.count
        
        // Copy exercises from template, skipping duplicates
        var orderOffset = 0
        for templateExercise in routine.exercises.sorted(by: { $0.order < $1.order }) {
            // Skip if exercise already exists in workout
            if WorkoutService.shared.exerciseExistsInWorkout(workout: workout, exerciseId: templateExercise.exerciseId) {
                continue
            }
            
            let workoutExercise = WorkoutExercise(
                exerciseId: templateExercise.exerciseId,
                order: currentExerciseCount + orderOffset + 1,
                notes: templateExercise.notes
            )
            workoutExercise.workout = workout
            workout.exercises.append(workoutExercise)  // Explicitly maintain bidirectional relationship
            modelContext.insert(workoutExercise)
            addedExercises.append(workoutExercise)
            orderOffset += 1

            // Hydrate sets for the newly added exercise
            hydrateInitialSets(
                for: templateExercise,
                on: workout,
                modelContext: modelContext
            )
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error adding routine exercises to workout: \(error)")
        }
        
        return addedExercises
    }

    // MARK: - Helpers
    /// Creates initial sets for a workout based on the routine template defaults or last session fallback
    private func hydrateInitialSets(
        for templateExercise: RoutineExercise,
        on workout: Workout,
        modelContext: ModelContext
    ) {
        let exerciseId = templateExercise.exerciseId
        let date = workout.date

        // Determine number of sets
        var setCount = max(0, templateExercise.sets)

        // Try to load last session for fallback values
        let lastSession = ExerciseService.shared.getLastSessionForExercise(
            exerciseId: exerciseId,
            modelContext: modelContext
        )

        // Determine base reps/weight/duration/distance
        var baseReps: Int?
        var baseWeight: Double?

        if let reps = templateExercise.reps { baseReps = reps }
        if let weight = templateExercise.weight { baseWeight = weight }

        if baseReps == nil || baseWeight == nil || setCount == 0 {
            if let last = lastSession, let first = last.first {
                // Fallback to last session
                baseReps = baseReps ?? first.reps
                baseWeight = baseWeight ?? first.weight
                if setCount == 0 { setCount = last.count }
            }
        }

        // Final defaults if still missing
        if setCount == 0 { setCount = 3 }
        if baseReps == nil { baseReps = 10 }
        if baseWeight == nil { baseWeight = 0 }

        // Build sets array (all not completed initially)
        let setsData: [(weight: Double, reps: Int, isCompleted: Bool)] = (0..<setCount).map { _ in
            (weight: baseWeight ?? 0, reps: baseReps ?? 0, isCompleted: false)
        }

        _ = ExerciseService.shared.saveSets(
            exerciseId: exerciseId,
            date: date,
            sets: setsData,
            modelContext: modelContext
        )
    }
}