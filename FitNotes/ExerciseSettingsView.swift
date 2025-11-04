import SwiftUI
import SwiftData

struct ExerciseSettingsView: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedMode: RPEMode = .off
    @State private var showingTimePicker = false
    @State private var timePickerForSet: Int? = nil // nil means default/standard mode
    @State private var tempSelectedSeconds: Int = 90
    @State private var showingAdvancedToStandardAlert = false
    
    enum RPEMode: String, CaseIterable {
        case off = "Off"
        case rpe = "RPE"
        case rir = "RIR"
    }
    
    // Get current session sets count (for Advanced mode display)
    private var currentSetsCount: Int {
        // Query for today's sets to determine how many sets to show
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let exerciseId = exercise.id
        
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.exerciseId == exerciseId &&
                set.date >= today &&
                set.date < tomorrow
            }
        )
        
        do {
            let sets = try modelContext.fetch(descriptor)
            return max(1, sets.count) // Show at least 1 set
        } catch {
            return 1
        }
    }
    
    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // RPE/RIR Tracking Card
                    FormSectionCard(title: "RPE/RIR Tracking") {
                        VStack(spacing: 12) {
                            // Segmented Control
                            HStack(spacing: 0) {
                                ForEach(RPEMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        withAnimation(.standardSpring) {
                                            selectedMode = mode
                                            updateExerciseMode()
                                        }
                                    }) {
                                        Text(mode.rawValue)
                                            .font(.system(size: 15, weight: selectedMode == mode ? .semibold : .medium))
                                            .foregroundColor(selectedMode == mode ? .textPrimary : .textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(selectedMode == mode ? Color.tertiaryBg : Color.clear)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(4)
                            .background(Color.secondaryBg)
                            .cornerRadius(12)
                            
                            // Description text
                            Text(modeDescription)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    
                    // Rest Timer Card
                    FormSectionCard(title: "Rest Timer") {
                        VStack(spacing: 12) {
                            // Rest Timer Toggle
                            HStack {
                                Text("Enable Rest Timer")
                                    .font(.bodyFont)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $exercise.useRestTimer)
                                    .tint(.accentPrimary)
                                    .labelsHidden()
                            }
                            .onChange(of: exercise.useRestTimer) { _, newValue in
                                if !newValue {
                                    // Reset to defaults when disabled
                                    exercise.useAdvancedRest = false
                                    exercise.customRestSeconds = [:]
                                }
                                saveExercise()
                            }
                            
                            // Configuration area (only visible when enabled)
                            if exercise.useRestTimer {
                                VStack(spacing: 12) {
                                    // Mode Selector
                                    HStack(spacing: 0) {
                                        Button(action: {
                                            if exercise.useAdvancedRest {
                                                showingAdvancedToStandardAlert = true
                                            } else {
                                                exercise.useAdvancedRest = false
                                                saveExercise()
                                            }
                                        }) {
                                            Text("Standard")
                                                .font(.system(size: 15, weight: !exercise.useAdvancedRest ? .semibold : .medium))
                                                .foregroundColor(!exercise.useAdvancedRest ? .textPrimary : .textSecondary)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 44)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(!exercise.useAdvancedRest ? Color.tertiaryBg : Color.clear)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            withAnimation(.standardSpring) {
                                                exercise.useAdvancedRest = true
                                                saveExercise()
                                            }
                                        }) {
                                            Text("Advanced")
                                                .font(.system(size: 15, weight: exercise.useAdvancedRest ? .semibold : .medium))
                                                .foregroundColor(exercise.useAdvancedRest ? .textPrimary : .textSecondary)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 44)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(exercise.useAdvancedRest ? Color.tertiaryBg : Color.clear)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(4)
                                    .background(Color.tertiaryBg)
                                    .cornerRadius(12)
                                    
                                    // Configuration based on mode
                                    if !exercise.useAdvancedRest {
                                        // Standard Mode: Single time picker
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Rest Between Sets")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.textSecondary)
                                            
                                            Button(action: {
                                                tempSelectedSeconds = exercise.defaultRestSeconds
                                                timePickerForSet = nil
                                                showingTimePicker = true
                                            }) {
                                                HStack {
                                                    Text(formatTime(exercise.defaultRestSeconds))
                                                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                                                        .foregroundColor(.textPrimary)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 16)
                                                .background(Color.tertiaryBg)
                                                .cornerRadius(10)
                                            }
                                        }
                                    } else {
                                        // Advanced Mode: Set-specific time pickers
                                        VStack(spacing: 12) {
                                            ForEach(1...currentSetsCount, id: \.self) { setNumber in
                                                HStack {
                                                    Text("Set \(setNumber):")
                                                        .font(.bodyFont)
                                                        .foregroundColor(.textPrimary)
                                                        .frame(width: 70, alignment: .leading)
                                                    
                                                    Spacer()
                                                    
                                                    Button(action: {
                                                        tempSelectedSeconds = getRestSecondsForSet(setNumber)
                                                        timePickerForSet = setNumber
                                                        showingTimePicker = true
                                                    }) {
                                                        Text(formatTime(getRestSecondsForSet(setNumber)))
                                                            .font(.system(size: 20, weight: .medium, design: .monospaced))
                                                            .foregroundColor(hasCustomRestForSet(setNumber) ? .accentPrimary : .textSecondary)
                                                    }
                                                }
                                            }
                                            
                                            // "All Others" row
                                            HStack {
                                                Text("All Others:")
                                                    .font(.bodyFont)
                                                    .foregroundColor(.textPrimary)
                                                    .frame(width: 70, alignment: .leading)
                                                
                                                Spacer()
                                                
                                                Button(action: {
                                                    tempSelectedSeconds = exercise.defaultRestSeconds
                                                    timePickerForSet = -1 // Special value for "All Others"
                                                    showingTimePicker = true
                                                }) {
                                                    Text(formatTime(exercise.defaultRestSeconds))
                                                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                                                        .foregroundColor(.textSecondary)
                                                }
                                            }
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            
            // Fixed CTA at bottom
            FixedModalCTAButton(
                title: "Done",
                icon: "checkmark",
                isEnabled: true,
                action: {
                    dismiss()
                }
            )
        }
        .navigationTitle("Exercise Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTimePicker) {
            TimePickerModal(selectedSeconds: $tempSelectedSeconds, isPresented: $showingTimePicker)
                .presentationDetents([.height(300)])
                .onDisappear {
                    // Save the selected time
                    if let setNumber = timePickerForSet {
                        if setNumber == -1 {
                            // "All Others" - update default
                            exercise.defaultRestSeconds = tempSelectedSeconds
                        } else {
                            // Specific set - update custom dictionary
                            var customDict = exercise.customRestSeconds
                            customDict[setNumber] = tempSelectedSeconds
                            exercise.customRestSeconds = customDict
                        }
                    } else {
                        // Standard mode - update default
                        exercise.defaultRestSeconds = tempSelectedSeconds
                    }
                    saveExercise()
                }
        }
        .alert("Switch to Standard mode?", isPresented: $showingAdvancedToStandardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Switch to Standard") {
                exercise.useAdvancedRest = false
                exercise.customRestSeconds = [:]
                saveExercise()
            }
        } message: {
            Text("Custom rest times for individual sets will be removed.")
        }
        .onAppear {
            // Initialize selectedMode based on exercise state
            if exercise.rpeEnabled {
                selectedMode = .rpe
            } else if exercise.rirEnabled {
                selectedMode = .rir
            } else {
                selectedMode = .off
            }
        }
    }
    
    private var modeDescription: String {
        switch selectedMode {
        case .off:
            return "No RPE or RIR tracking"
        case .rpe:
            return "Rate of Perceived Exertion (0-10 scale)"
        case .rir:
            return "Reps in Reserve (0-10 scale)"
        }
    }
    
    private func updateExerciseMode() {
        switch selectedMode {
        case .off:
            exercise.rpeEnabled = false
            exercise.rirEnabled = false
        case .rpe:
            exercise.setRPEMode(enabled: true)
        case .rir:
            exercise.setRIRMode(enabled: true)
        }
        
        saveExercise()
    }
    
    private func saveExercise() {
        exercise.updatedAt = Date()
        do {
            try modelContext.save()
        } catch {
            print("Error saving exercise settings: \(error)")
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func getRestSecondsForSet(_ setNumber: Int) -> Int {
        if let customSeconds = exercise.customRestSeconds[setNumber] {
            return customSeconds
        }
        return exercise.defaultRestSeconds
    }
    
    private func hasCustomRestForSet(_ setNumber: Int) -> Bool {
        return exercise.customRestSeconds[setNumber] != nil
    }
}

#Preview {
    NavigationStack {
        ExerciseSettingsView(exercise: Exercise(
            name: "Bench Press",
            primaryCategory: "Chest",
            secondaryCategories: ["Triceps", "Shoulders"],
            equipment: "Machine"
        ))
    }
    .modelContainer(for: [Exercise.self], inMemory: true)
}

