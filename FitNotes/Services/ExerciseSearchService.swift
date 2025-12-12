import Foundation

// MARK: - ExerciseSearchService
public final class ExerciseSearchService {
    public static let shared = ExerciseSearchService()
    private init() {}
    
    /// Search exercises by query and optional category and equipment filters
    /// - Parameters:
    ///   - query: Search text to match against exercise names
    ///   - category: Optional primary category filter (muscle group)
    ///   - equipment: Optional equipment filter
    ///   - exercises: Array of exercises to search through
    /// - Returns: Filtered array of exercises matching the criteria
    public func searchExercises(
        query: String,
        category: String?,
        equipment: String?,
        exercises: [Exercise]
    ) -> [Exercise] {
        var filteredExercises = exercises
        
        // Filter by primary category if provided
        if let category = category, !category.isEmpty {
            filteredExercises = filteredExercises.filter { $0.primaryCategory == category }
        }
        
        // Filter by equipment if provided
        if let equipment = equipment, !equipment.isEmpty {
            filteredExercises = filteredExercises.filter { $0.equipment == equipment }
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
