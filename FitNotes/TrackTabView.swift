import SwiftUI
import SwiftData

struct TrackTabView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    var onSaveSuccess: (() -> Void)? = nil
    
    @State private var sets: [(id: UUID, weight: Double, reps: Int, isChecked: Bool)] = []
    @State private var isSaving = false
    @State private var isSaved = false
    // Inline numeric inputs replaced the old wheel picker
    
    enum InputFocus: Hashable {
        case weight(UUID)
        case reps(UUID)
    }
    @FocusState private var focusedInput: InputFocus?
    
    var body: some View {
        ZStack {
            // Dark background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Current Sets
                        if !sets.isEmpty {
                            VStack(spacing: 10) {  // Reduced from 12
                                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                                    SetRowView(
                                        set: set,
                                        weight: Binding<Double>(
                                            get: { sets[index].weight },
                                            set: { newVal in
                                                sets[index].weight = newVal
                                                persistCurrentSets()
                                            }
                                        ),
                                        reps: Binding<Int>(
                                            get: { sets[index].reps },
                                            set: { newVal in
                                                sets[index].reps = newVal
                                                persistCurrentSets()
                                            }
                                        ),
                                        focusedInput: $focusedInput,
                                        onToggleCheck: {
                                            sets[index].isChecked.toggle()
                                            persistCurrentSets()
                                        },
                                        onDelete: {
                                            deleteSet(at: index)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)  // Reduced from 28
                        }
                        
                        // Add Set Button
                        AddSetButton {
                            addSet()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)  // Reduced from 28
                        .padding(.bottom, 100) // Space for fixed save button
                    }
                }
                
                // Fixed Save Button
                SaveButton(
                    isEnabled: !sets.isEmpty,
                    isSaving: isSaving,
                    isSaved: isSaved,
                    onSave: saveSets
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area + padding
                .background(Color.primaryBg) // Ensure background matches
            }
        }
        .onAppear {
            loadSets()
        }
        // Overlay removed; using inline numeric inputs
    }
    
    private func loadSets() {
        // Prefer today's persisted sets; if none, prefill from last session
        let todaysSets = ExerciseService.shared.getSetsByDate(
            exerciseId: exercise.id,
            date: Date(),
            modelContext: modelContext
        )
        if !todaysSets.isEmpty {
            sets = todaysSets.sorted { $0.order < $1.order }.map { s in
                (id: s.id, weight: s.weight, reps: s.reps, isChecked: s.isCompleted)
            }
            return
        }
        
        let lastSession = ExerciseService.shared.getLastSessionForExercise(
            exerciseId: exercise.id,
            modelContext: modelContext
        )
        
        if let lastSession = lastSession, !lastSession.isEmpty {
            // Pre-populate with last session data
            sets = lastSession.map { set in
                (id: set.id, weight: set.weight, reps: set.reps, isChecked: false)
            }
        } else {
            // No history, start with one empty set
            sets = [(id: UUID(), weight: 0, reps: 0, isChecked: false)]
        }
    }
    
    private func addSet() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let previousWeight = sets.last?.weight ?? 0
        sets.append((id: UUID(), weight: previousWeight, reps: 0, isChecked: false))
        persistCurrentSets()
    }
    
    private func deleteSet(at index: Int) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        sets.remove(at: index)
        persistCurrentSets()
    }
    
    private func saveSets() {
        isSaving = true
        let today = Date()
        let setData = sets.map { (weight: $0.weight, reps: $0.reps, isCompleted: $0.isChecked) }
        
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
            
            // Immediately show saved state without delay
            isSaving = false
            isSaved = true
            
            // Call onSaveSuccess callback if provided (e.g., when opening from workout tab)
            if let onSaveSuccess = onSaveSuccess {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onSaveSuccess()
                }
            } else {
                // Reset after animation when no callback
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isSaved = false
                }
            }
        } else {
            // Error haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            isSaving = false
        }
    }
    
    private func persistCurrentSets() {
        let today = Date()
        let setData = sets.map { (weight: $0.weight, reps: $0.reps, isCompleted: $0.isChecked) }
        _ = ExerciseService.shared.saveSets(
            exerciseId: exercise.id,
            date: today,
            sets: setData,
            modelContext: modelContext
        )
    }
}


