//
//  OnboardingContainerView.swift
//  FitNotes
//
//  Main container view for the onboarding flow
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var state = OnboardingState()

    var body: some View {
        ZStack {
            // Background
            Color.primaryBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Bar with Back Button
                OnboardingProgressBar(
                    progress: state.progress,
                    currentPage: state.currentPageIndex + 1,
                    totalPages: state.pages.count,
                    isFirstPage: state.isFirstPage,
                    onBack: { state.previousPage() }
                )
                .padding(.top, 8)

                // Page Content
                TabView(selection: $state.currentPageIndex) {
                    ForEach(Array(state.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page, state: state)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.standardSpring, value: state.currentPageIndex)

                // Bottom Navigation (hidden for pages with their own navigation)
                if state.currentPage.type != .interactive {
                    OnboardingBottomBar(state: state)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Progress Bar with Back Button
struct OnboardingProgressBar: View {
    let progress: Double
    let currentPage: Int
    let totalPages: Int
    let isFirstPage: Bool
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Back chevron (hidden on first page)
            if !isFirstPage {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .frame(width: 32, height: 32)
                }
            } else {
                // Spacer to maintain layout when no back button
                Spacer()
                    .frame(width: 32, height: 32)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.tertiaryBg)
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.standardSpring, value: progress)
                }
            }
            .frame(height: 4)

            // Page count
            Text("\(currentPage)/\(totalPages)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.textTertiary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Page View Router
struct OnboardingPageView: View {
    let page: OnboardingPage
    @ObservedObject var state: OnboardingState

    var body: some View {
        Group {
            switch page.type {
            case .static:
                OnboardingStaticPageView(page: page)
            case .settings:
                OnboardingSettingsView(page: page, state: state)
            case .interactive:
                OnboardingInteractiveSetupView(state: state)
            }
        }
    }
}

// MARK: - Bottom Navigation Bar
struct OnboardingBottomBar: View {
    @ObservedObject var state: OnboardingState

    var body: some View {
        VStack(spacing: 12) {
            // Primary CTA
            Button(action: {
                handlePrimaryAction()
            }) {
                HStack(spacing: 8) {
                    Text(primaryButtonTitle)
                        .font(.buttonFont)

                    if !state.isLastPage {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.textInverse)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    state.canProceed ?
                    LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.textTertiary.opacity(0.3), Color.textTertiary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(
                    color: state.canProceed ? .accentPrimary.opacity(0.3) : .clear,
                    radius: 16,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!state.canProceed)
            .padding(.horizontal, 20)

            // Secondary Actions (Skip button only - back is now in progress bar)
            if !state.currentPage.isRequired && !state.isLastPage {
                HStack {
                    Spacer()
                    Button(action: {
                        state.skipPage()
                    }) {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .frame(height: 32)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func handlePrimaryAction() {
        state.nextPage()
    }

    private var primaryButtonTitle: String {
        if state.isLastPage {
            return "Get Started"
        }

        switch state.currentPage.type {
        case .static:
            return "Continue"
        case .settings:
            return "Continue"
        case .interactive:
            return state.hasCompletedSetup ? "Continue" : "Complete Setup"
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView()
}
