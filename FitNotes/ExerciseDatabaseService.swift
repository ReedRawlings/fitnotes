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
    
    
    // Exercise types
    public static let exerciseTypes = [
        "Strength", "Cardio", "Flexibility", "Balance", "Plyometric"
    ]
    
    public func createDefaultExercises(modelContext: ModelContext) {
        let defaultExercises = getDefaultExercises()
        
        for exerciseData in defaultExercises {
            let exercise = Exercise(
                name: exerciseData.name,
                category: exerciseData.category,
                type: exerciseData.type,
                isCustom: false
            )
            modelContext.insert(exercise)
        }
        
        try? modelContext.save()
    }
    
    private func getDefaultExercises() -> [ExerciseData] {
        return [
            // Chest Exercises
            ExerciseData(name: "Push-ups", category: "Chest", type: "Strength"),
            ExerciseData(name: "Bench Press", category: "Chest", type: "Strength"),
            ExerciseData(name: "Incline Dumbbell Press", category: "Chest", type: "Strength"),
            ExerciseData(name: "Dumbbell Flyes", category: "Chest", type: "Strength"),
            
            // Back Exercises
            ExerciseData(name: "Pull-ups", category: "Back", type: "Strength"),
            ExerciseData(name: "Lat Pulldown", category: "Back", type: "Strength"),
            ExerciseData(name: "Bent-over Row", category: "Back", type: "Strength"),
            ExerciseData(name: "Deadlift", category: "Back", type: "Strength"),
            
            // Shoulder Exercises
            ExerciseData(name: "Overhead Press", category: "Shoulders", type: "Strength"),
            ExerciseData(name: "Lateral Raises", category: "Shoulders", type: "Strength"),
            ExerciseData(name: "Face Pulls", category: "Shoulders", type: "Strength"),
            
            // Arm Exercises
            ExerciseData(name: "Bicep Curls", category: "Arms", type: "Strength"),
            ExerciseData(name: "Tricep Dips", category: "Arms", type: "Strength"),
            ExerciseData(name: "Hammer Curls", category: "Arms", type: "Strength"),
            
            // Leg Exercises
            ExerciseData(name: "Squats", category: "Legs", type: "Strength"),
            ExerciseData(name: "Lunges", category: "Legs", type: "Strength"),
            ExerciseData(name: "Leg Press", category: "Legs", type: "Strength"),
            ExerciseData(name: "Romanian Deadlift", category: "Legs", type: "Strength"),
            
            // Core Exercises
            ExerciseData(name: "Plank", category: "Core", type: "Strength"),
            ExerciseData(name: "Crunches", category: "Core", type: "Strength"),
            ExerciseData(name: "Russian Twists", category: "Core", type: "Strength"),
            
            // Glute Exercises
            ExerciseData(name: "Hip Thrusts", category: "Glutes", type: "Strength"),
            ExerciseData(name: "Glute Bridges", category: "Glutes", type: "Strength"),
            
            // Cardio Exercises
            ExerciseData(name: "Running", category: "Cardio", type: "Cardio"),
            ExerciseData(name: "Jumping Jacks", category: "Cardio", type: "Cardio"),
            ExerciseData(name: "Burpees", category: "Cardio", type: "Cardio")
        ]
    }
}

private struct ExerciseData {
    let name: String
    let category: String
    let type: String
}
