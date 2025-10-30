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
    // Optional multi-select mode: when provided, tapping toggles selection instead of immediate callback
    var selectedIds: Binding<Set<UUID>>? = nil
    
    private var filteredExercises: [Exercise] {
        ExerciseSearchService.shared.searchExercises(
            query: searchText,
            category: nil as String?,
            equipment: nil as String?,
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
                            if var binding = selectedIds {
                                if binding.wrappedValue.contains(exercise.id) {
                                    binding.wrappedValue.remove(exercise.id)
                                } else {
                                    binding.wrappedValue.insert(exercise.id)
                                }
                            } else {
                                onExerciseSelected(exercise)
                            }
                        }) {
                            ExerciseListRowView(
                                exercise: exercise,
                                context: context,
                                isSelected: selectedIds?.wrappedValue.contains(exercise.id) ?? false
                            )
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
    var isSelected: Bool = false
    
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
            
            // Trailing indicator: checkmark in picker mode (multi-select) or chevron in simple pick
            if context == .picker {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .accentPrimary : .textSecondary)
            }
        }
        .padding(.vertical, 10)
        .cardStyle()
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
