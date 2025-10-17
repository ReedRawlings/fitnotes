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
        "Bodyweight", "Dumbbells", "Barbell", "Kettlebell", "Resistance Bands",
        "Machine", "Cable", "Medicine Ball", "TRX", "Bench", "Pull-up Bar"
    ]
    
    // Difficulty levels
    public static let difficultyLevels = [
        "Beginner", "Intermediate", "Advanced"
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
                secondaryMuscles: exerciseData.secondaryMuscles,
                type: exerciseData.type,
                equipment: exerciseData.equipment,
                difficulty: exerciseData.difficulty,
                instructions: exerciseData.instructions,
                isCustom: false
            )
            modelContext.insert(exercise)
        }
        
        try? modelContext.save()
    }
    
    private func getDefaultExercises() -> [ExerciseData] {
        return [
            // Chest Exercises
            ExerciseData(
                name: "Push-ups",
                category: "Chest",
                secondaryMuscles: ["Shoulders", "Triceps", "Core"],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Start in plank position, lower chest to ground, push back up"
            ),
            ExerciseData(
                name: "Bench Press",
                category: "Chest",
                secondaryMuscles: ["Shoulders", "Triceps"],
                type: "Strength",
                equipment: "Barbell",
                difficulty: "Intermediate",
                instructions: "Lie on bench, lower bar to chest, press up to starting position"
            ),
            ExerciseData(
                name: "Incline Dumbbell Press",
                category: "Chest",
                secondaryMuscles: ["Shoulders", "Triceps"],
                type: "Strength",
                equipment: "Dumbbells",
                difficulty: "Intermediate",
                instructions: "Sit on inclined bench, press dumbbells up and together"
            ),
            ExerciseData(
                name: "Dumbbell Flyes",
                category: "Chest",
                secondaryMuscles: ["Shoulders"],
                type: "Strength",
                equipment: "Dumbbells",
                difficulty: "Intermediate",
                instructions: "Lie on bench, lower dumbbells in wide arc, bring together over chest"
            ),
            
            // Back Exercises
            ExerciseData(
                name: "Pull-ups",
                category: "Back",
                secondaryMuscles: ["Biceps", "Shoulders"],
                type: "Strength",
                equipment: "Pull-up Bar",
                difficulty: "Intermediate",
                instructions: "Hang from bar, pull body up until chin over bar, lower with control"
            ),
            ExerciseData(
                name: "Lat Pulldown",
                category: "Back",
                secondaryMuscles: ["Biceps", "Shoulders"],
                type: "Strength",
                equipment: "Machine",
                difficulty: "Beginner",
                instructions: "Sit at lat pulldown machine, pull bar down to chest, return slowly"
            ),
            ExerciseData(
                name: "Bent-over Row",
                category: "Back",
                secondaryMuscles: ["Biceps", "Shoulders"],
                type: "Strength",
                equipment: "Barbell",
                difficulty: "Intermediate",
                instructions: "Bend forward, pull bar to lower chest, squeeze shoulder blades"
            ),
            ExerciseData(
                name: "Deadlift",
                category: "Back",
                secondaryMuscles: ["Legs", "Glutes", "Core"],
                type: "Strength",
                equipment: "Barbell",
                difficulty: "Advanced",
                instructions: "Stand with feet hip-width apart, lift bar from ground to standing position"
            ),
            
            // Shoulder Exercises
            ExerciseData(
                name: "Overhead Press",
                category: "Shoulders",
                secondaryMuscles: ["Triceps", "Core"],
                type: "Strength",
                equipment: "Barbell",
                difficulty: "Intermediate",
                instructions: "Press bar from shoulders to overhead, lower with control"
            ),
            ExerciseData(
                name: "Lateral Raises",
                category: "Shoulders",
                secondaryMuscles: [],
                type: "Strength",
                equipment: "Dumbbells",
                difficulty: "Beginner",
                instructions: "Raise dumbbells to sides until arms parallel to ground"
            ),
            ExerciseData(
                name: "Face Pulls",
                category: "Shoulders",
                secondaryMuscles: ["Back"],
                type: "Strength",
                equipment: "Cable",
                difficulty: "Beginner",
                instructions: "Pull cable to face, focus on external rotation"
            ),
            
            // Arm Exercises
            ExerciseData(
                name: "Bicep Curls",
                category: "Arms",
                secondaryMuscles: [],
                type: "Strength",
                equipment: "Dumbbells",
                difficulty: "Beginner",
                instructions: "Curl dumbbells from sides to shoulders, squeeze biceps at top"
            ),
            ExerciseData(
                name: "Tricep Dips",
                category: "Arms",
                secondaryMuscles: ["Shoulders", "Chest"],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Intermediate",
                instructions: "Lower body by bending elbows, push back up to starting position"
            ),
            ExerciseData(
                name: "Hammer Curls",
                category: "Arms",
                secondaryMuscles: [],
                type: "Strength",
                equipment: "Dumbbells",
                difficulty: "Beginner",
                instructions: "Curl dumbbells with neutral grip, palms facing each other"
            ),
            
            // Leg Exercises
            ExerciseData(
                name: "Squats",
                category: "Legs",
                secondaryMuscles: ["Glutes", "Core"],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Lower body as if sitting back into chair, drive through heels to stand"
            ),
            ExerciseData(
                name: "Lunges",
                category: "Legs",
                secondaryMuscles: ["Glutes"],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Step forward into lunge, lower back knee toward ground, return to start"
            ),
            ExerciseData(
                name: "Leg Press",
                category: "Legs",
                secondaryMuscles: ["Glutes"],
                type: "Strength",
                equipment: "Machine",
                difficulty: "Beginner",
                instructions: "Sit in leg press machine, press weight away with legs"
            ),
            ExerciseData(
                name: "Romanian Deadlift",
                category: "Legs",
                secondaryMuscles: ["Glutes", "Back"],
                type: "Strength",
                equipment: "Barbell",
                difficulty: "Intermediate",
                instructions: "Lower bar by hinging at hips, feel stretch in hamstrings"
            ),
            
            // Core Exercises
            ExerciseData(
                name: "Plank",
                category: "Core",
                secondaryMuscles: ["Shoulders", "Glutes"],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Hold body in straight line, engage core muscles"
            ),
            ExerciseData(
                name: "Crunches",
                category: "Core",
                secondaryMuscles: [],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Lift shoulders off ground by contracting abs"
            ),
            ExerciseData(
                name: "Russian Twists",
                category: "Core",
                secondaryMuscles: ["Obliques"],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Intermediate",
                instructions: "Sit and rotate torso side to side, engage obliques"
            ),
            
            // Glute Exercises
            ExerciseData(
                name: "Hip Thrusts",
                category: "Glutes",
                secondaryMuscles: ["Core", "Hamstrings"],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Drive hips up from bridge position, squeeze glutes at top"
            ),
            ExerciseData(
                name: "Glute Bridges",
                category: "Glutes",
                secondaryMuscles: ["Core", "Hamstrings"],
                type: "Strength",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Lift hips up from lying position, squeeze glutes"
            ),
            
            // Cardio Exercises
            ExerciseData(
                name: "Running",
                category: "Cardio",
                secondaryMuscles: ["Legs", "Core"],
                type: "Cardio",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Maintain steady pace for cardiovascular fitness"
            ),
            ExerciseData(
                name: "Jumping Jacks",
                category: "Cardio",
                secondaryMuscles: ["Legs", "Shoulders"],
                type: "Cardio",
                equipment: "Bodyweight",
                difficulty: "Beginner",
                instructions: "Jump feet apart while raising arms overhead, return to start"
            ),
            ExerciseData(
                name: "Burpees",
                category: "Cardio",
                secondaryMuscles: ["Full Body"],
                type: "Cardio",
                equipment: "Bodyweight",
                difficulty: "Advanced",
                instructions: "Squat down, jump back to plank, do push-up, jump feet forward, jump up"
            )
        ]
    }
}

private struct ExerciseData {
    let name: String
    let category: String
    let secondaryMuscles: [String]
    let type: String
    let equipment: String
    let difficulty: String
    let instructions: String
}