// MARK: - Set Row View
struct SetRowView: View {
    let set: (id: UUID, weight: Double, reps: Int, isChecked: Bool)
    @Binding var weight: Double
    @Binding var reps: Int
    var focusedInput: FocusState<TrackTabView.InputFocus?>.Binding
    let onToggleCheck: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Weight Column
            VStack(alignment: .leading, spacing: 4) {  // Reduced from 8
                HStack(spacing: 4) {
                    Text("WEIGHT")
                        .font(.sectionHeader)
                        .foregroundColor(.textTertiary)
                        .kerning(0.3)
                    
                    Text("kg")
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary.opacity(0.6))
                }
                
                TextField(
                    "0",
                    text: Binding<String>(
                        get: { formatWeight(weight) },
                        set: { newText in
                            let cleaned = newText.replacingOccurrences(of: ",", with: ".")
                            if let val = Double(cleaned) {
                                weight = val
                            } else if cleaned.isEmpty {
                                weight = 0
                            }
                        }
                    )
                )
                .keyboardType(.decimalPad)
                .submitLabel(.done)
                .font(.dataFont)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .focused(focusedInput, equals: TrackTabView.InputFocus.weight(set.id))
                .accessibilityLabel("Weight input")
                .contentShape(Rectangle())
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusedInput.wrappedValue = nil }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedInput.wrappedValue = TrackTabView.InputFocus.weight(set.id)
            }
            
            // Reps Column
            VStack(alignment: .leading, spacing: 4) {  // Reduced from 8
                Text("REPS")
                    .font(.sectionHeader)
                    .foregroundColor(.textTertiary)
                    .kerning(0.3)
                
                TextField(
                    "0",
                    text: Binding<String>(
                        get: { String(reps) },
                        set: { newText in
                            let filtered = newText.filter { $0.isNumber }
                            if let val = Int(filtered) {
                                reps = val
                            } else if filtered.isEmpty {
                                reps = 0
                            }
                        }
                    )
                )
                .keyboardType(.numberPad)
                .submitLabel(.done)
                .font(.dataFont)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .focused(focusedInput, equals: TrackTabView.InputFocus.reps(set.id))
                .accessibilityLabel("Reps input")
                .contentShape(Rectangle())
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusedInput.wrappedValue = nil }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedInput.wrappedValue = TrackTabView.InputFocus.reps(set.id)
            }
            
            // Checkbox Button
            Button(action: onToggleCheck) {
                ZStack {
                    Circle()
                        .fill(set.isChecked ? Color.accentSuccess : Color.white.opacity(0.06))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(set.isChecked ? Color.clear : Color.white.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(
                            color: set.isChecked ? Color.accentSuccess.opacity(0.35) : .clear,
                            radius: 10,
                            x: 0,
                            y: 4
                        )
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(set.isChecked ? 1 : 0)
                }
                .frame(width: 56, height: 56)
                .contentShape(Circle())
                .animation(.easeInOut(duration: 0.15), value: set.isChecked)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(set.isChecked ? "Uncheck set" : "Check set")
            .accessibilityHint("Marks this set as complete")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 0)  // Removed vertical padding
        .onLongPressGesture(minimumDuration: 0.5) {
            onDelete()
        }
        // Removed background and corner radius
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
    let isSaved: Bool
    let onSave: () -> Void
    
    var body: some View {
        Button(action: onSave) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .textInverse))
                        .scaleEffect(0.8)
                } else {
                    Text(isSaved ? "WORKOUT SAVED" : "SAVE WORKOUT")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(isSaved ? .accentSuccess : .textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isSaved ? Color.white : (isEnabled ? Color.accentSuccess : Color.disabledOverlay)
            )
            .cornerRadius(16)
            .shadow(
                color: isSaved ? .clear : (isEnabled ? .accentSuccess.opacity(0.4) : .clear),
                radius: 20,
                x: 0,
                y: 6
            )
        }
        .accessibilityLabel("Save workout")
        .disabled(!isEnabled || isSaving || isSaved)
        .scaleEffect(1.0)
        .animation(.buttonPress, value: isSaved)
    }
}

#Preview {
    TrackTabView(exercise: Exercise(
        name: "Bench Press",
        primaryCategory: "Chest",
        secondaryCategories: ["Triceps", "Shoulders"],
        equipment: "Machine"
    ))
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
}
