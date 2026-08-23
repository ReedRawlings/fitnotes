//
//  OnboardingSetupViews.swift
//  FitNotes
//
//  Guided first-exercise setup screen for onboarding
//

import SwiftUI

// MARK: - Interactive Setup View
/// Guided walkthrough for setting up the first exercise with progressive overload
struct OnboardingInteractiveSetupView: View {
    @ObservedObject var state: OnboardingState

    // Setup steps
    @State private var currentStep: Int = 0
    @State private var selectedExercise: PrimaryLift?
    @State private var targetRepsMin: Int = 5
    @State private var targetRepsMax: Int = 8
    @State private var weightIncrement: Double = 2.5
    @State private var progressionSetCount: Int = 4
    @State private var useWarmupSet: Bool = false
    @State private var autoProgress: Bool = true
    @State private var showingExercisePicker: Bool = false

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                if currentStep > 0 {
                    Button(action: previousStep) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    Spacer()
                        .frame(width: 44, height: 44)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: currentStep >= 2 ? 20 : 40)

                    // Icon - hidden on steps 3, 4, 5 (indices 2, 3, 4) to give more space for content
                    if currentStep < 2 {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.accentPrimary.opacity(0.15),
                                            Color.accentSecondary.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "arrow.up.forward.circle.fill")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.accentPrimary, .accentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Spacer()
                            .frame(height: 28)
                    }

                    // Title
                    Text("Configure Progressive Overload")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Text("Set up your first lift to track strength gains")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 36)

                    // Step Content
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0:
                            exerciseSelectionStep
                        case 1:
                            repRangeStep
                        case 2:
                            setTrackingStep
                        case 3:
                            weightIncrementStep
                        case 4:
                            confirmationStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 32)
                }
            }

            // Bottom Section: Step Progress + Continue Button
            VStack(spacing: 20) {
                // Step Progress Indicators (moved below content)
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(step <= currentStep ? Color.accentPrimary : Color.tertiaryBg)
                            .frame(height: 6)
                            .animation(.standardSpring, value: currentStep)
                    }
                }
                .padding(.horizontal, 20)

                Button(action: nextStep) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textInverse)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            canProceedStep ?
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.textTertiary.opacity(0.3), Color.textTertiary.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: canProceedStep ? .accentPrimary.opacity(0.3) : .clear,
                            radius: 16,
                            x: 0,
                            y: 4
                        )
                }
                .disabled(!canProceedStep)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 28)
        }
        .onAppear {
            // Set default weight increment based on unit
            weightIncrement = state.weightUnit == .lbs ? 5.0 : 2.5
        }
    }

    // MARK: - Step Views

    private var exerciseSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 1: Choose Your Lift")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text("Select a compound lift to track with progressive overload")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Common compound lifts to choose from
            VStack(spacing: 10) {
                ForEach(PrimaryLift.allCases, id: \.self) { lift in
                    Button(action: {
                        selectedExercise = lift
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        HStack {
                            Text(lift.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.textPrimary)

                            Spacer()

                            if selectedExercise == lift {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.accentPrimary)
                            } else {
                                Circle()
                                    .stroke(Color.textTertiary, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(selectedExercise == lift ? Color.accentPrimary.opacity(0.1) : Color.tertiaryBg)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedExercise == lift ? Color.accentPrimary : Color.white.opacity(0.06), lineWidth: selectedExercise == lift ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var repRangeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 2: Set Your Rep Range")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text("When you hit the top of your range, we'll prompt you to add weight")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 14) {
                StepperRow(
                    label: "Minimum Reps",
                    value: $targetRepsMin,
                    range: 1...20
                )

                StepperRow(
                    label: "Maximum Reps",
                    value: $targetRepsMax,
                    range: 1...30
                )
            }
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var setTrackingStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 3: Set Tracking")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text("Configure which sets count toward your progression")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 14) {
                StepperRow(
                    label: "Working Sets to Track",
                    value: $progressionSetCount,
                    range: 1...10
                )

                // Warm-up set toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First Set is Warm-up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textPrimary)

                        Text("Exclude first set from progression tracking")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $useWarmupSet)
                        .labelsHidden()
                        .tint(.accentPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.tertiaryBg)
                .cornerRadius(12)

                // Auto Progress toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Progress")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textPrimary)

                        Text("Automatically apply progression recommendations")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $autoProgress)
                        .labelsHidden()
                        .tint(.accentPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.tertiaryBg)
                .cornerRadius(12)
            }

            // Explanation
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentPrimary)

                Text("Only these sets will be used to calculate your progression recommendations")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.tertiaryBg)
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var weightIncrementStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 4: Weight Increment")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text("How much weight will you add each time you progress?")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DoubleStepperRow(
                label: "Increment",
                value: $weightIncrement,
                range: 0.5...10.0,
                suffix: " \(state.weightUnit.shortName)",
                step: 0.5
            )
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var confirmationStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 5: Review Your Setup")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text("Your progressive overload configuration")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.textSecondary)
            }

            VStack(spacing: 0) {
                confirmationRow(label: "Exercise", value: selectedExercise?.displayName ?? "")
                Divider()
                    .background(Color.white.opacity(0.06))
                confirmationRow(label: "Rep Range", value: "\(targetRepsMin)-\(targetRepsMax) reps")
                Divider()
                    .background(Color.white.opacity(0.06))
                confirmationRow(label: "Sets to Track", value: "\(progressionSetCount) sets")
                Divider()
                    .background(Color.white.opacity(0.06))
                confirmationRow(label: "Warm-up Set", value: useWarmupSet ? "Yes (excluded)" : "No")
                Divider()
                    .background(Color.white.opacity(0.06))
                confirmationRow(label: "Auto Progress", value: autoProgress ? "On" : "Off")
                Divider()
                    .background(Color.white.opacity(0.06))
                confirmationRow(label: "Weight Increment", value: "+\(String(format: "%.1f", weightIncrement)) \(state.weightUnit.shortName)")
            }
            .padding(.vertical, 4)
            .background(Color.tertiaryBg)
            .cornerRadius(14)

            // Success message
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.accentSuccess.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentSuccess)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Progressive Overload Active")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("We'll notify you when it's time to increase weight")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentSuccess.opacity(0.08))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentSuccess.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func confirmationRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private var canProceedStep: Bool {
        switch currentStep {
        case 0:
            return selectedExercise != nil
        case 1:
            return targetRepsMin < targetRepsMax
        case 2:
            return progressionSetCount > 0
        case 3:
            return weightIncrement > 0
        case 4:
            return true
        default:
            return true
        }
    }

    private func nextStep() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if currentStep < totalSteps - 1 {
            withAnimation(.standardSpring) {
                currentStep += 1
            }
        } else {
            // Complete setup and advance to next onboarding page
            state.selectedSetupExercise = selectedExercise
            state.autoProgress = autoProgress
            state.hasCompletedSetup = true
            state.nextPage()
        }
    }

    private func previousStep() {
        if currentStep > 0 {
            withAnimation(.standardSpring) {
                currentStep -= 1
            }
        }
    }
}

// MARK: - Previews
#Preview("Interactive Setup") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingInteractiveSetupView(state: OnboardingState())
    }
}
