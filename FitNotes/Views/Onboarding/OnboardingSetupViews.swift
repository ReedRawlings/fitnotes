//
//  OnboardingSetupViews.swift
//  FitNotes
//
//  Setup and conversion screens for onboarding (Screens 12-17)
//  Phase 3 - Full implementation pending
//

import SwiftUI
import StoreKit

// MARK: - Interactive Setup View (Screen 12)
/// Guided walkthrough for setting up the first exercise
struct OnboardingInteractiveSetupView: View {
    @ObservedObject var state: OnboardingState

    // Setup steps
    @State private var currentStep: Int = 0
    @State private var selectedExercise: PrimaryLift?
    @State private var targetRepsMin: Int = 5
    @State private var targetRepsMax: Int = 8
    @State private var weightIncrement: Double = 2.5
    @State private var showingExercisePicker: Bool = false

    private let totalSteps = 4

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

            // Step Progress Bar
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= currentStep ? Color.accentPrimary : Color.tertiaryBg)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 32)

                    // Icon
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

                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.accentPrimary, .accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Spacer()
                        .frame(height: 24)

                    // Title
                    Text("Let's Set Up Your First Exercise")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("We'll walk you through it")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    Spacer()
                        .frame(height: 32)

                    // Step Content
                    VStack(spacing: 16) {
                        switch currentStep {
                        case 0:
                            exerciseSelectionStep
                        case 1:
                            repRangeStep
                        case 2:
                            weightIncrementStep
                        case 3:
                            confirmationStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 24)
                }
            }

            // Bottom Continue Button
            VStack(spacing: 12) {
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
                }
                .disabled(!canProceedStep)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .onAppear {
            // Pre-select first lift from user's selection if available
            if let firstLift = state.primaryLifts.first {
                selectedExercise = firstLift
            }
            // Set default weight increment based on unit
            weightIncrement = state.weightUnit == .lbs ? 5.0 : 2.5
        }
    }

    // MARK: - Step Views

    private var exerciseSelectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 1: Choose an Exercise")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text("Select one of your key lifts to set up first")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)

            // Show user's selected lifts
            VStack(spacing: 8) {
                ForEach(Array(state.primaryLifts), id: \.self) { lift in
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
                                    .foregroundColor(.accentPrimary)
                            }
                        }
                        .padding(16)
                        .background(selectedExercise == lift ? Color.accentPrimary.opacity(0.1) : Color.secondaryBg)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedExercise == lift ? Color.accentPrimary : Color.white.opacity(0.06), lineWidth: selectedExercise == lift ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .cardStyle()
        .padding(.horizontal, 0)
    }

    private var repRangeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 2: Set Your Rep Range")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text("When you hit the top of your range, it's time to increase weight")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)

            VStack(spacing: 16) {
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

            // Visual representation
            HStack {
                Text("Target: \(targetRepsMin)-\(targetRepsMax) reps")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.accentPrimary.opacity(0.1))
            .cornerRadius(8)
        }
        .cardStyle()
        .padding(.horizontal, 0)
    }

    private var weightIncrementStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 3: Weight Increment")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text("How much weight will you add when progressing?")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)

            DoubleStepperRow(
                label: "Increment",
                value: $weightIncrement,
                range: 0.5...10.0,
                suffix: " \(state.weightUnit.shortName)",
                step: 0.5
            )

            // Suggestion based on exercise
            if let exercise = selectedExercise {
                let suggestion = getSuggestedIncrement(for: exercise)
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.accentSecondary)

                    Text("Suggested for \(exercise.displayName): \(String(format: "%.1f", suggestion)) \(state.weightUnit.shortName)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .padding(12)
                .background(Color.secondaryBg)
                .cornerRadius(8)
            }
        }
        .cardStyle()
        .padding(.horizontal, 0)
    }

    private var confirmationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 4: Confirm Your Setup")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text("Here's what we'll track for you")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)

            VStack(spacing: 12) {
                confirmationRow(label: "Exercise", value: selectedExercise?.displayName ?? "")
                confirmationRow(label: "Rep Range", value: "\(targetRepsMin)-\(targetRepsMax) reps")
                confirmationRow(label: "Weight Increment", value: "\(String(format: "%.1f", weightIncrement)) \(state.weightUnit.shortName)")
            }

            // Success message
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentSuccess)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Progressive Overload Enabled")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("We'll notify you when it's time to level up")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentSuccess.opacity(0.1))
            .cornerRadius(12)
        }
        .cardStyle()
        .padding(.horizontal, 0)
    }

    private func confirmationRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.textPrimary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var canProceedStep: Bool {
        switch currentStep {
        case 0:
            return selectedExercise != nil
        case 1:
            return targetRepsMin < targetRepsMax
        case 2:
            return weightIncrement > 0
        case 3:
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
            // Complete setup
            state.selectedSetupExercise = selectedExercise
            state.hasCompletedSetup = true
        }
    }

    private func previousStep() {
        if currentStep > 0 {
            withAnimation(.standardSpring) {
                currentStep -= 1
            }
        }
    }

    private func getSuggestedIncrement(for lift: PrimaryLift) -> Double {
        // Different suggestions based on weight unit
        if state.weightUnit == .lbs {
            switch lift {
            case .squat, .deadlift, .legPress:
                return 5.0
            case .benchPress, .overheadPress, .barbellRow:
                return 5.0
            case .pullUp, .dip:
                return 2.5
            }
        } else {
            switch lift {
            case .squat, .deadlift, .legPress:
                return 2.5
            case .benchPress, .overheadPress, .barbellRow:
                return 2.5
            case .pullUp, .dip:
                return 1.25
            }
        }
    }
}

