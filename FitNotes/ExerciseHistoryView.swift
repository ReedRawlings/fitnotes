import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let exercise: Exercise
    @State private var history: [ExerciseSessionSummary] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if history.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No History",
                        subtitle: "This exercise hasn't been performed yet",
                        actionTitle: nil,
                        onAction: nil
                    )
                } else {
                    List(history) { session in
                        HistoryRowView(session: session)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    private func loadHistory() {
        history = ExerciseService.shared.getExerciseHistory(
            exerciseId: exercise.id,
            modelContext: modelContext
        )
    }
}

struct HistoryRowView: View {
    let session: ExerciseSessionSummary
    
    var body: some View {
        HStack(spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(session.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sets summary
            Text(session.setsSummary)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ExerciseHistoryView(exercise: Exercise(
        name: "Bench Press",
        category: "Chest",
        type: "Strength"
    ))
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
}
