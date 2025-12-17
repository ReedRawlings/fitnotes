//
//  OnboardingSelectionViews.swift
//  FitNotes
//
//  Selection screens for onboarding (Screens 8-11)
//

import SwiftUI

// MARK: - Single Select View (Screens 8, 9)
struct OnboardingSingleSelectView: View {
    let page: OnboardingPage
    @ObservedObject var state: OnboardingState

    // Animation state
    @State private var iconOpacity: CGFloat = 0
    @State private var titleOpacity: CGFloat = 0
    @State private var optionsOpacity: CGFloat = 0

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
                .opacity(iconOpacity)

                Spacer()
                    .frame(height: 24)

                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                // Subtitle
                if let subtitle = page.subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(titleOpacity)
                }

                Spacer()
                    .frame(height: 32)

                // Options
                if let options = page.options {
                    VStack(spacing: 12) {
                        ForEach(options) { option in
                            SingleSelectOptionButton(
                                option: option,
                                isSelected: isOptionSelected(option),
                                onTap: { selectOption(option) }
                            )
                        }
                    }
                    .opacity(optionsOpacity)
                }

                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            animateContent()
        }
    }

    private func isOptionSelected(_ option: OnboardingOption) -> Bool {
        switch page.order {
        case 8: // Experience Level
            return state.experienceLevel?.rawValue == option.value
        case 9: // Goals
            return state.fitnessGoal?.rawValue == option.value
        default:
            return false
        }
    }

    private func selectOption(_ option: OnboardingOption) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.standardSpring) {
            switch page.order {
            case 8: // Experience Level
                if let level = ExperienceLevel(rawValue: option.value) {
                    state.selectExperienceLevel(level)
                }
            case 9: // Goals
                if let goal = OnboardingFitnessGoal(rawValue: option.value) {
                    state.selectFitnessGoal(goal)
                }
            default:
                break
            }
        }
    }

    private func animateContent() {
        iconOpacity = 0
        titleOpacity = 0
        optionsOpacity = 0

        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            iconOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            titleOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            optionsOpacity = 1.0
        }
    }
}

// MARK: - Single Select Option Button
struct SingleSelectOptionButton: View {
    let option: OnboardingOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.textSecondary)
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
            .padding(16)
            .background(isSelected ? Color.accentPrimary.opacity(0.1) : Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentPrimary : Color.white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Multi Select View (Screens 10, 11)
struct OnboardingMultiSelectView: View {
    let page: OnboardingPage
    @ObservedObject var state: OnboardingState

    // Animation state
    @State private var iconOpacity: CGFloat = 0
    @State private var titleOpacity: CGFloat = 0
    @State private var optionsOpacity: CGFloat = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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
                .opacity(iconOpacity)

                Spacer()
                    .frame(height: 24)

                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                // Subtitle
                if let subtitle = page.subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(titleOpacity)
                }

                Spacer()
                    .frame(height: 32)

                // Options Grid
                if let options = page.options {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(options) { option in
                            MultiSelectOptionButton(
                                option: option,
                                isSelected: isOptionSelected(option),
                                onTap: { toggleOption(option) }
                            )
                        }
                    }
                    .opacity(optionsOpacity)
                }

                // Selection count
                Text(selectionCountText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .padding(.top, 16)
                    .opacity(optionsOpacity)

                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            animateContent()
        }
    }

    private var selectionCountText: String {
        let count = selectedCount
        switch page.order {
        case 10:
            return count == 0 ? "Select at least one lift" : "\(count) lift\(count == 1 ? "" : "s") selected"
        default:
            return ""
        }
    }

    private var selectedCount: Int {
        switch page.order {
        case 10:
            return state.primaryLifts.count
        default:
            return 0
        }
    }

    private func isOptionSelected(_ option: OnboardingOption) -> Bool {
        switch page.order {
        case 10: // Primary Lifts
            if let lift = PrimaryLift(rawValue: option.value) {
                return state.primaryLifts.contains(lift)
            }
        default:
            break
        }
        return false
    }

    private func toggleOption(_ option: OnboardingOption) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.standardSpring) {
            switch page.order {
            case 10: // Primary Lifts
                if let lift = PrimaryLift(rawValue: option.value) {
                    state.togglePrimaryLift(lift)
                }
            default:
                break
            }
        }
    }

    private func animateContent() {
        iconOpacity = 0
        titleOpacity = 0
        optionsOpacity = 0

        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            iconOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            titleOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            optionsOpacity = 1.0
        }
    }
}

