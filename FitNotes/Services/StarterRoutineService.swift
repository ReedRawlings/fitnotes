//
//  StarterRoutineService.swift
//  FitNotes
//
//  Service for creating starter routines during onboarding
//

import Foundation
import SwiftData

/// Service for creating starter routines during onboarding
final class StarterRoutineService {
    static let shared = StarterRoutineService()
    private init() {}

    // MARK: - Routine Definitions

    /// Full Body Starter routine exercises
    private let fullBodyExercises = [
        "Barbell Squat",
        "Barbell Bench Press",
        "Barbell Row",
        "Overhead Press",
        "Barbell Deadlift",
        "Dumbbell Curl",
        "Tricep Pushdown"
    ]

    /// Push day exercises
    private let pushExercises = [
        "Barbell Bench Press",
        "Incline Dumbbell Press",
        "Overhead Press",
        "Lateral Raise",
        "Tricep Pushdown",
        "Overhead Tricep Extension"
    ]

    /// Pull day exercises
    private let pullExercises = [
        "Barbell Deadlift",
        "Barbell Row",
        "Lat Pulldown",
        "Face Pulls",
        "Barbell Curl",
        "Hammer Curl"
    ]

    /// Legs day exercises
    private let legsExercises = [
        "Barbell Squat",
        "Leg Press",
        "Leg Extension",
        "Leg Curl",
        "Barbell Hip Thrust"
    ]

    /// Upper body exercises
    private let upperExercises = [
        "Barbell Bench Press",
        "Barbell Row",
        "Overhead Press",
        "Lat Pulldown",
        "Dumbbell Curl",
        "Tricep Pushdown"
    ]

    /// Lower body exercises
    private let lowerExercises = [
        "Barbell Squat",
        "Leg Press",
        "Leg Curl",
        "Leg Extension",
        "Barbell Hip Thrust"
    ]

    // MARK: - Public API

    /// Creates the selected starter routine(s) with exercises and user-selected schedule
    func createStarterRoutine(
        _ routineType: StarterRoutine,
        workoutDays: Set<Int>,
        modelContext: ModelContext
    ) {
        // Sort days for consistent ordering (0=Sun through 6=Sat)
        let sortedDays = workoutDays.sorted()

        switch routineType {
        case .fullBody:
            createFullBodyRoutine(days: sortedDays, modelContext: modelContext)
        case .pushPullLegs:
            createPPLRoutines(days: sortedDays, modelContext: modelContext)
        case .upperLower:
            createUpperLowerRoutines(days: sortedDays, modelContext: modelContext)
        }
    }

    // MARK: - Private Routine Creators

    private func createFullBodyRoutine(days: [Int], modelContext: ModelContext) {
        let routine = RoutineService.shared.createRoutine(
            name: "Full Body Starter",
            description: "A beginner-friendly full body routine",
            modelContext: modelContext
        )

        routine.color = .teal
        addExercisesToRoutine(routine, exerciseNames: fullBodyExercises, modelContext: modelContext)

        // Use all selected days (user picked at least 3)
        RoutineService.shared.updateRoutineSchedule(
            routine: routine,
            scheduleType: .weekly,
            scheduleDays: Set(days),
            modelContext: modelContext
        )
    }

    private func createPPLRoutines(days: [Int], modelContext: ModelContext) {
        // Distribute days across Push, Pull, Legs
        // If 3 days: one rotation (Push, Pull, Legs)
        // If 4-5 days: distribute as evenly as possible
        // If 6 days: two rotations (Push, Pull, Legs, Push, Pull, Legs)

        var pushDays: Set<Int> = []
        var pullDays: Set<Int> = []
        var legsDays: Set<Int> = []

        for (index, day) in days.enumerated() {
            switch index % 3 {
            case 0: pushDays.insert(day)
            case 1: pullDays.insert(day)
            case 2: legsDays.insert(day)
            default: break
            }
        }

        // Push routine
        let push = RoutineService.shared.createRoutine(
            name: "Push Day",
            description: "Chest, shoulders, and triceps",
            modelContext: modelContext
        )
        push.color = .coral
        addExercisesToRoutine(push, exerciseNames: pushExercises, modelContext: modelContext)
        RoutineService.shared.updateRoutineSchedule(
            routine: push,
            scheduleType: .weekly,
            scheduleDays: pushDays,
            modelContext: modelContext
        )

        // Pull routine
        let pull = RoutineService.shared.createRoutine(
            name: "Pull Day",
            description: "Back and biceps",
            modelContext: modelContext
        )
        pull.color = .blue
        addExercisesToRoutine(pull, exerciseNames: pullExercises, modelContext: modelContext)
        RoutineService.shared.updateRoutineSchedule(
            routine: pull,
            scheduleType: .weekly,
            scheduleDays: pullDays,
            modelContext: modelContext
        )

        // Legs routine
        let legs = RoutineService.shared.createRoutine(
            name: "Legs Day",
            description: "Quads, hamstrings, and glutes",
            modelContext: modelContext
        )
        legs.color = .purple
        addExercisesToRoutine(legs, exerciseNames: legsExercises, modelContext: modelContext)
        RoutineService.shared.updateRoutineSchedule(
            routine: legs,
            scheduleType: .weekly,
            scheduleDays: legsDays,
            modelContext: modelContext
        )
    }

    private func createUpperLowerRoutines(days: [Int], modelContext: ModelContext) {
        // Alternate Upper/Lower across selected days
        var upperDays: Set<Int> = []
        var lowerDays: Set<Int> = []

        for (index, day) in days.enumerated() {
            if index % 2 == 0 {
                upperDays.insert(day)
            } else {
                lowerDays.insert(day)
            }
        }

        // Upper routine
        let upper = RoutineService.shared.createRoutine(
            name: "Upper Body",
            description: "Chest, back, shoulders, and arms",
            modelContext: modelContext
        )
        upper.color = .amber
        addExercisesToRoutine(upper, exerciseNames: upperExercises, modelContext: modelContext)
        RoutineService.shared.updateRoutineSchedule(
            routine: upper,
            scheduleType: .weekly,
            scheduleDays: upperDays,
            modelContext: modelContext
        )

        // Lower routine
        let lower = RoutineService.shared.createRoutine(
            name: "Lower Body",
            description: "Quads, hamstrings, glutes, and calves",
            modelContext: modelContext
        )
        lower.color = .teal
        addExercisesToRoutine(lower, exerciseNames: lowerExercises, modelContext: modelContext)
        RoutineService.shared.updateRoutineSchedule(
            routine: lower,
            scheduleType: .weekly,
            scheduleDays: lowerDays,
            modelContext: modelContext
        )
    }

    // MARK: - Helpers

    private func addExercisesToRoutine(
        _ routine: Routine,
        exerciseNames: [String],
        modelContext: ModelContext
    ) {
        for name in exerciseNames {
            if let exercise = findExercise(named: name, modelContext: modelContext) {
                _ = RoutineService.shared.addExerciseToRoutine(
                    routine: routine,
                    exerciseId: exercise.id,
                    modelContext: modelContext
                )
            }
        }
    }

    private func findExercise(named name: String, modelContext: ModelContext) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { $0.name == name }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
