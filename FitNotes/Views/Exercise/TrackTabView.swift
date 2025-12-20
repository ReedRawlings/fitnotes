import SwiftUI
import SwiftData
import os.log

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
    @State private var focusedInput: InputFocus?

    private let logger = Logger(subsystem: "com.fitnotes.app", category: "TrackTabView")
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                    // Current Sets
                    if !sets.isEmpty {
                        // Header Row
                        SetHeaderRowView(exercise: exercise)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 6) {  // Reduced spacing between sets
                            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                                SetRowView(
                                    exercise: exercise,
                                    set: set,
                                    setIndex: index,
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
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
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
            .onAppear {
                logger.info("🔄 TrackTabView appeared - loading sets for exercise: \(exercise.name)")
                loadSets()
                logger.info("📋 Loaded \(sets.count) sets")
            }

            // Custom Keyboard Overlay
            if focusedInput != nil {
                let _ = logger.info("🎹 RENDERING KEYBOARD OVERLAY - focusedInput: \(String(describing: self.focusedInput))")
                ZStack {
                    // Tap-to-dismiss overlay
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            logger.info("Background tapped - dismissing keyboard")
                            focusedInput = nil
                        }

                    VStack {
                        Spacer()
                        CustomNumericKeyboard(
                            text: bindingForFocusedInput(),
                            increment: incrementForFocusedInput(),
                            onDismiss: {
                                logger.info("Keyboard dismiss requested from CustomNumericKeyboard")
                                focusedInput = nil
                            },
                            onFillDown: {
                                fillDownCurrentColumn()
                            }
                        )
                    }
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: focusedInput)
                .ignoresSafeArea(.keyboard)
            } else {
                let _ = logger.debug("🎹 Keyboard overlay NOT rendered - focusedInput is nil")
            }
        }
        .onChange(of: focusedInput) { oldValue, newValue in
            logger.info("⚡️ FocusedInput CHANGED - OLD: \(String(describing: oldValue)) -> NEW: \(String(describing: newValue))")
            if newValue != nil {
                logger.info("✅ Keyboard should now be VISIBLE - focusedInput is NOT nil")
            } else {
                logger.info("❌ Keyboard should now be HIDDEN - focusedInput is nil")
            }
            // Log the current state after the change
            DispatchQueue.main.async {
                self.logger.info("📊 State after focusedInput change: focusedInput = \(String(describing: self.focusedInput))")
            }
        }
    }

    // MARK: - Custom Keyboard Helpers

    private func bindingForFocusedInput() -> Binding<String> {
        guard let focusedInput = focusedInput else {
            logger.warning("bindingForFocusedInput called but focusedInput is nil")
            return .constant("")
        }

        logger.debug("Creating binding for focused input: \(String(describing: focusedInput))")

        switch focusedInput {
        case .weight(let id):
            if let index = sets.firstIndex(where: { $0.id == id }) {
                logger.debug("Found weight field at index \(index)")
                return Binding<String>(
                    get: {
                        if let weight = sets[index].weight {
                            let formatted = formatWeight(weight)
                            logger.debug("Weight binding GET: returning '\(formatted)' for weight \(weight)")
                            return formatted
                        }
                        logger.debug("Weight binding GET: returning empty string (no weight)")
                        return ""
                    },
                    set: { newValue in
                        logger.info("Weight binding SET: received '\(newValue)'")
                        let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                        if cleaned.isEmpty {
                            logger.debug("Weight set to nil (empty string)")
                            sets[index].weight = nil
                        } else if let val = Double(cleaned) {
                            logger.info("Weight set to \(val)")
                            sets[index].weight = val
                        } else {
                            logger.error("Failed to parse weight value: '\(newValue)'")
                        }
                        persistCurrentSets()
                    }
                )
            } else {
                logger.error("Could not find set with id \(id) for weight field")
            }
        case .reps(let id):
            if let index = sets.firstIndex(where: { $0.id == id }) {
                logger.debug("Found reps field at index \(index)")
                return Binding<String>(
                    get: {
                        let value = sets[index].reps.map(String.init) ?? ""
                        logger.debug("Reps binding GET: returning '\(value)'")
                        return value
                    },
                    set: { newValue in
                        logger.info("Reps binding SET: received '\(newValue)'")
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.isEmpty {
                            logger.debug("Reps set to nil (empty)")
                            sets[index].reps = nil
                        } else if let val = Int(filtered) {
                            logger.info("Reps set to \(val)")
                            sets[index].reps = val
                        } else {
                            logger.error("Failed to parse reps value: '\(newValue)'")
                        }
                        persistCurrentSets()
                    }
                )
            } else {
                logger.error("Could not find set with id \(id) for reps field")
            }
        case .rpe(let id):
            if let index = sets.firstIndex(where: { $0.id == id }) {
                logger.debug("Found RPE field at index \(index)")
                return Binding<String>(
                    get: {
                        let value = sets[index].rpe.map(String.init) ?? ""
                        logger.debug("RPE binding GET: returning '\(value)'")
                        return value
                    },
                    set: { newValue in
                        logger.info("RPE binding SET: received '\(newValue)'")
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.isEmpty {
                            logger.debug("RPE set to nil (empty)")
                            sets[index].rpe = nil
                        } else if let val = Int(filtered) {
                            let clamped = max(0, min(10, val))
                            logger.info("RPE set to \(clamped) (original: \(val))")
                            sets[index].rpe = clamped
                        } else {
                            logger.error("Failed to parse RPE value: '\(newValue)'")
                        }
                        persistCurrentSets()
                    }
                )
            } else {
                logger.error("Could not find set with id \(id) for RPE field")
            }
        case .rir(let id):
            if let index = sets.firstIndex(where: { $0.id == id }) {
                logger.debug("Found RIR field at index \(index)")
                return Binding<String>(
                    get: {
                        let value = sets[index].rir.map(String.init) ?? ""
                        logger.debug("RIR binding GET: returning '\(value)'")
                        return value
                    },
                    set: { newValue in
                        logger.info("RIR binding SET: received '\(newValue)'")
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.isEmpty {
                            logger.debug("RIR set to nil (empty)")
                            sets[index].rir = nil
                        } else if let val = Int(filtered) {
                            let clamped = max(0, min(10, val))
                            logger.info("RIR set to \(clamped) (original: \(val))")
                            sets[index].rir = clamped
                        } else {
                            logger.error("Failed to parse RIR value: '\(newValue)'")
                        }
                        persistCurrentSets()
                    }
                )
            } else {
                logger.error("Could not find set with id \(id) for RIR field")
            }
        }

        logger.error("bindingForFocusedInput: Falling through to default empty binding")
        return .constant("")
    }

    private func incrementForFocusedInput() -> Double {
        guard let focusedInput = focusedInput else {
            logger.warning("incrementForFocusedInput called but focusedInput is nil")
            return 1.0
        }

        let increment: Double
        switch focusedInput {
        case .weight:
            // Use exercise's custom increment for weight
            increment = exercise.incrementValue
            logger.debug("Increment for weight field: \(increment)")
        case .reps, .rpe, .rir:
            // Always use 1 for reps/RPE/RIR
            increment = 1.0
            logger.debug("Increment for reps/RPE/RIR field: 1.0")
        }
        return increment
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        } else {
            return String(format: "%.1f", weight)
        }
    }
    
    private func fillDownCurrentColumn() {
        guard let focusedInput = focusedInput else {
            logger.warning("fillDownCurrentColumn called but focusedInput is nil")
            return
        }
        
        // Get current set index
        let currentSetId: UUID
        switch focusedInput {
        case .weight(let id), .reps(let id), .rpe(let id), .rir(let id):
            currentSetId = id
        }
        
        guard let currentIndex = sets.firstIndex(where: { $0.id == currentSetId }) else {
            logger.error("Could not find current set index for fill down")
            return
        }
        
        // Get current value from text binding
        let currentText = bindingForFocusedInput().wrappedValue
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Fill down based on column type
        switch focusedInput {
        case .weight(let id):
            // Parse current weight value
            let cleaned = currentText.replacingOccurrences(of: ",", with: ".")
            guard let currentValue = Double(cleaned) else {
                logger.warning("Could not parse weight value for fill down: '\(currentText)'")
                return
            }
            
            // Fill all sets below current index
            for index in (currentIndex + 1)..<sets.count {
                sets[index].weight = currentValue
            }
            logger.info("Filled down weight value \(currentValue) from row \(currentIndex) to rows \(currentIndex + 1)..<\(sets.count)")
            
        case .reps(let id):
            // Parse current reps value
            let filtered = currentText.filter { $0.isNumber }
            guard let currentValue = Int(filtered) else {
                logger.warning("Could not parse reps value for fill down: '\(currentText)'")
                return
            }
            
            // Fill all sets below current index
            for index in (currentIndex + 1)..<sets.count {
                sets[index].reps = currentValue
            }
            logger.info("Filled down reps value \(currentValue) from row \(currentIndex) to rows \(currentIndex + 1)..<\(sets.count)")
            
        case .rpe(let id):
            // Parse current RPE value
            let filtered = currentText.filter { $0.isNumber }
            guard let currentValue = Int(filtered) else {
                logger.warning("Could not parse RPE value for fill down: '\(currentText)'")
                return
            }
            let clampedValue = max(0, min(10, currentValue))
            
            // Fill all sets below current index
            for index in (currentIndex + 1)..<sets.count {
                sets[index].rpe = clampedValue
            }
            logger.info("Filled down RPE value \(clampedValue) from row \(currentIndex) to rows \(currentIndex + 1)..<\(sets.count)")
            
        case .rir(let id):
            // Parse current RIR value
            let filtered = currentText.filter { $0.isNumber }
            guard let currentValue = Int(filtered) else {
                logger.warning("Could not parse RIR value for fill down: '\(currentText)'")
                return
            }
            let clampedValue = max(0, min(10, currentValue))
            
            // Fill all sets below current index
            for index in (currentIndex + 1)..<sets.count {
                sets[index].rir = clampedValue
            }
            logger.info("Filled down RIR value \(clampedValue) from row \(currentIndex) to rows \(currentIndex + 1)..<\(sets.count)")
        }
        
        // Persist changes
        persistCurrentSets()
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
            unit: exercise.unit,
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
            unit: exercise.unit,
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


// MARK: - Set Header Row View
struct SetHeaderRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 20) {
            // Weight Column Header
            HStack(spacing: 4) {
                Text("WEIGHT")
                    .font(.sectionHeader)
                    .foregroundColor(.textTertiary)
                    .kerning(0.3)

                Text(exercise.unit)
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            
            // Reps Column Header
            Text("REPS")
                .font(.sectionHeader)
                .foregroundColor(.textTertiary)
                .kerning(0.3)
                .frame(maxWidth: .infinity)
            
            // RPE/RIR Column Header (conditional)
            if exercise.rpeEnabled || exercise.rirEnabled {
                Text(exercise.rpeEnabled ? "RPE" : "RIR")
                    .font(.sectionHeader)
                    .foregroundColor(.textTertiary)
                    .kerning(0.3)
                    .frame(maxWidth: .infinity)
            }
            
            // Spacer for checkbox column
            Spacer()
                .frame(width: 44) // Match checkbox width
        }
    }
}