// MARK: - Multi Select Option Button
struct MultiSelectOptionButton: View {
    let option: OnboardingOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(option.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentPrimary : Color.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.accentPrimary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textInverse)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? Color.accentPrimary.opacity(0.1) : Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentPrimary : Color.white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings View (Screen 11)
struct OnboardingSettingsView: View {
    let page: OnboardingPage
    @ObservedObject var state: OnboardingState

    // Animation state
    @State private var iconOpacity: CGFloat = 0
    @State private var titleOpacity: CGFloat = 0
    @State private var contentOpacity: CGFloat = 0

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
                .opacity(iconOpacity)

                Spacer()
                    .frame(height: 24)

                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                // Subtitle
                if let subtitle = page.subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(titleOpacity)
                }

                Spacer()
                    .frame(height: 32)

                // Settings content
                VStack(spacing: 24) {
                    // Weight Unit Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weight Unit")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 12) {
                            ForEach(WeightUnit.allCases, id: \.self) { unit in
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    state.setWeightUnit(unit)
                                }) {
                                    VStack(spacing: 8) {
                                        Text(unit.shortName.uppercased())
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(state.weightUnit == unit ? .textPrimary : .textSecondary)

                                        Text(unit == .kg ? "Kilograms" : "Pounds")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(state.weightUnit == unit ? .textSecondary : .textTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(state.weightUnit == unit ? Color.accentPrimary.opacity(0.1) : Color.secondaryBg)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(state.weightUnit == unit ? Color.accentPrimary : Color.white.opacity(0.06), lineWidth: state.weightUnit == unit ? 2 : 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // Rest Timer Setting
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Rest Timer")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Time between sets (you can adjust per exercise later)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.textSecondary)

                        // Timer presets
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                timerButton(seconds: 60, label: "1:00")
                                timerButton(seconds: 90, label: "1:30")
                                timerButton(seconds: 120, label: "2:00")
                            }
                            HStack(spacing: 8) {
                                timerButton(seconds: 150, label: "2:30")
                                timerButton(seconds: 180, label: "3:00")
                                timerButton(seconds: 0, label: "Off")
                            }
                        }

                        // Current selection display
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.accentPrimary)

                            Text(state.defaultRestTimer == 0 ? "Timer disabled" : "Rest: \(formatTime(state.defaultRestTimer))")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.accentPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .opacity(contentOpacity)

                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            animateContent()
        }
    }

    private func timerButton(seconds: Int, label: String) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            state.setDefaultRestTimer(seconds)
        }) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(state.defaultRestTimer == seconds ? .textPrimary : .textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(state.defaultRestTimer == seconds ? Color.accentPrimary.opacity(0.1) : Color.secondaryBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(state.defaultRestTimer == seconds ? Color.accentPrimary : Color.white.opacity(0.06), lineWidth: state.defaultRestTimer == seconds ? 2 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func animateContent() {
        iconOpacity = 0
        titleOpacity = 0
        contentOpacity = 0

        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            iconOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            titleOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            contentOpacity = 1.0
        }
    }
}

// MARK: - Previews
#Preview("Single Select") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingSingleSelectView(
            page: OnboardingPage(
                type: .singleSelect,
                title: "Where Are You Starting?",
                subtitle: "This helps us personalize your experience",
                systemImage: "figure.strengthtraining.traditional",
                options: ExperienceLevel.allCases.map { level in
                    OnboardingOption(
                        title: level.displayName,
                        subtitle: level.description,
                        value: level.rawValue
                    )
                },
                order: 8
            ),
            state: OnboardingState()
        )
    }
}

#Preview("Multi Select") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingMultiSelectView(
            page: OnboardingPage(
                type: .multiSelect,
                title: "Your Key Lifts",
                subtitle: "Select the lifts you want to focus on",
                systemImage: "dumbbell.fill",
                options: PrimaryLift.allCases.map { lift in
                    OnboardingOption(
                        title: lift.displayName,
                        subtitle: nil,
                        value: lift.rawValue
                    )
                },
                order: 10
            ),
            state: OnboardingState()
        )
    }
}

#Preview("Settings") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingSettingsView(
            page: OnboardingPage(
                type: .settings,
                title: "Your Preferences",
                subtitle: "Set your defaults for tracking",
                systemImage: "gearshape.2.fill",
                order: 11
            ),
            state: OnboardingState()
        )
    }
}
