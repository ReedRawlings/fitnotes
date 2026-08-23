//
//  OnboardingSelectionViews.swift
//  FitNotes
//
//  Settings screen for onboarding
//

import SwiftUI

// MARK: - Settings View
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
#Preview("Settings") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingSettingsView(
            page: OnboardingPage(
                type: .settings,
                title: "Your Preferences",
                subtitle: "Set your defaults for tracking",
                systemImage: "gearshape.2.fill",
                order: 2
            ),
            state: OnboardingState()
        )
    }
}