// MARK: - Set Row View
struct SetRowView: View {
    let exercise: Exercise
    let set: (id: UUID, weight: Double?, reps: Int?, rpe: Int?, rir: Int?, isChecked: Bool)
    let setIndex: Int
    @Binding var weight: Double?
    @Binding var reps: Int?
    @Binding var rpe: Int?
    @Binding var rir: Int?
    @Binding var focusedInput: TrackTabView.InputFocus?
    let onToggleCheck: () -> Void
    let onDelete: () -> Void

    private let logger = Logger(subsystem: "com.fitnotes.app", category: "SetRowView")

    private var isWarmupSet: Bool {
        exercise.useWarmupSet && setIndex == 0
    }

    var body: some View {
        HStack(spacing: 20) {
            // Warm up badge for first set
            if isWarmupSet {
                Text("W")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textTertiary)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    )
                    .padding(.trailing, -12)
            }

            // Weight Column
            NumericInputField(
                text: Binding<String>(
                    get: { formatWeight(weight) },
                    set: { _ in } // No-op: editing happens through keyboard binding
                ),
                placeholder: "0",
                isActive: focusedInput == TrackTabView.InputFocus.weight(set.id),
                onTap: {
                    logger.info("👆 WEIGHT FIELD TAPPED - Set ID: \(set.id)")
                    logger.info("   Current focusedInput BEFORE tap: \(String(describing: focusedInput))")
                    logger.info("   Setting focusedInput to: weight(\(set.id))")
                    focusedInput = TrackTabView.InputFocus.weight(set.id)
                    logger.info("   focusedInput AFTER assignment: \(String(describing: focusedInput))")
                }
            )
            .accessibilityLabel("Weight input")
            .accessibilityHint("Double tap to enter weight")
            
