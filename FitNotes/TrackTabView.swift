import SwiftUI
import SwiftData

struct TrackTabView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    
    @State private var sets: [(id: UUID, weight: Double, reps: Int)] = []
    @State private var lastSessionSummary: String?
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Last Session Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Session")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let summary = lastSessionSummary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("No history yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                // Add Set Button (Top)
                Button(action: addSet) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Set")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                // Sets List
                if !sets.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                            SetRowView(
                                set: set,
                                onWeightChange: { newWeight in
                                    sets[index].weight = newWeight
                                },
                                onRepsChange: { newReps in
                                    sets[index].reps = newReps
                                },
                                onDelete: {
                                    deleteSet(at: index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Add Set Button (Bottom)
                if !sets.isEmpty {
                    Button(action: addSet) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Set")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Save Button
                if !sets.isEmpty {
                    Button(action: saveSets) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            loadLastSession()
        }
        .alert("Sets Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your sets have been saved successfully.")
        }
    }
    
    private func loadLastSession() {
        let lastSession = ExerciseService.shared.getLastSessionForExercise(
            exerciseId: exercise.id,
            modelContext: modelContext
        )
        
        if let lastSession = lastSession, !lastSession.isEmpty {
            // Create summary string
            let weight = lastSession.first?.weight ?? 0
            let reps = lastSession.map { "\($0.reps)" }.joined(separator: "/")
            lastSessionSummary = "\(Int(weight))kg × \(reps)"
            
            // Pre-populate with last session data
            sets = lastSession.map { set in
                (id: set.id, weight: set.weight, reps: set.reps)
            }
        } else {
            // No history, start with one empty set
            sets = [(id: UUID(), weight: 0, reps: 0)]
            lastSessionSummary = nil
        }
    }
    
    private func addSet() {
        sets.append((id: UUID(), weight: 0, reps: 0))
    }
    
    private func deleteSet(at index: Int) {
        sets.remove(at: index)
    }
    
    private func saveSets() {
        let today = Date()
        let setData = sets.map { (weight: $0.weight, reps: $0.reps) }
        
        let success = ExerciseService.shared.saveSets(
            exerciseId: exercise.id,
            date: today,
            sets: setData,
            modelContext: modelContext
        )
        
        if success {
            // Also ensure we have a workout for today
            _ = WorkoutService.shared.getOrCreateWorkoutForDate(
                date: today,
                modelContext: modelContext
            )
            
            showingSaveConfirmation = true
        }
    }
}

struct SetRowView: View {
    let set: (id: UUID, weight: Double, reps: Int)
    let onWeightChange: (Double) -> Void
    let onRepsChange: (Int) -> Void
    let onDelete: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Weight Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    
                    Text("kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Reps Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            weightText = set.weight > 0 ? String(format: "%.1f", set.weight) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
        .onChange(of: weightText) { _, newValue in
            if let weight = Double(newValue) {
                onWeightChange(weight)
            }
        }
        .onChange(of: repsText) { _, newValue in
            if let reps = Int(newValue) {
                onRepsChange(reps)
            }
        }
    }
}

#Preview {
    TrackTabView(exercise: Exercise(
        name: "Bench Press",
        category: "Chest",
        type: "Strength"
    ))
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
}
