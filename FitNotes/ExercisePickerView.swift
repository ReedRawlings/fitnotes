import SwiftUI
import SwiftData

// MARK: - Exercise Picker Display Mode
enum ExercisePickerDisplayMode {
    case compact    // Minimal: name, category tag, equipment (for "Add to routine/workout")
    case detailed   // Full: icon, category badge, difficulty badge, equipment (for Settings)
}

// MARK: - Exercise Picker View
struct ExercisePickerView: View {
    let exercises: [Exercise]
    let displayMode: ExercisePickerDisplayMode
    let onExerciseSelected: (Exercise) -> Void
    
    var body: some View {
        if exercises.isEmpty {
            EmptyStateView(
                icon: "dumbbell",
                title: "No exercises found",
                subtitle: "Try adjusting your search or filter",
                actionTitle: nil,
                onAction: nil
            )
        } else {
            List(exercises) { exercise in
                Button(action: {
                    onExerciseSelected(exercise)
                }) {
                    ExercisePickerRowView(exercise: exercise, displayMode: displayMode)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - Exercise Picker Row View
struct ExercisePickerRowView: View {
    let exercise: Exercise
    let displayMode: ExercisePickerDisplayMode
    
    var body: some View {
        HStack(spacing: 12) {
            if displayMode == .detailed {
                // Exercise Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: exerciseIcon(for: exercise.category))
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(exercise.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                    
                    if !exercise.equipment.isEmpty {
                        Text(exercise.equipment)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if displayMode == .detailed {
                        Text(exercise.difficulty)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor(exercise.difficulty).opacity(0.2))
                            .foregroundColor(difficultyColor(exercise.difficulty))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func exerciseIcon(for category: String) -> String {
        switch category.lowercased() {
        case "chest": return "heart"
        case "back": return "figure.strengthtraining.traditional"
        case "shoulders": return "figure.arms.open"
        case "arms": return "figure.arms.open"
        case "legs": return "figure.walk"
        case "core": return "circle.grid.cross"
        case "glutes": return "figure.strengthtraining.functional"
        case "cardio": return "heart.fill"
        default: return "dumbbell"
        }
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

// MARK: - Exercise Search Service
public final class ExerciseSearchService {
    public static let shared = ExerciseSearchService()
    private init() {}
    
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
        
        // Filter by query text (case-insensitive search in name)
        if !query.isEmpty {
            filteredExercises = filteredExercises.filter { 
                $0.name.localizedCaseInsensitiveContains(query) 
            }
        }
        
        // Sort results alphabetically
        return filteredExercises.sorted { $0.name < $1.name }
    }
}

#Preview {
    ExercisePickerView(
        exercises: [],
        displayMode: .detailed,
        onExerciseSelected: { _ in }
    )
}
