import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 16) {
                    // Exercise Name
                    Text(exercise.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Category Badge
                    HStack(spacing: 12) {
                        Text(exercise.category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .cornerRadius(20)
                        
                        Text(exercise.type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Tab Navigation
                Picker("Tab", selection: $selectedTab) {
                    Text("Track").tag(0)
                    Text("History").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Tab Content
                if selectedTab == 0 {
                    TrackTabView(exercise: exercise)
                } else {
                    HistoryTabView(exercise: exercise)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ExerciseDetailView(exercise: Exercise(
        name: "Bench Press",
        category: "Chest",
        type: "Strength"
    ))
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
}