// MARK: - Conditional View (Screen 15)
/// Shows different content based on experience level
struct OnboardingConditionalView: View {
    @ObservedObject var state: OnboardingState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)

                // Icon
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

                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Spacer()
                    .frame(height: 24)

                // Title
                Text("Your Next Steps")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Spacer()
                    .frame(height: 32)

                // Conditional content based on experience
                if isBeginnerPath {
                    beginnerContent
                } else {
                    advancedContent
                }

                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
    }

    private var isBeginnerPath: Bool {
        guard let level = state.experienceLevel else { return true }
        return level == .brandNew || level == .beginner
    }

    private var beginnerContent: some View {
        VStack(spacing: 16) {
            Text("Perfect for Getting Started")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.accentPrimary)

            Text("We've curated beginner-friendly routines designed to build your foundation safely and effectively.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                routineCard(
                    title: "Full Body Starter",
                    subtitle: "3 days/week • Perfect for beginners",
                    icon: "figure.walk"
                )

                routineCard(
                    title: "Push/Pull/Legs",
                    subtitle: "3-6 days/week • Flexible split",
                    icon: "arrow.left.arrow.right"
                )

                routineCard(
                    title: "Upper/Lower Split",
                    subtitle: "4 days/week • Balanced approach",
                    icon: "arrow.up.arrow.down"
                )
            }

            Text("You can browse and start these routines after onboarding")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(20)
    }

    private var advancedContent: some View {
        VStack(spacing: 16) {
            Text("You Know What You're Doing")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.accentPrimary)

            Text("Head to Settings > Routines to build your own custom routines or explore our example templates for inspiration.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                featureCard(
                    title: "Custom Routines",
                    subtitle: "Build exactly what you need",
                    icon: "plus.square"
                )

                featureCard(
                    title: "Example Templates",
                    subtitle: "PPL, Upper/Lower, and more",
                    icon: "doc.text"
                )

                featureCard(
                    title: "Full Flexibility",
                    subtitle: "Track any exercise, any way",
                    icon: "slider.horizontal.3"
                )
            }

            Text("Find everything in Settings after onboarding")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(20)
    }

    private func routineCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.tertiaryBg)
        .cornerRadius(12)
    }

    private func featureCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.tertiaryBg)
        .cornerRadius(12)
    }
}

