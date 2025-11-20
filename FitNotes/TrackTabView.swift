import SwiftUI
import SwiftData

struct TrackTabView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    var workout: Workout?
    var workoutExercise: WorkoutExercise?
    var onSaveSuccess: (() -> Void)? = nil
    
    @State private var sets: [(id: UUID, weight: Double?, reps: Int?, rpe: Int?, rir: Int?, isChecked: Bool)] = []
    @State private var isSaving = false
    @State private var isSaved = false
    
    enum InputFocus: Hashable {
        case weight(UUID)
        case reps(UUID)
        case rpe(UUID)
        case rir(UUID)
    }
    @FocusState private var focusedInput: InputFocus?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Current Sets
                    if !sets.isEmpty {
                        VStack(spacing: 10) {  // Reduced from 12
                            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                                SetRowView(
                                    exercise: exercise,
                                    set: set,
                                    weight: Binding<Double?>(
                                        get: { sets[index].weight },
                                        set: { newVal in
                                            sets[index].weight = newVal
                                            persistCurrentSets()
                                        }
                                    ),
                                    reps: Binding<Int?>(
                                        get: { sets[index].reps },
                                        set: { newVal in
                                            sets[index].reps = newVal
                                            persistCurrentSets()
                                        }
                                    ),
                                    rpe: Binding<Int?>(
                                        get: { sets[index].rpe },
                                        set: { newVal in
                                            sets[index].rpe = newVal
                                            persistCurrentSets()
                                        }
                                    ),
                                    rir: Binding<Int?>(
                                        get: { sets[index].rir },
                                        set: { newVal in
                                            sets[index].rir = newVal
                                            persistCurrentSets()
                                        }
                                    ),
                                    focusedInput: $focusedInput,
                                    onToggleCheck: {
                                        sets[index].isChecked.toggle()
                                        persistCurrentSets()

                                        // Always trigger rest timer when checking a set (cancel any existing timer)
                                        if sets[index].isChecked {
                                            triggerRestTimer(forSet: index + 1)
                                        }

                                        handleSetCompletion()
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

                    // Spacer to allow tapping blank space below content
                    Spacer()
                        .frame(minHeight: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping blank space
                    focusedInput = nil
                }
            }
            .scrollDismissesKeyboard(.immediately)

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
        .onAppear {
            loadSets()
        }
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
                (id: s.id, weight: s.weight, reps: s.reps, rpe: s.rpe, rir: s.rir, isChecked: s.isCompleted)
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
                (id: UUID(), weight: set.weight, reps: set.reps, rpe: nil, rir: nil, isChecked: false)
            }
        } else {
            // No history, start with one empty set
            sets = [(id: UUID(), weight: nil, reps: nil, rpe: nil, rir: nil, isChecked: false)]
        }
    }
    
    private func addSet() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Get weight and reps from the last displayed set, or from history if no sets are displayed
        let previousWeight: Double?
        let previousReps: Int?
        
        if let lastSet = sets.last {
            // Use the last displayed set
            previousWeight = lastSet.weight
            previousReps = lastSet.reps
        } else {
            // Fall back to last session history
            let lastSession = ExerciseService.shared.getLastSessionForExercise(
                exerciseId: exercise.id,
                modelContext: modelContext
            )
            if let lastSessionSet = lastSession?.last {
                previousWeight = lastSessionSet.weight
                previousReps = lastSessionSet.reps
            } else {
                previousWeight = nil
                previousReps = nil
            }
        }
        
        sets.append((id: UUID(), weight: previousWeight, reps: previousReps, rpe: nil, rir: nil, isChecked: false))
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
        let setData = sets.map { (weight: $0.weight, reps: $0.reps, rpe: $0.rpe, rir: $0.rir, isCompleted: $0.isChecked) }
        
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
        let setData = sets.map { (weight: $0.weight, reps: $0.reps, rpe: $0.rpe, rir: $0.rir, isCompleted: $0.isChecked) }
        _ = ExerciseService.shared.saveSets(
            exerciseId: exercise.id,
            date: today,
            sets: setData,
            modelContext: modelContext
        )
    }

    private func handleSetCompletion() {
        guard let workout = workout, let currentExercise = workoutExercise else { return }

        let allSetsCompleted = sets.allSatisfy { $0.isChecked }
        if !allSetsCompleted {
            return
        }

        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }

        guard let currentIndex = sortedExercises.firstIndex(where: { $0.id == currentExercise.id }) else {
            return
        }

        let nextWorkoutExercise = sortedExercises
            .suffix(from: currentIndex + 1)
            .first { nextExercise in
                let sets = ExerciseService.shared.getSetsByDate(
                    exerciseId: nextExercise.exerciseId,
                    date: workout.date,
                    modelContext: modelContext
                )
                return sets.isEmpty || !sets.allSatisfy { $0.isCompleted }
            }

        if let nextWorkoutExercise = nextWorkoutExercise {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let allExercises: [Exercise]
                do {
                    allExercises = try modelContext.fetch(FetchDescriptor<Exercise>())
                } catch {
                    allExercises = []
                }
                if let nextExercise = allExercises.first(where: { $0.id == nextWorkoutExercise.exerciseId }) {
                    appState.selectedExercise = nextExercise
                }
            }
        } else {
            // No more exercises, workout is finished
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.selectedExercise = nil // Dismiss the sheet
                appState.showWorkoutFinishedBanner = true
                appState.selectedTab = 2 // Switch to workout tab
            }
        }
    }
    
    private func triggerRestTimer(forSet setNumber: Int) {
        // Check if rest timer is enabled for this exercise
        guard exercise.useRestTimer else { return }

        // Determine rest duration
        let restSeconds: Int
        if exercise.useAdvancedRest {
            // Advanced mode: check custom rest time for this set, or use default
            if let customSeconds = exercise.customRestSeconds[setNumber] {
                restSeconds = customSeconds
            } else {
                restSeconds = exercise.defaultRestSeconds
            }
        } else {
            // Standard mode: use default for all sets
            restSeconds = exercise.defaultRestSeconds
        }

        // Start the timer
        appState.startRestTimer(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            setNumber: setNumber,
            duration: TimeInterval(restSeconds)
        )

        // Medium haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}


// MARK: - Set Row View
struct SetRowView: View {
    let exercise: Exercise
    let set: (id: UUID, weight: Double?, reps: Int?, rpe: Int?, rir: Int?, isChecked: Bool)
    @Binding var weight: Double?
    @Binding var reps: Int?
    @Binding var rpe: Int?
    @Binding var rir: Int?
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
                            if cleaned.isEmpty {
                                weight = nil
                            } else if let val = Double(cleaned) {
                                weight = val
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
                        get: { reps.map(String.init) ?? "" },
                        set: { newText in
                            let filtered = newText.filter { $0.isNumber }
                            if filtered.isEmpty {
                                reps = nil
                            } else if let val = Int(filtered) {
                                reps = val
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
            }
            
            // RPE/RIR Column (conditional)
            if exercise.rpeEnabled || exercise.rirEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.rpeEnabled ? "RPE" : "RIR")
                        .font(.sectionHeader)
                        .foregroundColor(.textTertiary)
                        .kerning(0.3)
                    
                    TextField(
                        "0",
                        text: Binding<String>(
                            get: {
                                if exercise.rpeEnabled { return rpe.map(String.init) ?? "" }
                                else { return rir.map(String.init) ?? "" }
                            },
                            set: { newText in
                                let filtered = newText.filter { $0.isNumber }
                                if filtered.isEmpty {
                                    if exercise.rpeEnabled { rpe = nil } else { rir = nil }
                                } else if let val = Int(filtered) {
                                    let clamped = max(0, min(10, val))
                                    if exercise.rpeEnabled { rpe = clamped } else { rir = clamped }
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
                    .focused(
                        focusedInput,
                        equals: exercise.rpeEnabled ? TrackTabView.InputFocus.rpe(set.id) : TrackTabView.InputFocus.rir(set.id)
                    )
                    .accessibilityLabel(exercise.rpeEnabled ? "RPE input" : "RIR input")
                }
            }
            
            // Checkbox Button
            Button(action: onToggleCheck) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(set.isChecked ? Color.accentSuccess : Color.white.opacity(0.06))
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(set.isChecked ? Color.clear : Color.white.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(
                            color: set.isChecked ? Color.accentSuccess.opacity(0.35) : .clear,
                            radius: 6,
                            x: 0,
                            y: 2
                        )
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(set.isChecked ? 1 : 0)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
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
    
    private func formatWeight(_ weight: Double?) -> String {
        guard let weight = weight else { return "" }
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
    .environmentObject(AppState())
}
