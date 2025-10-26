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
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredExercises) { exercise in
                        Button(action: {
                            onExerciseSelected(exercise)
                        }) {
                            ExerciseListRowView(exercise: exercise, context: context)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
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
                    .foregroundColor(.textPrimary)
                
                Text(exercise.category)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Chevron if selectable
            if context == .picker {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 10)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
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
