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
            ExerciseData(name: "Barbell Bench Press", primaryCategory: "Chest", secondaryCategory: ["Triceps", "Shoulders"], equipment: "free-weight")
            ExerciseData(name: "Dumbbell Bench Press", primaryCategory: "Chest", secondaryCategory: ["Triceps", "Shoulders"], equipment: "free-weight")
            ExerciseData(name: "Incline Barbell Bench Press", primaryCategory: "Chest", secondaryCategory: ["Shoulders", "Triceps"], equipment: "free-weight")
            ExerciseData(name: "Incline Dumbbell Press", primaryCategory: "Chest", secondaryCategory: ["Shoulders", "Triceps"], equipment: "free-weight")
            ExerciseData(name: "Dumbbell Flyes", primaryCategory: "Chest", secondaryCategory: ["Shoulders"], equipment: "free-weight")
            ExerciseData(name: "Machine Chest Press", primaryCategory: "Chest", secondaryCategory: ["Triceps", "Shoulders"], equipment: "machine")
            ExerciseData(name: "Push-ups", primaryCategory: "Chest", secondaryCategory: ["Triceps", "Shoulders"], equipment: "bodyweight")
            ExerciseData(name: "Decline Bench Press", primaryCategory: "Chest", secondaryCategory: ["Triceps"], equipment: "free-weight")
            ExerciseData(name: "Machine Fly", primaryCategory: "Chest", secondaryCategory: ["Shoulders"], equipment: "machine")
            ExerciseData(name: "Weighted Dips", primaryCategory: "Chest", secondaryCategory: ["Triceps", "Shoulders"], equipment: "bodyweight")
            ExerciseData(name: "Smith Machine Bench Press", primaryCategory: "Chest", secondaryCategory: ["Triceps", "Shoulders"], equipment: "machine")
            // Back Exercises
            ExerciseData(name: "Barbell Deadlift", primaryCategory: "Back", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "free-weight")
            ExerciseData(name: "Barbell Row", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "free-weight")
            ExerciseData(name: "Lat Pulldown", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "machine")
            ExerciseData(name: "Pull-ups", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "bodyweight")
            ExerciseData(name: "Chin-ups", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "bodyweight")
            ExerciseData(name: "Cable Row", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "machine")
            ExerciseData(name: "Dumbbell Row", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "free-weight")
            ExerciseData(name: "Face Pulls", primaryCategory: "Back", secondaryCategory: ["Shoulders"], equipment: "machine")
            ExerciseData(name: "T-Bar Row", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "free-weight")
            ExerciseData(name: "Machine Row", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "machine")
            ExerciseData(name: "Romanian Deadlift", primaryCategory: "Back", secondaryCategory: ["Hamstrings", "Glutes"], equipment: "free-weight")
            ExerciseData(name: "Bent-Over Dumbbell Row", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "free-weight")
            ExerciseData(name: "Pendlay Row", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "free-weight")
            ExerciseData(name: "Assisted Pull-ups", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "machine")
            ExerciseData(name: "Smith Machine Row", primaryCategory: "Back", secondaryCategory: ["Biceps"], equipment: "machine")
            // Shoulder Exercises
            ExerciseData(name: "Overhead Press", primaryCategory: "Shoulders", secondaryCategory: ["Triceps", "Chest"], equipment: "free-weight")
            ExerciseData(name: "Dumbbell Shoulder Press", primaryCategory: "Shoulders", secondaryCategory: ["Triceps", "Chest"], equipment: "free-weight")
            ExerciseData(name: "Machine Shoulder Press", primaryCategory: "Shoulders", secondaryCategory: ["Triceps"], equipment: "machine")
            ExerciseData(name: "Lateral Raise", primaryCategory: "Shoulders", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Cable Lateral Raise", primaryCategory: "Shoulders", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Rear Delt Flyes", primaryCategory: "Shoulders", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Machine Rear Delt Fly", primaryCategory: "Shoulders", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Upright Row", primaryCategory: "Shoulders", secondaryCategory: ["Biceps"], equipment: "free-weight")
            ExerciseData(name: "Dumbbell Upright Row", primaryCategory: "Shoulders", secondaryCategory: ["Biceps"], equipment: "free-weight")
            ExerciseData(name: "Arnold Press", primaryCategory: "Shoulders", secondaryCategory: ["Triceps", "Chest"], equipment: "free-weight")
            ExerciseData(name: "Pike Push-ups", primaryCategory: "Shoulders", secondaryCategory: ["Triceps", "Chest"], equipment: "bodyweight")
            ExerciseData(name: "Barbell Shrug", primaryCategory: "Shoulders", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Dumbbell Shrug", primaryCategory: "Shoulders", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Smith Machine Shoulder Press", primaryCategory: "Shoulders", secondaryCategory: ["Triceps"], equipment: "machine")
            // Biceps Exercises
            ExerciseData(name: "Barbell Curl", primaryCategory: "Biceps", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Dumbbell Curl", primaryCategory: "Biceps", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Machine Curl", primaryCategory: "Biceps", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Cable Curl", primaryCategory: "Biceps", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Hammer Curl", primaryCategory: "Biceps", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Incline Dumbbell Curl", primaryCategory: "Biceps", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "EZ-Bar Curl", primaryCategory: "Biceps", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Preacher Curl", primaryCategory: "Biceps", secondaryCategory: [], equipment: "free-weight")
            // Tricep Exercises
            ExerciseData(name: "Tricep Dips", primaryCategory: "Triceps", secondaryCategory: ["Chest", "Shoulders"], equipment: "bodyweight")
            ExerciseData(name: "Tricep Pushdown", primaryCategory: "Triceps", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Overhead Tricep Extension", primaryCategory: "Triceps", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Machine Tricep Extension", primaryCategory: "Triceps", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Skullcrusher", primaryCategory: "Triceps", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Dumbbell Skullcrusher", primaryCategory: "Triceps", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Rope Pushdown", primaryCategory: "Triceps", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Close-Grip Bench Press", primaryCategory: "Triceps", secondaryCategory: ["Chest", "Shoulders"], equipment: "free-weight")
            ExerciseData(name: "Machine Dips", primaryCategory: "Triceps", secondaryCategory: ["Chest", "Shoulders"], equipment: "machine")
            // Quads Exercises
            ExerciseData(name: "Barbell Squat", primaryCategory: "Quads", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "free-weight")
            ExerciseData(name: "Leg Press", primaryCategory: "Quads", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "machine")
            ExerciseData(name: "Leg Extension", primaryCategory: "Quads", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Goblet Squat", primaryCategory: "Quads", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "free-weight")
            ExerciseData(name: "Smith Machine Squat", primaryCategory: "Quads", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "machine")
            ExerciseData(name: "Front Squat", primaryCategory: "Quads", secondaryCategory: ["Glutes"], equipment: "free-weight")
            ExerciseData(name: "Bulgarian Split Squat", primaryCategory: "Quads", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "free-weight")
            ExerciseData(name: "Dumbbell Lunge", primaryCategory: "Quads", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "free-weight")
            ExerciseData(name: "Barbell Lunge", primaryCategory: "Quads", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "free-weight")
            ExerciseData(name: "Hack Squat", primaryCategory: "Quads", secondaryCategory: ["Glutes", "Hamstrings"], equipment: "machine")
            // Glute Exercises
            ExerciseData(name: "Barbell Hip Thrust", primaryCategory: "Glutes", secondaryCategory: ["Hamstrings"], equipment: "free-weight")
            ExerciseData(name: "Glute Bridge", primaryCategory: "Glutes", secondaryCategory: ["Hamstrings"], equipment: "bodyweight")
            ExerciseData(name: "Cable Pull-Through", primaryCategory: "Glutes", secondaryCategory: ["Hamstrings", "Back"], equipment: "machine")
            ExerciseData(name: "Weighted Glute Bridge", primaryCategory: "Glutes", secondaryCategory: ["Hamstrings"], equipment: "free-weight")
            ExerciseData(name: "Hip Abduction Machine", primaryCategory: "Glutes", secondaryCategory: [], equipment: "machine")
            // Hamstring Exercises
            ExerciseData(name: "Deadlift", primaryCategory: "Hamstrings", secondaryCategory: ["Glutes", "Back"], equipment: "free-weight")
            ExerciseData(name: "Romanian Deadlift", primaryCategory: "Hamstrings", secondaryCategory: ["Glutes", "Back"], equipment: "free-weight")
            ExerciseData(name: "Leg Curl", primaryCategory: "Hamstrings", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Lying Leg Curl", primaryCategory: "Hamstrings", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Dumbbell Deadlift", primaryCategory: "Hamstrings", secondaryCategory: ["Glutes", "Back"], equipment: "free-weight")
            ExerciseData(name: "Smith Machine Deadlift", primaryCategory: "Hamstrings", secondaryCategory: ["Glutes", "Back"], equipment: "machine")
            
            // Core Exercises
            ExerciseData(name: "Plank", primaryCategory: "Abs", secondaryCategory: [], equipment: "bodyweight")
            ExerciseData(name: "Ab Wheel Rollout", primaryCategory: "Abs", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Cable Crunch", primaryCategory: "Abs", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Machine Crunch", primaryCategory: "Abs", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Weighted Crunch", primaryCategory: "Abs", secondaryCategory: [], equipment: "free-weight")
            ExerciseData(name: "Cable Woodchop", primaryCategory: "Abs", secondaryCategory: [], equipment: "machine")
            ExerciseData(name: "Hanging Leg Raise", primaryCategory: "Abs", secondaryCategory: [], equipment: "bodyweight")
            ExerciseData(name: "Decline Sit-up", primaryCategory: "Abs", secondaryCategory: [], equipment: "bodyweight")
            ExerciseData(name: "Pallof Press", primaryCategory: "Abs", secondaryCategory: [], equipment: "machine")
            ]
    }
}

private struct ExerciseData {
    let name: String
    let primaryCategory: String
    let secondaryCategories: [String]
    let equipment: String
}
