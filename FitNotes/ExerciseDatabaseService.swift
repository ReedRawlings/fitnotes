import Foundation
import SwiftData

public final class ExerciseDatabaseService {
    public static let shared = ExerciseDatabaseService()
    private init() {}
    
    // Comprehensive list of muscle groups
    public static let muscleGroups = [
        "Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Glutes",
        "Calves", "Forearms", "Neck", "Full Body", "Cardio"
    ]
    
    
    // Equipment types
    public static let equipmentTypes = [
        "Machine", "Free Weight", "Body"
    ]
    
    public func createDefaultExercises(modelContext: ModelContext) {
        let defaultExercises = getDefaultExercises()
        
        for exerciseData in defaultExercises {
            let exercise = Exercise(
                name: exerciseData.name,
                primaryCategory: exerciseData.primaryCategory,
                secondaryCategories: exerciseData.secondaryCategories,
                equipment: exerciseData.equipment,
                isCustom: false
            )
            modelContext.insert(exercise)
        }
        
        try? modelContext.save()
    }
    
    private func getDefaultExercises() -> [ExerciseData] {
        return [
            // Chest Exercises
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
            // Back Exercises
            ExerciseData(name: "Barbell Deadlift", primaryCategory: "Back", secondaryCategories: ["Glutes", "Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Barbell Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Lat Pulldown", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),
            ExerciseData(name: "Pull-ups", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "bodyweight"),
            ExerciseData(name: "Chin-ups", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "bodyweight"),
            ExerciseData(name: "Cable Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),
            ExerciseData(name: "Dumbbell Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Face Pulls", primaryCategory: "Back", secondaryCategories: ["Shoulders"], equipment: "machine"),
            ExerciseData(name: "T-Bar Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Machine Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),
            ExerciseData(name: "Romanian Deadlift", primaryCategory: "Back", secondaryCategories: ["Hamstrings", "Glutes"], equipment: "free-weight"),
            ExerciseData(name: "Bent-Over Dumbbell Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Pendlay Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Assisted Pull-ups", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),
            ExerciseData(name: "Smith Machine Row", primaryCategory: "Back", secondaryCategories: ["Biceps"], equipment: "machine"),
            // Shoulder Exercises
            ExerciseData(name: "Overhead Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps", "Chest"], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Shoulder Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps", "Chest"], equipment: "free-weight"),
            ExerciseData(name: "Machine Shoulder Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps"], equipment: "machine"),
            ExerciseData(name: "Lateral Raise", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Cable Lateral Raise", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Rear Delt Flyes", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Machine Rear Delt Fly", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Upright Row", primaryCategory: "Shoulders", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Upright Row", primaryCategory: "Shoulders", secondaryCategories: ["Biceps"], equipment: "free-weight"),
            ExerciseData(name: "Arnold Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps", "Chest"], equipment: "free-weight"),
            ExerciseData(name: "Pike Push-ups", primaryCategory: "Shoulders", secondaryCategories: ["Triceps", "Chest"], equipment: "bodyweight"),
            ExerciseData(name: "Barbell Shrug", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Shrug", primaryCategory: "Shoulders", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Smith Machine Shoulder Press", primaryCategory: "Shoulders", secondaryCategories: ["Triceps"], equipment: "machine"),
            // Biceps Exercises
            ExerciseData(name: "Barbell Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Machine Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Cable Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Hammer Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Incline Dumbbell Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "EZ-Bar Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Preacher Curl", primaryCategory: "Biceps", secondaryCategories: [], equipment: "free-weight"),
            // Tricep Exercises
            ExerciseData(name: "Tricep Dips", primaryCategory: "Triceps", secondaryCategories: ["Chest", "Shoulders"], equipment: "bodyweight"),
            ExerciseData(name: "Tricep Pushdown", primaryCategory: "Triceps", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Overhead Tricep Extension", primaryCategory: "Triceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Machine Tricep Extension", primaryCategory: "Triceps", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Skullcrusher", primaryCategory: "Triceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Dumbbell Skullcrusher", primaryCategory: "Triceps", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Rope Pushdown", primaryCategory: "Triceps", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Close-Grip Bench Press", primaryCategory: "Triceps", secondaryCategories: ["Chest", "Shoulders"], equipment: "free-weight"),
            ExerciseData(name: "Machine Dips", primaryCategory: "Triceps", secondaryCategories: ["Chest", "Shoulders"], equipment: "machine"),
            // Quads Exercises
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
            // Glute Exercises
            ExerciseData(name: "Barbell Hip Thrust", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Glute Bridge", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings"], equipment: "bodyweight"),
            ExerciseData(name: "Cable Pull-Through", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings", "Back"], equipment: "machine"),
            ExerciseData(name: "Weighted Glute Bridge", primaryCategory: "Glutes", secondaryCategories: ["Hamstrings"], equipment: "free-weight"),
            ExerciseData(name: "Hip Abduction Machine", primaryCategory: "Glutes", secondaryCategories: [], equipment: "machine"),
            // Hamstring Exercises
            ExerciseData(name: "Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "free-weight"),
            ExerciseData(name: "Romanian Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "free-weight"),
            ExerciseData(name: "Leg Curl", primaryCategory: "Hamstrings", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Lying Leg Curl", primaryCategory: "Hamstrings", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Dumbbell Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "free-weight"),
            ExerciseData(name: "Smith Machine Deadlift", primaryCategory: "Hamstrings", secondaryCategories: ["Glutes", "Back"], equipment: "machine"),
            
            // Core Exercises
            ExerciseData(name: "Plank", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Ab Wheel Rollout", primaryCategory: "Abs", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Cable Crunch", primaryCategory: "Abs", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Machine Crunch", primaryCategory: "Abs", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Weighted Crunch", primaryCategory: "Abs", secondaryCategories: [], equipment: "free-weight"),
            ExerciseData(name: "Cable Woodchop", primaryCategory: "Abs", secondaryCategories: [], equipment: "machine"),
            ExerciseData(name: "Hanging Leg Raise", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Decline Sit-up", primaryCategory: "Abs", secondaryCategories: [], equipment: "bodyweight"),
            ExerciseData(name: "Pallof Press", primaryCategory: "Abs", secondaryCategories: [], equipment: "machine")
            ]
    }
}

private struct ExerciseData {
    let name: String
    let primaryCategory: String
    let secondaryCategories: [String]
    let equipment: String
}