            // Reps Column
            NumericInputField(
                text: Binding<String>(
                    get: { reps.map(String.init) ?? "" },
                    set: { _ in } // No-op: editing happens through keyboard binding
                ),
                placeholder: "0",
                isActive: focusedInput == TrackTabView.InputFocus.reps(set.id),
                onTap: {
                    logger.info("👆 REPS FIELD TAPPED - Set ID: \(set.id)")
                    logger.info("   Current focusedInput BEFORE tap: \(String(describing: focusedInput))")
                    logger.info("   Setting focusedInput to: reps(\(set.id))")
                    focusedInput = TrackTabView.InputFocus.reps(set.id)
                    logger.info("   focusedInput AFTER assignment: \(String(describing: focusedInput))")
                }
            )
            .accessibilityLabel("Reps input")
            .accessibilityHint("Double tap to enter reps")
            
            // RPE/RIR Column (conditional)
            if exercise.rpeEnabled || exercise.rirEnabled {
                NumericInputField(
                    text: Binding<String>(
                        get: { exercise.rpeEnabled ? (rpe.map(String.init) ?? "") : (rir.map(String.init) ?? "") },
                        set: { _ in } // No-op: editing happens through keyboard binding
                    ),
                    placeholder: "0",
                    isActive: focusedInput == (exercise.rpeEnabled ? TrackTabView.InputFocus.rpe(set.id) : TrackTabView.InputFocus.rir(set.id)),
                    onTap: {
                        let fieldType = exercise.rpeEnabled ? "RPE" : "RIR"
                        logger.info("👆 \(fieldType) FIELD TAPPED - Set ID: \(set.id)")
                        logger.info("   Current focusedInput BEFORE tap: \(String(describing: focusedInput))")
                        let newFocus = exercise.rpeEnabled ? TrackTabView.InputFocus.rpe(set.id) : TrackTabView.InputFocus.rir(set.id)
                        logger.info("   Setting focusedInput to: \(String(describing: newFocus))")
                        focusedInput = newFocus
                        logger.info("   focusedInput AFTER assignment: \(String(describing: focusedInput))")
                    }
                )
                .accessibilityLabel(exercise.rpeEnabled ? "RPE input" : "RIR input")
                .accessibilityHint("Double tap to enter \(exercise.rpeEnabled ? "RPE" : "RIR")")
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
        .onAppear {
            logger.debug("SetRowView appeared for set \(set.id)")
        }
        .onChange(of: focusedInput) { oldValue, newValue in
            logger.debug("SetRowView (\(set.id)) detected focusedInput change: \(String(describing: oldValue)) -> \(String(describing: newValue))")
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
