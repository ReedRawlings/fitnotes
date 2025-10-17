import Foundation

// MARK: - Exercise Library Service
public final class ExerciseLibraryService {
    
    private let exerciseRepository: ExerciseRepository
    
    public init(exerciseRepository: ExerciseRepository) {
        self.exerciseRepository = exerciseRepository
    }
    
    // MARK: - Public Methods
    
    /// Get all exercises from the library
    public func getAllExercises() -> [Exercise] {
        return exerciseRepository.all()
    }
    
    /// Get exercises by muscle group
    public func getExercises(for category: ExerciseLibrary.MuscleGroup) -> [Exercise] {
        let allExercises = exerciseRepository.all()
        return allExercises.filter { $0.category == category.rawValue }
    }
    
    /// Get exercises by type
    public func getExercises(for type: ExerciseLibrary.ExerciseType) -> [Exercise] {
        let allExercises = exerciseRepository.all()
        return allExercises.filter { $0.type == type.rawValue }
    }
    
    /// Get bodyweight exercises
    public func getBodyweightExercises() -> [Exercise] {
        let allExercises = exerciseRepository.all()
        return allExercises.filter { $0.unit == "reps" || $0.unit == "seconds" }
    }
    
    /// Get weighted exercises
    public func getWeightedExercises() -> [Exercise] {
        let allExercises = exerciseRepository.all()
        return allExercises.filter { $0.unit == "kg" }
    }
    
    /// Search exercises by query
    public func searchExercises(query: String) -> [Exercise] {
        let allExercises = exerciseRepository.all()
        return allExercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query) ||
            exercise.category.localizedCaseInsensitiveContains(query) ||
            exercise.type.localizedCaseInsensitiveContains(query) ||
            (exercise.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    /// Get all available muscle groups
    public func getMuscleGroups() -> [ExerciseLibrary.MuscleGroup] {
        return ExerciseLibrary.MuscleGroup.allCases
    }
    
    /// Get all available exercise types
    public func getExerciseTypes() -> [ExerciseLibrary.ExerciseType] {
        return ExerciseLibrary.ExerciseType.allCases
    }
    
    /// Get exercises grouped by muscle group
    public func getExercisesGroupedByMuscleGroup() -> [ExerciseLibrary.MuscleGroup: [Exercise]] {
        var grouped: [ExerciseLibrary.MuscleGroup: [Exercise]] = [:]
        
        for muscleGroup in ExerciseLibrary.MuscleGroup.allCases {
            grouped[muscleGroup] = getExercises(for: muscleGroup)
        }
        
        return grouped
    }
    
    /// Get exercises grouped by type
    public func getExercisesGroupedByType() -> [ExerciseLibrary.ExerciseType: [Exercise]] {
        var grouped: [ExerciseLibrary.ExerciseType: [Exercise]] = [:]
        
        for exerciseType in ExerciseLibrary.ExerciseType.allCases {
            grouped[exerciseType] = getExercises(for: exerciseType)
        }
        
        return grouped
    }
    
    /// Get popular exercises (most commonly used)
    public func getPopularExercises(limit: Int = 20) -> [Exercise] {
        // For now, return a curated list of popular exercises
        // In a real app, this would be based on usage statistics
        let popularExerciseNames = [
            "Bench Press", "Squats", "Deadlift", "Pull-ups", "Overhead Press",
            "Push-ups", "Dumbbell Press", "Lunges", "Plank", "Crunches",
            "Bicep Curls", "Tricep Dips", "Lateral Raises", "Romanian Deadlifts",
            "Hip Thrusts", "Calf Raises", "Burpees", "Mountain Climbers",
            "Russian Twists", "Jump Squats"
        ]
        
        let allExercises = exerciseRepository.all()
        return popularExerciseNames.compactMap { name in
            allExercises.first { $0.name == name }
        }.prefix(limit).map { $0 }
    }
    
    /// Get recommended exercises for a specific muscle group
    public func getRecommendedExercises(for category: ExerciseLibrary.MuscleGroup, limit: Int = 5) -> [Exercise] {
        let exercises = getExercises(for: category)
        
        // Return a mix of bodyweight and weighted exercises
        let bodyweight = exercises.filter { $0.unit == "reps" || $0.unit == "seconds" }
        let weighted = exercises.filter { $0.unit == "kg" }
        
        var recommended: [Exercise] = []
        
        // Add 2-3 bodyweight exercises
        recommended.append(contentsOf: bodyweight.prefix(3))
        
        // Add 2-3 weighted exercises
        recommended.append(contentsOf: weighted.prefix(3))
        
        return Array(recommended.prefix(limit))
    }
    
    /// Get exercise count by muscle group
    public func getExerciseCountByMuscleGroup() -> [ExerciseLibrary.MuscleGroup: Int] {
        var counts: [ExerciseLibrary.MuscleGroup: Int] = [:]
        
        for muscleGroup in ExerciseLibrary.MuscleGroup.allCases {
            counts[muscleGroup] = getExercises(for: muscleGroup).count
        }
        
        return counts
    }
    
    /// Get exercise count by type
    public func getExerciseCountByType() -> [ExerciseLibrary.ExerciseType: Int] {
        var counts: [ExerciseLibrary.ExerciseType: Int] = [:]
        
        for exerciseType in ExerciseLibrary.ExerciseType.allCases {
            counts[exerciseType] = getExercises(for: exerciseType).count
        }
        
        return counts
    }
}

// MARK: - Exercise Library Initialization
extension ExerciseLibraryService {
    
    /// Initialize the exercise library with default exercises
    public func initializeExerciseLibrary() {
        // Check if exercises already exist
        let existingExercises = exerciseRepository.all()
        if !existingExercises.isEmpty {
            return // Library already initialized
        }
        
        // Create exercises from the library data
        for exerciseData in ExerciseLibrary.exercises {
            let exercise = Exercise(
                name: exerciseData.name,
                category: exerciseData.category.rawValue,
                type: exerciseData.type.rawValue,
                notes: exerciseData.notes,
                unit: exerciseData.unit
            )
            
            exerciseRepository.upsert(exercise)
        }
    }
    
    /// Reset the exercise library (remove all exercises and reinitialize)
    public func resetExerciseLibrary() {
        // This would require a delete method in the repository
        // For now, we'll just reinitialize
        initializeExerciseLibrary()
    }
}