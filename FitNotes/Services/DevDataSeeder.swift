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
        
        // App Store screenshots: launch with `-screenshotData` for ~13 weeks of realistic history
        if ProcessInfo.processInfo.arguments.contains("-screenshotData") {
            seedScreenshotHistory(modelContext: modelContext)
            return
        }

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

            // Past days are done: check their sets off and finish the workout, so stats,
            // PRs and "last time" numbers have something to show. Today stays to be done.
            if date < today {
                for exerciseId in [bench.id, squat.id] {
                    for set in ExerciseService.shared.getSetsByDate(exerciseId: exerciseId, date: date, modelContext: modelContext) {
                        set.isCompleted = true
                        set.completedAt = date
                    }
                }
                workout.finishedAt = date
            }
        }
        try? modelContext.save()
        #endif
    }
    
    #if DEBUG
    /// Three sessions a week (Mon/Wed/Fri) for 13 weeks with steady progressive overload, all
    /// finished. Today is a Push session with the first bench sets checked off. Weights are in
    /// lbs, the default unit for the seeded exercises.
    private static func seedScreenshotHistory(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        typealias Plan = [(name: String, start: Double, step: Double, reps: [Int])]
        let push: Plan = [
            ("Barbell Bench Press", 155, 2.5, [8, 8, 6, 6]),
            ("Overhead Press", 85, 1.25, [8, 8, 6]),
            ("Incline Dumbbell Press", 50, 0.5, [10, 10, 8]),
            ("Lateral Raise", 15, 0.25, [15, 12, 12]),
            ("Tricep Pushdown", 50, 1, [12, 12, 10])
        ]
        let legs: Plan = [
            ("Barbell Squat", 205, 5, [5, 5, 5, 5]),
            ("Romanian Deadlift", 155, 2.5, [8, 8, 8]),
            ("Barbell Deadlift", 255, 5, [5, 5, 3])
        ]
        let pull: Plan = [
            ("Barbell Row", 135, 2.5, [8, 8, 8]),
            ("Lat Pulldown", 120, 2, [10, 10, 8]),
            ("Face Pulls", 40, 1, [15, 15]),
            ("Barbell Curl", 65, 1, [10, 10, 8])
        ]

        func roundToPlate(_ lbs: Double) -> Double { (lbs / 5).rounded() * 5 }
        var exerciseCache: [String: Exercise] = [:]
        func lookup(_ name: String) -> Exercise? {
            if let cached = exerciseCache[name] { return cached }
            let found = exercise(named: name, modelContext: modelContext)
            exerciseCache[name] = found
            return found
        }
        func add(_ plan: Plan, session: Double, to workout: Workout, date: Date, completed: Bool) {
            for item in plan {
                guard let exercise = lookup(item.name) else { continue }
                let weight = roundToPlate(item.start + item.step * session)
                _ = WorkoutService.shared.addExerciseToWorkoutWithSets(
                    workout: workout,
                    exerciseId: exercise.id,
                    setData: item.reps.map { (reps: $0, weight: weight, duration: nil, distance: nil) },
                    modelContext: modelContext
                )
                guard completed else { continue }
                for set in ExerciseService.shared.getSetsByDate(exerciseId: exercise.id, date: date, modelContext: modelContext) {
                    set.isCompleted = true
                    set.completedAt = date
                }
            }
        }

        var dates: [Date] = []
        for daysAgo in stride(from: 91, through: 1, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            if [2, 4, 6].contains(calendar.component(.weekday, from: date)) { dates.append(date) }
        }

        for (index, date) in dates.enumerated() {
            let workout = WorkoutService.shared.getOrCreateWorkoutForDate(date: date, modelContext: modelContext)
            add([push, legs, pull][index % 3], session: Double(index / 3), to: workout, date: date, completed: true)
            workout.finishedAt = date.addingTimeInterval(60 * 60 * 18)
        }

        // Today: Push, one step heavier than last time, first two bench sets done
        let workout = WorkoutService.shared.getOrCreateWorkoutForDate(date: today, modelContext: modelContext)
        add(push, session: Double(dates.count / 3 + 1), to: workout, date: today, completed: false)
        if let bench = lookup("Barbell Bench Press") {
            let sets = ExerciseService.shared.getSetsByDate(exerciseId: bench.id, date: today, modelContext: modelContext)
                .sorted { $0.order < $1.order }
            for set in sets.prefix(2) {
                set.isCompleted = true
                set.completedAt = Date()
            }
        }
        try? modelContext.save()
    }
    #endif

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


