import Foundation
import SwiftData

public final class ExerciseDatabaseService {
    public static let shared = ExerciseDatabaseService()
    private init() {}
    
    // Comprehensive list of muscle groups
    public static let muscleGroups = [
        "Chest", "Back", "Shoulders", "Biceps", "Triceps",
        "Quads", "Hamstrings", "Glutes", "Calves", "Abs", "Forearms"
    ]
    
    
    // Equipment types
    public static let equipmentTypes = [
        "Machine", "Free Weight", "Body", "Pulley"
    ]
    
    /// Normalizes equipment type strings to match the standard format used in the UI
    /// Converts: "free-weight" -> "Free Weight", "bodyweight" -> "Body", "machine" -> "Machine", "pulley"/"cable" -> "Pulley"
    public static func normalizeEquipmentType(_ equipment: String) -> String {
        let lowercased = equipment.lowercased()
        switch lowercased {
        case "free-weight", "free weight":
            return "Free Weight"
        case "bodyweight", "body":
            return "Body"
        case "machine":
            return "Machine"
        case "pulley", "cable":
            return "Pulley"
        default:
            // Return as-is if already in correct format or unknown
            return equipment
        }
    }
    
    public func createDefaultExercises(modelContext: ModelContext) {
        let defaultExercises = getDefaultExercises()

        // Get global defaults from preferences
        let defaultUnit = PreferencesService.shared.getDefaultWeightUnit(modelContext: modelContext)
        let defaultRestSeconds = PreferencesService.shared.getDefaultRestSeconds(modelContext: modelContext)
        let defaultStatsDisplay = PreferencesService.shared.getDefaultStatsDisplayPreference(modelContext: modelContext)
        // Enable rest timer by default if user set a non-zero rest time during onboarding
        let enableRestTimer = PreferencesService.shared.shouldEnableRestTimerByDefault(modelContext: modelContext)

        for exerciseData in defaultExercises {
            let exercise = Exercise(
                name: exerciseData.name,
                primaryCategory: exerciseData.primaryCategory,
                secondaryCategories: exerciseData.secondaryCategories,
                equipment: ExerciseDatabaseService.normalizeEquipmentType(exerciseData.equipment),
                notes: nil,
                unit: defaultUnit,
                isCustom: false,
                rpeEnabled: false,
                rirEnabled: false,
                useRestTimer: enableRestTimer,
                defaultRestSeconds: defaultRestSeconds,
                useAdvancedRest: false,
                customRestSeconds: [:],
                targetRepMin: nil,
                targetRepMax: nil,
                lastProgressionDate: nil,
                incrementValue: 5.0,
                statsDisplayPreference: defaultStatsDisplay,
                statsIsExpanded: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            modelContext.insert(exercise)
        }

        try? modelContext.save()
    }

    // MARK: - Exercise Library Sync (Differential Migration)

    /// Syncs the default exercise library with the database.
    /// Adds any missing default exercises without touching user-created exercises.
    /// Also updates equipment types for existing cable exercises to "Pulley".
    /// Safe to call on every app launch.
    public func syncDefaultExercises(modelContext: ModelContext) {
        let defaultExercises = getDefaultExercises()

        // Fetch all existing exercises
        let descriptor = FetchDescriptor<Exercise>()
        guard let existingExercises = try? modelContext.fetch(descriptor) else {
            // If fetch fails, fall back to creating all defaults
            createDefaultExercises(modelContext: modelContext)
            return
        }

        // Create a set of existing exercise names for O(1) lookup
        let existingNames = Set(existingExercises.map { $0.name })

        // Find missing default exercises
        let missingExercises = defaultExercises.filter { !existingNames.contains($0.name) }

        guard !missingExercises.isEmpty else {
            // Also update equipment types for existing cable exercises
            updateCableExercisesToPulley(existingExercises: existingExercises, modelContext: modelContext)
            return
        }

        // Get global defaults from preferences
        let defaultUnit = PreferencesService.shared.getDefaultWeightUnit(modelContext: modelContext)
        let defaultRestSeconds = PreferencesService.shared.getDefaultRestSeconds(modelContext: modelContext)
        let defaultStatsDisplay = PreferencesService.shared.getDefaultStatsDisplayPreference(modelContext: modelContext)
        let enableRestTimer = PreferencesService.shared.shouldEnableRestTimerByDefault(modelContext: modelContext)

        // Add missing exercises
        for exerciseData in missingExercises {
            let exercise = Exercise(
                name: exerciseData.name,
                primaryCategory: exerciseData.primaryCategory,
                secondaryCategories: exerciseData.secondaryCategories,
                equipment: ExerciseDatabaseService.normalizeEquipmentType(exerciseData.equipment),
                notes: nil,
                unit: defaultUnit,
                isCustom: false,
                rpeEnabled: false,
                rirEnabled: false,
                useRestTimer: enableRestTimer,
                defaultRestSeconds: defaultRestSeconds,
                useAdvancedRest: false,
                customRestSeconds: [:],
                targetRepMin: nil,
                targetRepMax: nil,
                lastProgressionDate: nil,
                incrementValue: 5.0,
                statsDisplayPreference: defaultStatsDisplay,
                statsIsExpanded: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            modelContext.insert(exercise)
        }

        // Also update equipment types for existing cable exercises
        updateCableExercisesToPulley(existingExercises: existingExercises, modelContext: modelContext)

        try? modelContext.save()

        #if DEBUG
        print("ExerciseDatabaseService: Synced \(missingExercises.count) new exercises to library")
        #endif
    }

    /// Updates existing cable/machine exercises that should be categorized as "Pulley"
    private func updateCableExercisesToPulley(existingExercises: [Exercise], modelContext: ModelContext) {
        // List of exercise names that should use "Pulley" equipment
        let pulleyExerciseNames: Set<String> = [
            "Cable Crossover", "Low Cable Fly", "High Cable Fly",
            "Lat Pulldown", "Cable Row", "Face Pulls", "Straight Arm Pulldown", "Single Arm Cable Row",
            "Cable Lateral Raise", "Cable Front Raise", "Cable Rear Delt Fly",
            "Cable Curl", "Cable Hammer Curl", "Bayesian Curl",
            "Tricep Pushdown", "Rope Pushdown", "Overhead Cable Extension", "Single Arm Pushdown", "Cable Kickback",
            "Cable Pull-Through", "Cable Glute Kickback",
            "Cable Crunch", "Cable Woodchop", "Pallof Press"
        ]

        var updatedCount = 0
        for exercise in existingExercises {
            if pulleyExerciseNames.contains(exercise.name) && exercise.equipment != "Pulley" {
                exercise.equipment = "Pulley"
                exercise.updatedAt = Date()
                updatedCount += 1
            }
        }

        if updatedCount > 0 {
            try? modelContext.save()
            #if DEBUG
            print("ExerciseDatabaseService: Updated \(updatedCount) exercises to Pulley equipment type")
            #endif
        }
    }
    
    private func getDefaultExercises() -> [ExerciseData] {
        return [
            // MARK: - Chest Exercises (15)
            ExerciseData(name: "Barbell Bench Press", primaryCategory: "Chest", secondaryCategories: ["Triceps", "Shoulders"], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Bench Press", primaryCategory: "Chest", secondaryCategories: ["Triceps", "Shoulders"], equipment: "free-weight"),
            ExerciseData(name: "Incline Barbell Bench Press", primaryCategory: "Chest", secondaryCategories: ["Shoulders", "Triceps"], equipment: "free-weight"),
            ExerciseData(name: "Incline Dumbbell Press", primaryCategory: "Chest", secondaryCategories: ["Shoulders", "Triceps"], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Flyes", primaryCategory: "Chest", secondaryCategories: ["Shoulders"], equipment: "free-weight"),
            ExerciseData(name: "Machine Chest Press", primaryCategory: "Chest", secondaryCategories: ["Triceps", "Shoulders"], equipment: "machine"),
            ExerciseData(name: "Push-ups", primaryCategory: "Chest", secondaryCategories: ["Triceps", "Shoulders"], equipment: "bodyweight"),
            ExerciseData(name: "Decline Bench Press", primaryCategory: "Chest", secondaryCategories: ["Triceps"], equipment: "free-weight"),
            ExerciseData(name: "Machine Fly", primaryCategory: "Chest", secondaryCategories: ["Shoulders"], equipment: "machine"),
            ExerciseData(name: "Weighted Dips", primaryCategory: "Chest", secondaryCategories: ["Triceps", "Shoulders"], equipment: "bodyweight"),
            ExerciseData(name: "Smith Machine Bench Press", primaryCategory: "Chest", secondaryCategories: ["Triceps", "Shoulders"], equipment: "machine"),
            ExerciseData(name: "Cable Crossover", primaryCategory: "Chest", secondaryCategories: ["Shoulders"], equipment: "pulley"),
            ExerciseData(name: "Low Cable Fly", primaryCategory: "Chest", secondaryCategories: ["Shoulders"], equipment: "pulley"),
            ExerciseData(name: "High Cable Fly", primaryCategory: "Chest", secondaryCategories: ["Shoulders"], equipment: "pulley"),
            ExerciseData(name: "Dumbbell Pullover", primaryCategory: "Chest", secondaryCategories: ["Back"], equipment: "free-weight"),

            // MARK: - Back Exercises (20)
            ExerciseData(name: "Barbell Deadlift", primaryCategory: "Back", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Barbell Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Lat Pulldown", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "pulley"),
            ExerciseData(name: "Pull-ups", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "bodyweight"),
            ExerciseData(name: "Chin-ups", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "bodyweight"),
            ExerciseData(name: "Cable Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "pulley"),
            ExerciseData(name: "Dumbbell Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Face Pulls", primaryCategory: "Back", secondaryCategories: ["Shoulders"], equipment: "pulley"),
            ExerciseData(name: "T-Bar Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Machine Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),
            ExerciseData(name: "Romanian Deadlift", primaryCategory: "Back", secondaryCategories: ["Hamstrings", "Glutes"], equipment: "free-weight"),
            ExerciseData(name: "Bent-Over Dumbbell Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Pendlay Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Assisted Pull-ups", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),
            ExerciseData(name: "Smith Machine Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),
            ExerciseData(name: "Straight Arm Pulldown", primaryCategory: "Back", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Single Arm Cable Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "pulley"),
            ExerciseData(name: "Rack Pull", primaryCategory: "Back", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Meadows Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Chest Supported Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),

            // MARK: - Shoulder Exercises (18)
            ExerciseData(name: "Overhead Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps", "Chest"], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Shoulder Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps", "Chest"], equipment: "free-weight"),
            ExerciseData(name: "Machine Shoulder Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps"], equipment: "machine"),
            ExerciseData(name: "Lateral Raise", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Cable Lateral Raise", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Rear Delt Flyes", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Machine Rear Delt Fly", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Upright Row", primaryCategory: "Shoulders", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Upright Row", primaryCategory: "Shoulders", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Arnold Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps", "Chest"], equipment: "free-weight"),
            ExerciseData(name: "Pike Push-ups", primaryCategory: "Shoulders", secondaryCategories: ["Triceps", "Chest"], equipment: "bodyweight"),
            ExerciseData(name: "Barbell Shrug", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Shrug", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Smith Machine Shoulder Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps"], equipment: "machine"),
            ExerciseData(name: "Cable Front Raise", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Cable Rear Delt Fly", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Reverse Pec Deck", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Front Raise", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),

            // MARK: - Biceps Exercises (14)
            ExerciseData(name: "Barbell Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Machine Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Cable Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Hammer Curl", primaryCategory: "Biceps", secondaryCategories: ["Forearms"], equipment: "free-weight"),
            ExerciseData(name: "Incline Dumbbell Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "EZ-Bar Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Preacher Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Concentration Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Spider Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Cable Hammer Curl", primaryCategory: "Biceps", secondaryCategories: ["Forearms"], equipment: "pulley"),
            ExerciseData(name: "Bayesian Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Reverse Curl", primaryCategory: "Biceps", secondaryCategories: ["Forearms"], equipment: "free-weight"),
            ExerciseData(name: "Zottman Curl", primaryCategory: "Biceps", secondaryCategories: ["Forearms"], equipment: "free-weight"),

            // MARK: - Triceps Exercises (14)
            ExerciseData(name: "Tricep Dips", primaryCategory: "Triceps", secondaryCategories: ["Chest", "Shoulders"], equipment: "bodyweight"),
            ExerciseData(name: "Tricep Pushdown", primaryCategory: "Triceps", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Overhead Tricep Extension", primaryCategory: "Triceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Machine Tricep Extension", primaryCategory: "Triceps", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Skullcrusher", primaryCategory: "Triceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Skullcrusher", primaryCategory: "Triceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Rope Pushdown", primaryCategory: "Triceps", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Close-Grip Bench Press", primaryCategory: "Triceps", secondaryCategories: ["Chest", "Shoulders"], equipment: "free-weight"),
            ExerciseData(name: "Machine Dips", primaryCategory: "Triceps", secondaryCategories: ["Chest", "Shoulders"], equipment: "machine"),
            ExerciseData(name: "Diamond Push-ups", primaryCategory: "Triceps", secondaryCategories: ["Chest"], equipment: "bodyweight"),
            ExerciseData(name: "Overhead Cable Extension", primaryCategory: "Triceps", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Single Arm Pushdown", primaryCategory: "Triceps", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Cable Kickback", primaryCategory: "Triceps", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "JM Press", primaryCategory: "Triceps", secondaryCategories: [], equipment: "free-weight"),

            // MARK: - Quads Exercises (15)
            ExerciseData(name: "Barbell Squat", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Leg Press", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "machine"),
            ExerciseData(name: "Leg Extension", primaryCategory: "Quads", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Goblet Squat", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Smith Machine Squat", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "machine"),
            ExerciseData(name: "Front Squat", primaryCategory: "Quads", secondaryCategories: ["Glutes"], equipment: "free-weight"),
            ExerciseData(name: "Bulgarian Split Squat", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Lunge", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Barbell Lunge", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Hack Squat", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "machine"),
            ExerciseData(name: "Walking Lunge", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Step-ups", primaryCategory: "Quads", secondaryCategories: ["Glutes"], equipment: "free-weight"),
            ExerciseData(name: "Sissy Squat", primaryCategory: "Quads", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Pendulum Squat", primaryCategory: "Quads", secondaryCategories: ["Glutes"], equipment: "machine"),
            ExerciseData(name: "Belt Squat", primaryCategory: "Quads", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "machine"),

            // MARK: - Glutes Exercises (10)
            ExerciseData(name: "Barbell Hip Thrust", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Glute Bridge", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings"], equipment: "bodyweight"),
            ExerciseData(name: "Cable Pull-Through", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings", "Back"], equipment: "pulley"),
            ExerciseData(name: "Weighted Glute Bridge", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Hip Abduction Machine", primaryCategory: "Glutes", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Cable Glute Kickback", primaryCategory: "Glutes", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Sumo Deadlift", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings", "Back", "Quads"], equipment: "free-weight"),
            ExerciseData(name: "Machine Glute Kickback", primaryCategory: "Glutes", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Frog Pump", primaryCategory: "Glutes", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Hip Adduction Machine", primaryCategory: "Glutes", secondaryCategories: [], equipment: "machine"),

            // MARK: - Hamstrings Exercises (11)
            ExerciseData(name: "Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "free-weight"),
            ExerciseData(name: "Romanian Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "free-weight"),
            ExerciseData(name: "Leg Curl", primaryCategory: "Hamstrings", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Lying Leg Curl", primaryCategory: "Hamstrings", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Dumbbell Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "free-weight"),
            ExerciseData(name: "Smith Machine Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "machine"),
            ExerciseData(name: "Nordic Curl", primaryCategory: "Hamstrings", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Good Morning", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "free-weight"),
            ExerciseData(name: "Stiff-Leg Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "free-weight"),
            ExerciseData(name: "Single Leg Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes"], equipment: "free-weight"),
            ExerciseData(name: "Glute Ham Raise", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes"], equipment: "machine"),

            // MARK: - Calves Exercises (6)
            ExerciseData(name: "Standing Calf Raise", primaryCategory: "Calves", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Seated Calf Raise", primaryCategory: "Calves", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Donkey Calf Raise", primaryCategory: "Calves", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Single Leg Calf Raise", primaryCategory: "Calves", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Smith Machine Calf Raise", primaryCategory: "Calves", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Leg Press Calf Raise", primaryCategory: "Calves", secondaryCategories: [], equipment: "machine"),

            // MARK: - Abs/Core Exercises (15)
            ExerciseData(name: "Plank", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Ab Wheel Rollout", primaryCategory: "Abs", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Cable Crunch", primaryCategory: "Abs", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Machine Crunch", primaryCategory: "Abs", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Weighted Crunch", primaryCategory: "Abs", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Cable Woodchop", primaryCategory: "Abs", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Hanging Leg Raise", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Decline Sit-up", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Pallof Press", primaryCategory: "Abs", secondaryCategories: [], equipment: "pulley"),
            ExerciseData(name: "Russian Twist", primaryCategory: "Abs", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Dead Bug", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Mountain Climbers", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Bicycle Crunch", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Side Plank", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Toes to Bar", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),

            // MARK: - Forearms Exercises (6)
            ExerciseData(name: "Wrist Curl", primaryCategory: "Forearms", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Reverse Wrist Curl", primaryCategory: "Forearms", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Farmer's Walk", primaryCategory: "Forearms", secondaryCategories: ["Shoulders"], equipment: "free-weight"),
            ExerciseData(name: "Dead Hang", primaryCategory: "Forearms", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Plate Pinch", primaryCategory: "Forearms", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Behind the Back Wrist Curl", primaryCategory: "Forearms", secondaryCategories: [], equipment: "free-weight")
        ]
    }
}

private struct ExerciseData {
    let name: String
    let primaryCategory: String
    let secondaryCategories: [String]
    let equipment: String
}