// MARK: - Email Capture View (Screen 16)
struct OnboardingEmailCaptureView: View {
    let page: OnboardingPage
    @ObservedObject var state: OnboardingState
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)

                // Icon
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

                    Image(systemName: page.systemImage)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Spacer()
                    .frame(height: 24)

                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle = page.subtitle {
                    Text(subtitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.accentPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                if let description = page.description {
                    Text(description)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                }

                Spacer()
                    .frame(height: 32)

                // Email Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)

                    TextField("your@email.com", text: $state.email)
                        .font(.system(size: 17))
                        .foregroundColor(.textPrimary)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isEmailFocused)
                        .padding(16)
                        .background(Color.tertiaryBg)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isEmailFocused ? Color.accentPrimary : Color.white.opacity(0.06), lineWidth: isEmailFocused ? 2 : 1)
                        )
                }
                .padding(.horizontal, 20)

                // What you'll get
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's in the guide:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    guideFeature(text: "The history & science of progressive overload")
                    guideFeature(text: "Step-by-step progression strategies")
                    guideFeature(text: "Common mistakes and how to avoid them")
                    guideFeature(text: "Sample workout progressions")
                }
                .padding(20)
                .background(Color.secondaryBg)
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer()
                    .frame(height: 120)
            }
        }
    }

    private func guideFeature(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.accentSuccess)

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Paywall View (Screen 17)
struct OnboardingPaywallView: View {
    @ObservedObject var state: OnboardingState
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var selectedProductId: String?
    @State private var isPurchasing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)

                // Commitment Section
                VStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Ready to Commit?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text("Are you ready to become the most fit you've ever been?")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
                    .frame(height: 32)

                // Plan Selection
                VStack(spacing: 16) {
                    // Yearly Plan (Best Value)
                    if let yearly = storeManager.yearlyProduct {
                        StoreKitPlanCard(
                            product: yearly,
                            isSelected: selectedProductId == yearly.id,
                            isPremium: true,
                            badge: savingsBadge,
                            monthlyEquivalent: storeManager.formattedPricePerMonth(for: yearly),
                            features: premiumFeatures,
                            onTap: {
                                selectedProductId = yearly.id
                                state.selectedPlan = .premium
                            }
                        )
                    }

                    // Monthly Plan
                    if let monthly = storeManager.monthlyProduct {
                        StoreKitPlanCard(
                            product: monthly,
                            isSelected: selectedProductId == monthly.id,
                            isPremium: true,
                            badge: nil,
                            monthlyEquivalent: nil,
                            features: premiumFeatures,
                            onTap: {
                                selectedProductId = monthly.id
                                state.selectedPlan = .premium
                            }
                        )
                    }

                    // Free Plan
                    PlanOptionCard(
                        title: "Free",
                        price: "Forever",
                        features: freeFeatures,
                        isSelected: state.selectedPlan == .free && selectedProductId == nil,
                        isPremium: false,
                        onTap: {
                            selectedProductId = nil
                            state.selectedPlan = .free
                        }
                    )
                }
                .padding(.horizontal, 20)

                // Loading indicator for products
                if storeManager.isLoading && storeManager.products.isEmpty {
                    ProgressView()
                        .tint(.accentPrimary)
                        .padding(.top, 20)
                }

                // Error message
                if let error = storeManager.errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.errorRed)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 20)
                }

                // Legal text and restore
                VStack(spacing: 12) {
                    Text("Cancel anytime. Subscription auto-renews.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textTertiary)
                        .multilineTextAlignment(.center)

                    Button(action: restorePurchases) {
                        Text("Restore Purchases")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .underline()
                    }

                    // Terms and Privacy links
                    HStack(spacing: 16) {
                        Button(action: { openTerms() }) {
                            Text("Terms of Use")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.textTertiary)
                        }

                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.textTertiary)

                        Button(action: { openPrivacy() }) {
                            Text("Privacy Policy")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                .padding(.top, 16)

                Spacer()
                    .frame(height: 120)
            }
        }
        .overlay {
            if isPurchasing {
                purchasingOverlay
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Default to yearly if available
            if let yearly = storeManager.yearlyProduct {
                selectedProductId = yearly.id
                state.selectedPlan = .premium
            }
        }
    }

    // MARK: - Premium Features
    private var premiumFeatures: [String] {
        [
            "Unlimited exercise tracking",
            "Advanced analytics & insights",
            "Custom progression targets",
            "Export workout data",
            "Priority support"
        ]
    }

    private var freeFeatures: [String] {
        [
            "Track up to 5 exercises",
            "Basic workout logging",
            "7-day history"
        ]
    }

    private var savingsBadge: String? {
        guard let yearly = storeManager.yearlyProduct,
              let monthly = storeManager.monthlyProduct else {
            return nil
        }
        let savings = storeManager.savingsPercentage(yearly: yearly, monthly: monthly)
        return savings > 0 ? "Save \(savings)%" : nil
    }

    // MARK: - Purchasing Overlay
    private var purchasingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)

                Text("Processing...")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.secondaryBg)
            .cornerRadius(20)
        }
    }

    // MARK: - Actions
    func purchaseSelectedPlan() async {
        guard let productId = selectedProductId,
              let product = storeManager.products.first(where: { $0.id == productId }) else {
            return
        }

        isPurchasing = true

        do {
            _ = try await storeManager.purchase(product)
            isPurchasing = false
            // Purchase successful - complete onboarding
            state.completeOnboarding()
        } catch StoreError.userCancelled {
            isPurchasing = false
            // User cancelled - do nothing
        } catch StoreError.pending {
            isPurchasing = false
            errorMessage = "Your purchase is pending approval. You'll get access once it's approved."
            showError = true
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func restorePurchases() {
        Task {
            isPurchasing = true
            await storeManager.restorePurchases()
            isPurchasing = false

            if storeManager.isPremium {
                state.selectedPlan = .premium
                state.completeOnboarding()
            }
        }
    }

    private func openTerms() {
        // TODO: Replace with your actual Terms URL
        if let url = URL(string: "https://fitnotes.app/terms") {
            UIApplication.shared.open(url)
        }
    }

    private func openPrivacy() {
        // TODO: Replace with your actual Privacy Policy URL
        if let url = URL(string: "https://fitnotes.app/privacy") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - StoreKit Plan Card
struct StoreKitPlanCard: View {
    let product: Product
    let isSelected: Bool
    let isPremium: Bool
    let badge: String?
    let monthlyEquivalent: String?
    let features: [String]
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(product.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.textPrimary)

                            if isPremium {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentSecondary)
                            }

                            if let badge = badge {
                                Text(badge)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.textInverse)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentSuccess)
                                    .cornerRadius(6)
                            }
                        }

                        HStack(spacing: 4) {
                            Text(product.displayPrice)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(isPremium ? .accentPrimary : .textSecondary)

                            Text(subscriptionPeriod)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.textSecondary)
                        }

                        if let monthly = monthlyEquivalent {
                            Text("(\(monthly)/month)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.textTertiary)
                        }
                    }

                    Spacer()

                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.accentPrimary : Color.textTertiary, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color.accentPrimary)
                                .frame(width: 14, height: 14)
                        }
                    }
                }

                // Features (only show when selected)
                if isSelected {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(features, id: \.self) { feature in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isPremium ? .accentPrimary : .textSecondary)

                                Text(feature)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(20)
            .background(isSelected ? Color.accentPrimary.opacity(0.1) : Color.secondaryBg)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.accentPrimary : Color.white.opacity(0.06),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .animation(.standardSpring, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var subscriptionPeriod: String {
        guard let subscription = product.subscription else { return "" }

        switch subscription.subscriptionPeriod.unit {
        case .month:
            return subscription.subscriptionPeriod.value == 1 ? "/month" : "/\(subscription.subscriptionPeriod.value) months"
        case .year:
            return subscription.subscriptionPeriod.value == 1 ? "/year" : "/\(subscription.subscriptionPeriod.value) years"
        case .week:
            return "/week"
        case .day:
            return "/day"
        @unknown default:
            return ""
        }
    }
}

// MARK: - Plan Option Card
struct PlanOptionCard: View {
    let title: String
    let price: String
    let features: [String]
    let isSelected: Bool
    let isPremium: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.textPrimary)

                            if isPremium {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentSecondary)
                            }
                        }

                        Text(price)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isPremium ? .accentPrimary : .textSecondary)
                    }

                    Spacer()

                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.accentPrimary : Color.textTertiary, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color.accentPrimary)
                                .frame(width: 14, height: 14)
                        }
                    }
                }

                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isPremium ? .accentPrimary : .textSecondary)

                            Text(feature)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .padding(20)
            .background(isSelected ? (isPremium ? Color.accentPrimary.opacity(0.1) : Color.secondaryBg) : Color.secondaryBg)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? (isPremium ? Color.accentPrimary : Color.textTertiary) : Color.white.opacity(0.06),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
#Preview("Interactive Setup") {
    let state = OnboardingState()
    state.primaryLifts = [.benchPress, .squat, .deadlift]

    return ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingInteractiveSetupView(state: state)
    }
}

#Preview("Conditional - Beginner") {
    let state = OnboardingState()
    state.experienceLevel = .beginner

    return ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingConditionalView(state: state)
    }
}

#Preview("Conditional - Advanced") {
    let state = OnboardingState()
    state.experienceLevel = .advanced

    return ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingConditionalView(state: state)
    }
}

#Preview("Email Capture") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingEmailCaptureView(
            page: OnboardingPage(
                type: .emailCapture,
                title: "Get Our Free Guide",
                subtitle: "The Complete Progressive Overload Handbook",
                description: "Learn the science, history, and practical strategies behind progressive overload.",
                systemImage: "book.fill",
                isRequired: false,
                order: 16
            ),
            state: OnboardingState()
        )
    }
}

#Preview("Paywall") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingPaywallView(state: OnboardingState())
    }
}
