import SwiftUI
import SwiftData

struct TrackTabView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    var onSaveSuccess: (() -> Void)? = nil
    
    @State private var sets: [(id: UUID, weight: Double, reps: Int, isChecked: Bool)] = []
    @State private var isSaving = false
    @State private var isSaved = false
    @State private var restTimerRemaining = 0
    @State private var restTimerTotal = 0
    @State private var isRestTimerVisible = false
    @State private var isRestTimerPaused = false
    @State private var restTimer: Timer?
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
                        if !isRestTimerVisible {
                            RestTimerControlCard(
                                duration: exercise.restTimerDuration,
                                autoStartEnabled: exercise.autoStartRestTimer,
                                onStart: { startRestTimer(isManualTrigger: true) }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                        } else {
                            Color.clear
                                .frame(height: 16)
                        }
                        
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
                                            if sets[index].isChecked, exercise.autoStartRestTimer {
                                                startRestTimer(isManualTrigger: false)
                                            }
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
                
                if isRestTimerVisible {
                    RestTimerBanner(
                        remainingSeconds: restTimerRemaining,
                        totalSeconds: restTimerTotal,
                        isPaused: isRestTimerPaused,
                        onTogglePause: toggleRestTimerPause,
                        onRestart: restartRestTimer,
                        onSkip: {
                            stopRestTimer(triggerFeedback: true)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .onDisappear {
            stopRestTimer(triggerFeedback: false)
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
        
        sets.append((id: UUID(), weight: 0, reps: 0, isChecked: false))
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
    
    private func startRestTimer(isManualTrigger: Bool) {
        let duration = exercise.restTimerDuration
        guard duration > 0 else {
            if isManualTrigger {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
            return
        }
        let feedbackStyle: UIImpactFeedbackGenerator.Style = isManualTrigger ? .light : .medium
        beginRestTimer(duration: duration, feedbackStyle: feedbackStyle)
    }
    
    private func beginRestTimer(duration: Int, feedbackStyle: UIImpactFeedbackGenerator.Style = .medium) {
        restTimer?.invalidate()
        restTimerRemaining = duration
        restTimerTotal = duration
        isRestTimerPaused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isRestTimerVisible = true
        }
        let impactFeedback = UIImpactFeedbackGenerator(style: feedbackStyle)
        impactFeedback.impactOccurred()
        let timer = Timer(timeInterval: 1, repeats: true) { _ in
            guard !isRestTimerPaused else { return }
            if restTimerRemaining > 0 {
                restTimerRemaining -= 1
                if restTimerRemaining <= 0 {
                    finalizeRestTimer()
                }
            } else {
                finalizeRestTimer()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        restTimer = timer
    }
    
    private func toggleRestTimerPause() {
        guard isRestTimerVisible, restTimer != nil else { return }
        isRestTimerPaused.toggle()
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func restartRestTimer() {
        guard restTimerTotal > 0 else {
            startRestTimer(isManualTrigger: true)
            return
        }
        beginRestTimer(duration: restTimerTotal, feedbackStyle: .medium)
    }
    
    private func stopRestTimer(triggerFeedback: Bool) {
        if triggerFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        restTimer?.invalidate()
        restTimer = nil
        restTimerRemaining = 0
        restTimerTotal = 0
        isRestTimerPaused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isRestTimerVisible = false
        }
    }
    
    private func finalizeRestTimer() {
        guard restTimer != nil else { return }
        restTimer?.invalidate()
        restTimer = nil
        restTimerRemaining = 0
        isRestTimerPaused = false
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isRestTimerVisible = false
            }
            restTimerTotal = 0
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
        HStack(spacing: 16) {
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
                Image(systemName: set.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(set.isChecked ? .accentSuccess : .textSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(set.isChecked ? "Uncheck set" : "Check set")
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

// MARK: - Rest Timer Control Card
struct RestTimerControlCard: View {
    let duration: Int
    let autoStartEnabled: Bool
    let onStart: () -> Void
    
    private var isStartDisabled: Bool { duration <= 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("REST TIMER")
                        .font(.sectionHeader)
                        .foregroundColor(.textTertiary)
                        .kerning(0.3)
                    Text(formattedDuration(duration))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.textPrimary)
                    Text("Default rest for this exercise")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Button(action: onStart) {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isStartDisabled ? .textSecondary : .textInverse)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(
                            isStartDisabled ? Color.disabledOverlay : LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                }
                .disabled(isStartDisabled)
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack(spacing: 10) {
                Image(systemName: autoStartEnabled ? "checkmark.circle.fill" : "pause.circle")
                    .font(.system(size: 18))
                    .foregroundColor(autoStartEnabled ? .accentSuccess : .textSecondary)
                Text(autoStartEnabled ? "Auto-start is enabled" : "Auto-start is disabled")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func formattedDuration(_ seconds: Int) -> String {
        guard seconds > 0 else { return "Off" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 {
            return "\(remainder)s"
        } else if remainder == 0 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m \(remainder)s"
        }
    }
}

// MARK: - Rest Timer Banner
struct RestTimerBanner: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let isPaused: Bool
    let onTogglePause: () -> Void
    let onRestart: () -> Void
    let onSkip: () -> Void
    
    private var progress: Double {
        guard totalSeconds > 0 else { return remainingSeconds == 0 ? 1 : 0 }
        let clampedRemaining = max(min(remainingSeconds, totalSeconds), 0)
        let completed = Double(totalSeconds - clampedRemaining)
        return min(max(completed / Double(totalSeconds), 0), 1)
    }
    
    private var statusText: String {
        if isPaused {
            return "Paused"
        }
        if remainingSeconds <= 0 {
            return "Complete"
        }
        return "Total \(formattedTotal)"
    }
    
    private var formattedTotal: String {
        formatDuration(totalSeconds)
    }
    
    private var formattedRemaining: String {
        formatCountdown(remainingSeconds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("REST TIMER")
                        .font(.sectionHeader)
                        .foregroundColor(.textTertiary)
                        .kerning(0.3)
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Text(formattedRemaining)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(.textPrimary)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.tertiaryBg)
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.accentPrimary)
            }
            .frame(height: 6)
            
            HStack(spacing: 12) {
                Button(action: onTogglePause) {
                    Label(isPaused ? "Resume" : "Pause", systemImage: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textInverse)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onRestart) {
                    Label("Restart", systemImage: "gobackward")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.tertiaryBg)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onSkip) {
                    Label("Skip", systemImage: "forward.end.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.errorRed)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.errorRed.opacity(0.15))
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        guard seconds > 0 else { return "Off" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 {
            return "\(remainder)s"
        } else if remainder == 0 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m \(remainder)s"
        }
    }
    
    private func formatCountdown(_ seconds: Int) -> String {
        guard seconds > 0 else { return "00:00" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
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
