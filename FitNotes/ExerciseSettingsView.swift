import SwiftUI
import SwiftData

struct ExerciseSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let exercise: Exercise
    
    @State private var restDuration: Int
    @State private var autoStart: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _restDuration = State(initialValue: max(exercise.restTimerDuration, 0))
        _autoStart = State(initialValue: exercise.autoStartRestTimer)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    FormSectionCard(title: "REST TIMER") {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $autoStart) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Auto-start timer")
                                        .font(.bodyFont)
                                        .foregroundColor(.textPrimary)
                                    Text("Automatically begin the rest timer whenever you complete a set.")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .accentPrimary))
                            
                            Divider()
                                .overlay(Color.white.opacity(0.08))
                            
                            VStack(alignment: .leading, spacing: 12) {
                                StepperRow(
                                    label: "Default duration",
                                    value: $restDuration,
                                    range: 0...600,
                                    suffix: "s",
                                    step: 5
                                )
                                
                                Text("Currently set to \(formattedTime(restDuration)). Applies to this exercise only.")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color.primaryBg.ignoresSafeArea())
            .navigationTitle("Exercise Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            handleSave()
                        }
                        .disabled(!hasChanges)
                    }
                }
            }
            .alert(
                "Unable to Save",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private var hasChanges: Bool {
        restDuration != exercise.restTimerDuration || autoStart != exercise.autoStartRestTimer
    }
    
    private func handleSave() {
        guard hasChanges else {
            dismiss()
            return
        }
        isSaving = true
        let sanitizedDuration = max(0, min(restDuration, 600))
        exercise.restTimerDuration = sanitizedDuration
        exercise.autoStartRestTimer = autoStart
        exercise.updatedAt = Date()
        do {
            try modelContext.save()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            isSaving = false
        }
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        guard seconds > 0 else { return "Off" }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes == 0 {
            return "\(remainingSeconds) seconds"
        } else if remainingSeconds == 0 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        } else {
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}
