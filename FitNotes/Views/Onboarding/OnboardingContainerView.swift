//
//  OnboardingContainerView.swift
//  FitNotes
//
//  Main container view for the onboarding flow
//

import SwiftUI
import StoreKit

struct OnboardingContainerView: View {
    @StateObject private var state = OnboardingState()
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Background
            Color.primaryBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Bar
                OnboardingProgressBar(progress: state.progress)
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

                // Bottom Navigation (hidden for interactive setup which has its own navigation)
                if state.currentPage.type != .interactive {
                    OnboardingBottomBar(state: state, storeManager: storeManager)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Progress Bar
struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
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
            case .singleSelect:
                OnboardingSingleSelectView(page: page, state: state)
            case .multiSelect:
                OnboardingMultiSelectView(page: page, state: state)
            case .settings:
                OnboardingSettingsView(page: page, state: state)
            case .interactive:
                OnboardingInteractiveSetupView(state: state)
            case .conditional:
                OnboardingConditionalView(state: state)
            case .emailCapture:
                OnboardingEmailCaptureView(page: page, state: state)
            case .paywall:
                OnboardingPaywallView(state: state)
            }
        }
    }
}

// MARK: - Bottom Navigation Bar
struct OnboardingBottomBar: View {
    @ObservedObject var state: OnboardingState
    @ObservedObject var storeManager: StoreKitManager
    @State private var isPurchasing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 12) {
            // Primary CTA
            Button(action: {
                handlePrimaryAction()
            }) {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.textInverse)
                            .scaleEffect(0.9)
                    } else {
                        Text(primaryButtonTitle)
                            .font(.buttonFont)

                        if !state.isLastPage {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
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
            .disabled(!state.canProceed || isPurchasing)
            .padding(.horizontal, 20)

            // Secondary Actions
            HStack {
                // Back button (hidden on first page)
                if !state.isFirstPage {
                    Button(action: {
                        state.previousPage()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .medium))
                            Text("Back")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.textSecondary)
                    }
                } else {
                    Spacer()
                }

                Spacer()

                // Skip button (for optional pages)
                if !state.currentPage.isRequired && !state.isLastPage {
                    Button(action: {
                        state.skipPage()
                    }) {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 32)
        }
        .padding(.bottom, 24)
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Actions

    private func handlePrimaryAction() {
        // If on paywall and premium is selected, initiate purchase
        if state.currentPage.type == .paywall && state.selectedPlan == .premium {
            Task {
                await purchasePremium()
            }
        } else {
            state.nextPage()
        }
    }

    private func purchasePremium() async {
        // Try yearly first, then monthly
        guard let product = storeManager.yearlyProduct ?? storeManager.monthlyProduct else {
            // No products available, just continue
            state.completeOnboarding()
            return
        }

        isPurchasing = true

        do {
            _ = try await storeManager.purchase(product)
            isPurchasing = false
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

    private var primaryButtonTitle: String {
        if state.isLastPage {
            return state.selectedPlan == .premium ? "Start Premium" : "Get Started"
        }

        switch state.currentPage.type {
        case .static:
            return "Continue"
        case .singleSelect, .multiSelect:
            return state.canProceed ? "Continue" : "Select to Continue"
        case .settings:
            return "Continue"
        case .interactive:
            return state.hasCompletedSetup ? "Continue" : "Complete Setup"
        case .conditional:
            return "Continue"
        case .emailCapture:
            return state.email.isEmpty ? "Continue" : "Send Guide"
        case .paywall:
            return state.selectedPlan == .premium ? "Start Premium" : "Continue Free"
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView()
}
