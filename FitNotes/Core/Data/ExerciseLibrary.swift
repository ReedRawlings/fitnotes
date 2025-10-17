import Foundation

// MARK: - Exercise Library
public struct ExerciseLibrary {
    
    // MARK: - Muscle Group Categories
    public enum MuscleGroup: String, CaseIterable {
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case biceps = "Biceps"
        case triceps = "Triceps"
        case legs = "Legs"
        case glutes = "Glutes"
        case core = "Core"
        case calves = "Calves"
        case forearms = "Forearms"
        case fullBody = "Full Body"
        case cardio = "Cardio"
    }
    
    // MARK: - Exercise Type
    public enum ExerciseType: String, CaseIterable {
        case strength = "Strength"
        case cardio = "Cardio"
        case flexibility = "Flexibility"
        case plyometric = "Plyometric"
        case isometric = "Isometric"
        case endurance = "Endurance"
    }
    
    // MARK: - Exercise Data Structure
    public struct ExerciseData {
        let name: String
        let category: MuscleGroup
        let type: ExerciseType
        let notes: String?
        let unit: String
        let isBodyweight: Bool
    }
    
    // MARK: - Exercise Database
    public static let exercises: [ExerciseData] = [
        // MARK: - Chest Exercises
        ExerciseData(name: "Bench Press", category: .chest, type: .strength, notes: "Lie flat on bench, lower bar to chest, press up", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Incline Bench Press", category: .chest, type: .strength, notes: "Bench at 30-45 degree angle", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Decline Bench Press", category: .chest, type: .strength, notes: "Bench at decline angle", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Dumbbell Press", category: .chest, type: .strength, notes: "Press dumbbells from chest level", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Incline Dumbbell Press", category: .chest, type: .strength, notes: "Press dumbbells on inclined bench", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Push-ups", category: .chest, type: .strength, notes: "Bodyweight chest exercise", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Incline Push-ups", category: .chest, type: .strength, notes: "Feet elevated push-ups", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Decline Push-ups", category: .chest, type: .strength, notes: "Hands elevated push-ups", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Diamond Push-ups", category: .chest, type: .strength, notes: "Hands close together in diamond shape", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Chest Flyes", category: .chest, type: .strength, notes: "Dumbbell flyes on bench", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Incline Chest Flyes", category: .chest, type: .strength, notes: "Flyes on inclined bench", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Cable Chest Flyes", category: .chest, type: .strength, notes: "Cable crossover flyes", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Dips", category: .chest, type: .strength, notes: "Chest-focused dips", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Dumbbell Pullovers", category: .chest, type: .strength, notes: "Lie perpendicular on bench", unit: "kg", isBodyweight: false),
        
        // MARK: - Back Exercises
        ExerciseData(name: "Deadlift", category: .back, type: .strength, notes: "Lift bar from floor to standing position", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Romanian Deadlift", category: .back, type: .strength, notes: "Deadlift with straight legs", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Sumo Deadlift", category: .back, type: .strength, notes: "Wide stance deadlift", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Pull-ups", category: .back, type: .strength, notes: "Hang from bar, pull body up", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Chin-ups", category: .back, type: .strength, notes: "Pull-ups with palms facing you", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Lat Pulldown", category: .back, type: .strength, notes: "Pull bar down to chest", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Wide Grip Lat Pulldown", category: .back, type: .strength, notes: "Wide grip pulldown", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Close Grip Lat Pulldown", category: .back, type: .strength, notes: "Close grip pulldown", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Bent Over Row", category: .back, type: .strength, notes: "Bend forward, row bar to chest", unit: "kg", isBodyweight: false),
        ExerciseData(name: "T-Bar Row", category: .back, type: .strength, notes: "Row T-bar to chest", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Cable Row", category: .back, type: .strength, notes: "Seated cable row", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Dumbbell Row", category: .back, type: .strength, notes: "Single arm dumbbell row", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Face Pulls", category: .back, type: .strength, notes: "Cable face pulls", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Reverse Flyes", category: .back, type: .strength, notes: "Dumbbell reverse flyes", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Hyperextensions", category: .back, type: .strength, notes: "Back extensions on hyperextension bench", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Good Mornings", category: .back, type: .strength, notes: "Bend forward with bar on shoulders", unit: "kg", isBodyweight: false),
        
        // MARK: - Shoulder Exercises
        ExerciseData(name: "Overhead Press", category: .shoulders, type: .strength, notes: "Press bar overhead from shoulders", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Dumbbell Shoulder Press", category: .shoulders, type: .strength, notes: "Press dumbbells overhead", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Arnold Press", category: .shoulders, type: .strength, notes: "Rotating dumbbell press", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Lateral Raises", category: .shoulders, type: .strength, notes: "Raise dumbbells to sides", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Front Raises", category: .shoulders, type: .strength, notes: "Raise dumbbells in front", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Rear Delt Flyes", category: .shoulders, type: .strength, notes: "Bent over rear delt flyes", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Upright Row", category: .shoulders, type: .strength, notes: "Row bar up to chest level", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Shrugs", category: .shoulders, type: .strength, notes: "Shrug shoulders up and down", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Pike Push-ups", category: .shoulders, type: .strength, notes: "Handstand push-up progression", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Handstand Push-ups", category: .shoulders, type: .strength, notes: "Push-ups in handstand position", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Cable Lateral Raises", category: .shoulders, type: .strength, notes: "Cable lateral raises", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Cable Front Raises", category: .shoulders, type: .strength, notes: "Cable front raises", unit: "kg", isBodyweight: false),
        
        // MARK: - Bicep Exercises
        ExerciseData(name: "Barbell Curls", category: .biceps, type: .strength, notes: "Curl barbell with both hands", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Dumbbell Curls", category: .biceps, type: .strength, notes: "Curl dumbbells with both hands", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Hammer Curls", category: .biceps, type: .strength, notes: "Curl dumbbells with neutral grip", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Preacher Curls", category: .biceps, type: .strength, notes: "Curl on preacher bench", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Concentration Curls", category: .biceps, type: .strength, notes: "Single arm seated curls", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Cable Curls", category: .biceps, type: .strength, notes: "Cable bicep curls", unit: "kg", isBodyweight: false),
        ExerciseData(name: "21s", category: .biceps, type: .strength, notes: "7 reps bottom half, 7 reps top half, 7 full reps", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Incline Dumbbell Curls", category: .biceps, type: .strength, notes: "Curls on inclined bench", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Spider Curls", category: .biceps, type: .strength, notes: "Curls on inclined bench face down", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Reverse Curls", category: .biceps, type: .strength, notes: "Curl with overhand grip", unit: "kg", isBodyweight: false),
        
        // MARK: - Tricep Exercises
        ExerciseData(name: "Close Grip Bench Press", category: .triceps, type: .strength, notes: "Bench press with narrow grip", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Dips", category: .triceps, type: .strength, notes: "Tricep-focused dips", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Overhead Tricep Extension", category: .triceps, type: .strength, notes: "Extend dumbbell overhead", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Skull Crushers", category: .triceps, type: .strength, notes: "Lying tricep extension", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Tricep Pushdowns", category: .triceps, type: .strength, notes: "Cable tricep pushdowns", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Diamond Push-ups", category: .triceps, type: .strength, notes: "Push-ups with diamond hand position", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Overhead Cable Extension", category: .triceps, type: .strength, notes: "Cable overhead tricep extension", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Tricep Kickbacks", category: .triceps, type: .strength, notes: "Bent over tricep kickbacks", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Close Grip Push-ups", category: .triceps, type: .strength, notes: "Push-ups with hands close together", unit: "reps", isBodyweight: true),
        ExerciseData(name: "JM Press", category: .triceps, type: .strength, notes: "Hybrid between close grip bench and skull crushers", unit: "kg", isBodyweight: false),
        
        // MARK: - Leg Exercises
        ExerciseData(name: "Squats", category: .legs, type: .strength, notes: "Basic squat movement", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Bodyweight Squats", category: .legs, type: .strength, notes: "Squats without weight", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Front Squats", category: .legs, type: .strength, notes: "Squats with bar in front", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Overhead Squats", category: .legs, type: .strength, notes: "Squats with bar overhead", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Goblet Squats", category: .legs, type: .strength, notes: "Squats holding dumbbell at chest", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Bulgarian Split Squats", category: .legs, type: .strength, notes: "Single leg squats with rear foot elevated", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Lunges", category: .legs, type: .strength, notes: "Step forward into lunge position", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Walking Lunges", category: .legs, type: .strength, notes: "Lunges while walking forward", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Reverse Lunges", category: .legs, type: .strength, notes: "Step backward into lunge position", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Leg Press", category: .legs, type: .strength, notes: "Seated leg press machine", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Hack Squats", category: .legs, type: .strength, notes: "Hack squat machine", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Leg Extensions", category: .legs, type: .strength, notes: "Quad extension machine", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Leg Curls", category: .legs, type: .strength, notes: "Hamstring curl machine", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Romanian Deadlifts", category: .legs, type: .strength, notes: "Straight leg deadlifts", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Stiff Leg Deadlifts", category: .legs, type: .strength, notes: "Deadlifts with straight legs", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Step-ups", category: .legs, type: .strength, notes: "Step up onto platform", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Pistol Squats", category: .legs, type: .strength, notes: "Single leg squats", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Jump Squats", category: .legs, type: .plyometric, notes: "Explosive squats with jump", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Box Jumps", category: .legs, type: .plyometric, notes: "Jump onto box/platform", unit: "reps", isBodyweight: true),
        
        // MARK: - Glute Exercises
        ExerciseData(name: "Hip Thrusts", category: .glutes, type: .strength, notes: "Thrust hips up from seated position", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Glute Bridges", category: .glutes, type: .strength, notes: "Bridge hips up from lying position", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Single Leg Glute Bridges", category: .glutes, type: .strength, notes: "One leg glute bridges", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Romanian Deadlifts", category: .glutes, type: .strength, notes: "RDLs target glutes and hamstrings", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Bulgarian Split Squats", category: .glutes, type: .strength, notes: "Single leg squats with rear foot elevated", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Lunges", category: .glutes, type: .strength, notes: "Forward lunges", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Reverse Lunges", category: .glutes, type: .strength, notes: "Backward lunges", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Lateral Lunges", category: .glutes, type: .strength, notes: "Side lunges", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Clamshells", category: .glutes, type: .strength, notes: "Side-lying hip abduction", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Fire Hydrants", category: .glutes, type: .strength, notes: "On hands and knees, lift leg to side", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Donkey Kicks", category: .glutes, type: .strength, notes: "On hands and knees, kick leg back", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Cable Kickbacks", category: .glutes, type: .strength, notes: "Cable glute kickbacks", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Sumo Squats", category: .glutes, type: .strength, notes: "Wide stance squats", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Monster Walks", category: .glutes, type: .strength, notes: "Lateral walks with resistance band", unit: "reps", isBodyweight: true),
        
        // MARK: - Core Exercises
        ExerciseData(name: "Plank", category: .core, type: .isometric, notes: "Hold push-up position", unit: "seconds", isBodyweight: true),
        ExerciseData(name: "Side Plank", category: .core, type: .isometric, notes: "Hold side position", unit: "seconds", isBodyweight: true),
        ExerciseData(name: "Dead Bug", category: .core, type: .strength, notes: "Lie on back, extend opposite arm and leg", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Bird Dog", category: .core, type: .strength, notes: "On hands and knees, extend opposite arm and leg", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Crunches", category: .core, type: .strength, notes: "Basic crunches", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Bicycle Crunches", category: .core, type: .strength, notes: "Alternating elbow to knee crunches", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Russian Twists", category: .core, type: .strength, notes: "Seated twists with weight", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Mountain Climbers", category: .core, type: .cardio, notes: "Alternating knee to chest in plank", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Hollow Body Hold", category: .core, type: .isometric, notes: "Lie on back, lift shoulders and legs", unit: "seconds", isBodyweight: true),
        ExerciseData(name: "L-Sit", category: .core, type: .isometric, notes: "Hold body in L-shape", unit: "seconds", isBodyweight: true),
        ExerciseData(name: "Hanging Leg Raises", category: .core, type: .strength, notes: "Hang from bar, raise legs", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Knee Raises", category: .core, type: .strength, notes: "Hang from bar, raise knees", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Ab Wheel Rollouts", category: .core, type: .strength, notes: "Roll ab wheel forward and back", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Dragon Flags", category: .core, type: .strength, notes: "Advanced core exercise", unit: "reps", isBodyweight: true),
        ExerciseData(name: "V-Ups", category: .core, type: .strength, notes: "Sit up while bringing legs up", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Flutter Kicks", category: .core, type: .strength, notes: "Lie on back, alternate leg kicks", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Scissor Kicks", category: .core, type: .strength, notes: "Lie on back, scissor legs", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Wood Chops", category: .core, type: .strength, notes: "Diagonal cable or dumbbell chops", unit: "kg", isBodyweight: false),
        
        // MARK: - Calf Exercises
        ExerciseData(name: "Calf Raises", category: .calves, type: .strength, notes: "Standing calf raises", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Seated Calf Raises", category: .calves, type: .strength, notes: "Calf raises while seated", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Single Leg Calf Raises", category: .calves, type: .strength, notes: "One leg at a time", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Donkey Calf Raises", category: .calves, type: .strength, notes: "Bent over calf raises", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Jump Rope", category: .calves, type: .cardio, notes: "Jump rope for calf endurance", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Box Jumps", category: .calves, type: .plyometric, notes: "Explosive jumps onto box", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Calf Press", category: .calves, type: .strength, notes: "Calf press on leg press machine", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Farmer's Walk", category: .calves, type: .strength, notes: "Walk with heavy weights", unit: "kg", isBodyweight: false),
        
        // MARK: - Forearm Exercises
        ExerciseData(name: "Wrist Curls", category: .forearms, type: .strength, notes: "Curl wrists up", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Reverse Wrist Curls", category: .forearms, type: .strength, notes: "Curl wrists down", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Farmer's Walk", category: .forearms, type: .strength, notes: "Walk with heavy weights", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Plate Pinches", category: .forearms, type: .strength, notes: "Pinch weight plates together", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Towel Pull-ups", category: .forearms, type: .strength, notes: "Pull-ups using towel", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Grip Crushers", category: .forearms, type: .strength, notes: "Squeeze grip strengthener", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Hammer Curls", category: .forearms, type: .strength, notes: "Neutral grip curls", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Reverse Curls", category: .forearms, type: .strength, notes: "Overhand grip curls", unit: "kg", isBodyweight: false),
        
        // MARK: - Full Body Exercises
        ExerciseData(name: "Burpees", category: .fullBody, type: .cardio, notes: "Squat, plank, push-up, jump", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Thrusters", category: .fullBody, type: .strength, notes: "Squat to overhead press", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Clean and Press", category: .fullBody, type: .strength, notes: "Olympic lift movement", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Kettlebell Swings", category: .fullBody, type: .strength, notes: "Hip hinge swing movement", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Turkish Get-ups", category: .fullBody, type: .strength, notes: "Complex movement from lying to standing", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Bear Crawls", category: .fullBody, type: .strength, notes: "Crawl on hands and feet", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Crab Walks", category: .fullBody, type: .strength, notes: "Walk in crab position", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Man Makers", category: .fullBody, type: .strength, notes: "Complex full body movement", unit: "kg", isBodyweight: false),
        ExerciseData(name: "Mountain Climbers", category: .fullBody, type: .cardio, notes: "Alternating knee to chest", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Jumping Jacks", category: .fullBody, type: .cardio, notes: "Jump while spreading arms and legs", unit: "reps", isBodyweight: true),
        ExerciseData(name: "High Knees", category: .fullBody, type: .cardio, notes: "Run in place with high knees", unit: "reps", isBodyweight: true),
        ExerciseData(name: "Butt Kicks", category: .fullBody, type: .cardio, notes: "Run in place kicking heels to glutes", unit: "reps", isBodyweight: true),
        
        // MARK: - Cardio Exercises
        ExerciseData(name: "Running", category: .cardio, type: .cardio, notes: "Outdoor or treadmill running", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Cycling", category: .cardio, type: .cardio, notes: "Stationary or outdoor cycling", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Rowing", category: .cardio, type: .cardio, notes: "Rowing machine", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Swimming", category: .cardio, type: .cardio, notes: "Swimming laps", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Elliptical", category: .cardio, type: .cardio, notes: "Elliptical machine", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Stair Climbing", category: .cardio, type: .cardio, notes: "Stair climber machine or stairs", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Jump Rope", category: .cardio, type: .cardio, notes: "Jump rope", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "HIIT", category: .cardio, type: .cardio, notes: "High Intensity Interval Training", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Tabata", category: .cardio, type: .cardio, notes: "20 seconds work, 10 seconds rest", unit: "rounds", isBodyweight: true),
        ExerciseData(name: "Walking", category: .cardio, type: .cardio, notes: "Brisk walking", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Hiking", category: .cardio, type: .cardio, notes: "Outdoor hiking", unit: "minutes", isBodyweight: true),
        ExerciseData(name: "Dancing", category: .cardio, type: .cardio, notes: "Dance cardio", unit: "minutes", isBodyweight: true)
    ]
    
    // MARK: - Helper Methods
    public static func exercises(for category: MuscleGroup) -> [ExerciseData] {
        return exercises.filter { $0.category == category }
    }
    
    public static func exercises(for type: ExerciseType) -> [ExerciseData] {
        return exercises.filter { $0.type == type }
    }
    
    public static func bodyweightExercises() -> [ExerciseData] {
        return exercises.filter { $0.isBodyweight }
    }
    
    public static func weightedExercises() -> [ExerciseData] {
        return exercises.filter { !$0.isBodyweight }
    }
    
    public static func searchExercises(query: String) -> [ExerciseData] {
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query) ||
            exercise.category.rawValue.localizedCaseInsensitiveContains(query) ||
            exercise.type.rawValue.localizedCaseInsensitiveContains(query) ||
            (exercise.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}