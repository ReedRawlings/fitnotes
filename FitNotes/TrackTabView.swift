import SwiftUI
import SwiftData

struct TrackTabView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    
    @State private var sets: [(id: UUID, weight: Double, reps: Int)] = []
    @State private var lastSessionSummary: String?
    @State private var showingSaveConfirmation = false
    @State private var isSaving = false
    @State private var showingPicker = false
    @State private var pickerType: WeightRepsPicker.PickerType = .weight
    @State private var editingSetIndex: Int = 0
    @State private var editingField: FieldType = .weight
    
    enum FieldType {
        case weight, reps
    }
    
    var body: some View {
        ZStack {
            // Dark background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Last Session Card
                        LastSessionCard(summary: lastSessionSummary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        
                        // Current Sets
                        if !sets.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                                    SetRowView(
                                        set: set,
                                        onWeightTap: {
                                            editingSetIndex = index
                                            editingField = .weight
                                            pickerType = .weight
                                            showingPicker = true
                                        },
                                        onRepsTap: {
                                            editingSetIndex = index
                                            editingField = .reps
                                            pickerType = .reps
                                            showingPicker = true
                                        },
                                        onDelete: {
                                            deleteSet(at: index)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                        }
                        
                        // Add Set Button
                        AddSetButton {
                            addSet()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Space for fixed save button
                    }
                }
                
                // Fixed Save Button
                SaveButton(
                    isEnabled: !sets.isEmpty,
                    isSaving: isSaving,
                    onSave: saveSets
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area + padding
                .background(Color.primaryBg) // Ensure background matches
            }
        }
        .onAppear {
            loadLastSession()
        }
        .overlay(
            showingPicker ? 
            WeightRepsPicker(
                pickerType: pickerType,
                currentValue: editingField == .weight ? sets[editingSetIndex].weight : Double(sets[editingSetIndex].reps),
                onValueChanged: { newValue in
                    if editingField == .weight {
                        sets[editingSetIndex].weight = newValue
                    } else {
                        sets[editingSetIndex].reps = Int(newValue)
                    }
                },
                onDismiss: {
                    showingPicker = false
                }
            ) : nil
        )
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
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.standardSpring) {
            sets.append((id: UUID(), weight: 0, reps: 0))
        }
    }
    
    private func deleteSet(at index: Int) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.deleteAnimation) {
            sets.remove(at: index)
        }
    }
    
    private func saveSets() {
        isSaving = true
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
            
            // Success haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            showingSaveConfirmation = true
        } else {
            // Error haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
        
        isSaving = false
    }
}

// MARK: - Last Session Card
struct LastSessionCard: View {
    let summary: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST SESSION")
                .font(.sectionHeader)
                .foregroundColor(.textSecondary)
                .kerning(0.5)
            
            if let summary = summary {
                Text(summary)
                    .font(.lastSessionData)
                    .foregroundColor(.textPrimary)
            } else {
                Text("No previous data")
                    .font(.bodyFont)
                    .foregroundColor(.textTertiary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Set Row View
struct SetRowView: View {
    let set: (id: UUID, weight: Double, reps: Int)
    let onWeightTap: () -> Void
    let onRepsTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Weight Column
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("WEIGHT")
                        .font(.sectionHeader)
                        .foregroundColor(.textTertiary)
                        .kerning(0.3)
                    
                    Text("kg")
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary.opacity(0.6))
                }
                
                Button(action: onWeightTap) {
                    Text(formatWeight(set.weight))
                        .font(.dataFont)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(10)
                }
                .accessibilityLabel("Weight, \(formatWeight(set.weight)) kilograms")
            }
            
            // Reps Column
            VStack(alignment: .leading, spacing: 8) {
                Text("REPS")
                    .font(.sectionHeader)
                    .foregroundColor(.textTertiary)
                    .kerning(0.3)
                
                Button(action: onRepsTap) {
                    Text("\(set.reps)")
                        .font(.dataFont)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(10)
                }
                .accessibilityLabel("Reps, \(set.reps)")
            }
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.errorRed)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Delete set")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.tertiaryBg)
        .cornerRadius(14)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        } else {
            return String(format: "%.1f", weight)
        }
    }
}

// MARK: - Add Set Button
struct AddSetButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16))
                
                Text("ADD SET")
                    .font(.buttonFont)
            }
            .foregroundColor(.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.accentPrimary, .accentSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: .accentPrimary.opacity(0.3),
                radius: 16,
                x: 0,
                y: 4
            )
        }
        .accessibilityLabel("Add new set")
        .scaleEffect(1.0)
        .animation(.buttonPress, value: false)
    }
}

// MARK: - Save Button
struct SaveButton: View {
    let isEnabled: Bool
    let isSaving: Bool
    let onSave: () -> Void
    
    var body: some View {
        Button(action: onSave) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .textInverse))
                        .scaleEffect(0.8)
                } else {
                    Text("SAVE WORKOUT")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isEnabled ? Color.accentSuccess : Color.disabledOverlay
            )
            .cornerRadius(16)
            .shadow(
                color: isEnabled ? .accentSuccess.opacity(0.4) : .clear,
                radius: 20,
                x: 0,
                y: 6
            )
        }
        .accessibilityLabel("Save workout")
        .disabled(!isEnabled || isSaving)
        .scaleEffect(1.0)
        .animation(.buttonPress, value: false)
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
