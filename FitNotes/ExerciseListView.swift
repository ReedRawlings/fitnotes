import SwiftUI
import SwiftData

// MARK: - Exercise List Context
enum ExerciseListContext {
    case browse    // For Settings tab - browse and manage exercises
    case picker    // For adding exercises to routines/workouts
}

// MARK: - Unified Exercise List View
struct ExerciseListView: View {
    let exercises: [Exercise]
    @Binding var searchText: String
    let onExerciseSelected: (Exercise) -> Void
    let context: ExerciseListContext
    
    private var filteredExercises: [Exercise] {
        ExerciseSearchService.shared.searchExercises(
            query: searchText,
            category: nil as String?,
            exercises: exercises
        )
    }
    
    var body: some View {
        if filteredExercises.isEmpty {
            EmptyStateView(
                icon: "dumbbell",
                title: "No exercises found",
                subtitle: "Try adjusting your search",
                actionTitle: nil,
                onAction: nil
            )
        } else {
            List(filteredExercises) { exercise in
                Button(action: {
                    onExerciseSelected(exercise)
                }) {
                    ExerciseListRowView(exercise: exercise, context: context)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - Exercise List Row View
struct ExerciseListRowView: View {
    let exercise: Exercise
    let context: ExerciseListContext
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(exercise.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron if selectable
            if context == .picker {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ExerciseListView(
        exercises: [],
        searchText: .constant(""),
        onExerciseSelected: { _ in },
        context: .browse
    )
}
