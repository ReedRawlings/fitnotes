import Foundation
import SwiftUI

// MARK: - Exercise Library View Model
@MainActor
public final class ExerciseLibraryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var exercises: [Exercise] = []
    @Published public var filteredExercises: [Exercise] = []
    @Published public var selectedMuscleGroup: ExerciseLibrary.MuscleGroup? = nil
    @Published public var selectedExerciseType: ExerciseLibrary.ExerciseType? = nil
    @Published public var searchQuery: String = ""
    @Published public var showBodyweightOnly: Bool = false
    @Published public var showWeightedOnly: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    // MARK: - Private Properties
    private let exerciseLibraryService: ExerciseLibraryService
    
    // MARK: - Initialization
    public init(exerciseLibraryService: ExerciseLibraryService) {
        self.exerciseLibraryService = exerciseLibraryService
        loadExercises()
    }
    
    // MARK: - Public Methods
    
    /// Load all exercises
    public func loadExercises() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Initialize the exercise library if needed
                exerciseLibraryService.initializeExerciseLibrary()
                
                let allExercises = exerciseLibraryService.getAllExercises()
                
                await MainActor.run {
                    self.exercises = allExercises
                    self.applyFilters()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load exercises: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Apply current filters to exercises
    public func applyFilters() {
        var filtered = exercises
        
        // Filter by muscle group
        if let muscleGroup = selectedMuscleGroup {
            filtered = filtered.filter { $0.category == muscleGroup.rawValue }
        }
        
        // Filter by exercise type
        if let exerciseType = selectedExerciseType {
            filtered = filtered.filter { $0.type == exerciseType.rawValue }
        }
        
        // Filter by bodyweight/weighted
        if showBodyweightOnly {
            filtered = filtered.filter { $0.unit == "reps" || $0.unit == "seconds" }
        } else if showWeightedOnly {
            filtered = filtered.filter { $0.unit == "kg" }
        }
        
        // Filter by search query
        if !searchQuery.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchQuery) ||
                exercise.category.localizedCaseInsensitiveContains(searchQuery) ||
                exercise.type.localizedCaseInsensitiveContains(searchQuery) ||
                (exercise.notes?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }
        
        filteredExercises = filtered
    }
    
    /// Set muscle group filter
    public func setMuscleGroupFilter(_ muscleGroup: ExerciseLibrary.MuscleGroup?) {
        selectedMuscleGroup = muscleGroup
        applyFilters()
    }
    
    /// Set exercise type filter
    public func setExerciseTypeFilter(_ exerciseType: ExerciseLibrary.ExerciseType?) {
        selectedExerciseType = exerciseType
        applyFilters()
    }
    
    /// Set search query
    public func setSearchQuery(_ query: String) {
        searchQuery = query
        applyFilters()
    }
    
    /// Toggle bodyweight filter
    public func toggleBodyweightFilter() {
        showBodyweightOnly.toggle()
        if showBodyweightOnly {
            showWeightedOnly = false
        }
        applyFilters()
    }
    
    /// Toggle weighted filter
    public func toggleWeightedFilter() {
        showWeightedOnly.toggle()
        if showWeightedOnly {
            showBodyweightOnly = false
        }
        applyFilters()
    }
    
    /// Clear all filters
    public func clearFilters() {
        selectedMuscleGroup = nil
        selectedExerciseType = nil
        searchQuery = ""
        showBodyweightOnly = false
        showWeightedOnly = false
        applyFilters()
    }
    
    /// Get exercises grouped by muscle group
    public func getExercisesGroupedByMuscleGroup() -> [ExerciseLibrary.MuscleGroup: [Exercise]] {
        return exerciseLibraryService.getExercisesGroupedByMuscleGroup()
    }
    
    /// Get exercises grouped by type
    public func getExercisesGroupedByType() -> [ExerciseLibrary.ExerciseType: [Exercise]] {
        return exerciseLibraryService.getExercisesGroupedByType()
    }
    
    /// Get popular exercises
    public func getPopularExercises(limit: Int = 20) -> [Exercise] {
        return exerciseLibraryService.getPopularExercises(limit: limit)
    }
    
    /// Get recommended exercises for a muscle group
    public func getRecommendedExercises(for category: ExerciseLibrary.MuscleGroup, limit: Int = 5) -> [Exercise] {
        return exerciseLibraryService.getRecommendedExercises(for: category, limit: limit)
    }
    
    /// Get exercise count by muscle group
    public func getExerciseCountByMuscleGroup() -> [ExerciseLibrary.MuscleGroup: Int] {
        return exerciseLibraryService.getExerciseCountByMuscleGroup()
    }
    
    /// Get exercise count by type
    public func getExerciseCountByType() -> [ExerciseLibrary.ExerciseType: Int] {
        return exerciseLibraryService.getExerciseCountByType()
    }
    
    /// Get all available muscle groups
    public func getMuscleGroups() -> [ExerciseLibrary.MuscleGroup] {
        return exerciseLibraryService.getMuscleGroups()
    }
    
    /// Get all available exercise types
    public func getExerciseTypes() -> [ExerciseLibrary.ExerciseType] {
        return exerciseLibraryService.getExerciseTypes()
    }
    
    /// Check if any filters are active
    public var hasActiveFilters: Bool {
        return selectedMuscleGroup != nil ||
               selectedExerciseType != nil ||
               !searchQuery.isEmpty ||
               showBodyweightOnly ||
               showWeightedOnly
    }
    
    /// Get filter summary
    public var filterSummary: String {
        var filters: [String] = []
        
        if let muscleGroup = selectedMuscleGroup {
            filters.append("Muscle: \(muscleGroup.rawValue)")
        }
        
        if let exerciseType = selectedExerciseType {
            filters.append("Type: \(exerciseType.rawValue)")
        }
        
        if showBodyweightOnly {
            filters.append("Bodyweight Only")
        } else if showWeightedOnly {
            filters.append("Weighted Only")
        }
        
        if !searchQuery.isEmpty {
            filters.append("Search: \"\(searchQuery)\"")
        }
        
        return filters.joined(separator: " • ")
    }
}