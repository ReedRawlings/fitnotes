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
                category: exerciseData.category,
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
            ExerciseData(name: "Push-ups", category: "Chest", equipment: "Body"),
            ExerciseData(name: "Bench Press", category: "Chest", equipment: "Machine"),
            ExerciseData(name: "Incline Dumbbell Press", category: "Chest", equipment: "Free Weight"),
            ExerciseData(name: "Dumbbell Flyes", category: "Chest", equipment: "Free Weight"),
            
            // Back Exercises
            ExerciseData(name: "Pull-ups", category: "Back", equipment: "Body"),
            ExerciseData(name: "Lat Pulldown", category: "Back", equipment: "Machine"),
            ExerciseData(name: "Bent-over Row", category: "Back", equipment: "Free Weight"),
            ExerciseData(name: "Deadlift", category: "Back", equipment: "Free Weight"),
            
            // Shoulder Exercises
            ExerciseData(name: "Overhead Press", category: "Shoulders", equipment: "Free Weight"),
            ExerciseData(name: "Lateral Raises", category: "Shoulders", equipment: "Free Weight"),
            ExerciseData(name: "Face Pulls", category: "Shoulders", equipment: "Machine"),
            
            // Arm Exercises
            ExerciseData(name: "Bicep Curls", category: "Arms", equipment: "Free Weight"),
            ExerciseData(name: "Tricep Dips", category: "Arms", equipment: "Body"),
            ExerciseData(name: "Hammer Curls", category: "Arms", equipment: "Free Weight"),
            
            // Leg Exercises
            ExerciseData(name: "Squats", category: "Legs", equipment: "Body"),
            ExerciseData(name: "Lunges", category: "Legs", equipment: "Body"),
            ExerciseData(name: "Leg Press", category: "Legs", equipment: "Machine"),
            ExerciseData(name: "Romanian Deadlift", category: "Legs", equipment: "Free Weight"),
            
            // Core Exercises
            ExerciseData(name: "Plank", category: "Core", equipment: "Body"),
            ExerciseData(name: "Crunches", category: "Core", equipment: "Body"),
            ExerciseData(name: "Russian Twists", category: "Core", equipment: "Body"),
            
            // Glute Exercises
            ExerciseData(name: "Hip Thrusts", category: "Glutes", equipment: "Free Weight"),
            ExerciseData(name: "Glute Bridges", category: "Glutes", equipment: "Body"),
            
            // Cardio Exercises
            ExerciseData(name: "Running", category: "Cardio", equipment: "Body"),
            ExerciseData(name: "Jumping Jacks", category: "Cardio", equipment: "Body"),
            ExerciseData(name: "Burpees", category: "Cardio", equipment: "Body")
        ]
    }
}

private struct ExerciseData {
    let name: String
    let category: String
    let equipment: String
}
