import SwiftUI
import SwiftData

struct ExerciseSettingsView: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedMode: RPEMode = .off
    
    enum RPEMode: String, CaseIterable {
        case off = "Off"
        case rpe = "RPE"
        case rir = "RIR"
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
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving exercise settings: \(error)")
        }
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

