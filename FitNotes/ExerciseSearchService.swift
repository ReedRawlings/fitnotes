import Foundation

// MARK: - ExerciseSearchService
public final class ExerciseSearchService {
    public static let shared = ExerciseSearchService()
    private init() {}
    
    /// Search exercises by query and optional category filter
    /// - Parameters:
    ///   - query: Search text to match against exercise names
    ///   - category: Optional category filter (muscle group)
    ///   - exercises: Array of exercises to search through
    /// - Returns: Filtered array of exercises matching the criteria
    public func searchExercises(
        query: String,
        category: String?,
        exercises: [Exercise]
    ) -> [Exercise] {
        var filteredExercises = exercises
        
        // Filter by category if provided
        if let category = category, !category.isEmpty {
            filteredExercises = filteredExercises.filter { $0.category == category }
        }
        
        // Filter by search query if provided
        if !query.isEmpty {
            filteredExercises = filteredExercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(query)
            }
        }
        
        return filteredExercises
    }
}
