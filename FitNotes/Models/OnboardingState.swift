//
//  OnboardingState.swift
//  FitNotes
//
//  State management for the onboarding flow
//

import Foundation
import SwiftUI

// MARK: - OnboardingState
/// Manages the state and collected data throughout the onboarding flow
@MainActor
class OnboardingState: ObservableObject {
    // MARK: - Navigation State
    @Published var currentPageIndex: Int = 0
    @Published var isOnboardingComplete: Bool = false

    // MARK: - Settings State
    @Published var weightUnit: WeightUnit = .lbs
    @Published var defaultRestTimer: Int = 90  // seconds
    @Published var autoProgress: Bool = true  // Auto-apply progression recommendations

    // MARK: - Setup State
    @Published var selectedSetupExercise: PrimaryLift?
    @Published var hasCompletedSetup: Bool = false

    // MARK: - Persistence Keys
    private enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let weightUnit = "onboarding_weightUnit"
        static let defaultRestTimer = "onboarding_defaultRestTimer"
        static let autoProgress = "onboarding_autoProgress"
    }

    // MARK: - Pages
    let pages: [OnboardingPage] = OnboardingState.buildPages()

    // MARK: - Computed Properties
    var currentPage: OnboardingPage {
        pages[currentPageIndex]
    }

    var canProceed: Bool {
        switch currentPage.type {
        case .static:
            return true
        case .settings:
            return true // Unit and timer always have defaults
        case .interactive:
            return hasCompletedSetup
        }
    }

    var progress: Double {
        Double(currentPageIndex + 1) / Double(pages.count)
    }

    var isFirstPage: Bool {
        currentPageIndex == 0
    }

    var isLastPage: Bool {
        currentPageIndex == pages.count - 1
    }

    // MARK: - Navigation Methods
    func nextPage() {
        guard currentPageIndex < pages.count - 1 else {
            completeOnboarding()
            return
        }

        withAnimation(.standardSpring) {
            currentPageIndex += 1
        }
    }

    func previousPage() {
        guard currentPageIndex > 0 else { return }

        withAnimation(.standardSpring) {
            currentPageIndex -= 1
        }
    }

    func skipPage() {
        // Only allowed for non-required pages
        guard !currentPage.isRequired else { return }
        nextPage()
    }

    func goToPage(_ index: Int) {
        guard index >= 0 && index < pages.count else { return }
        withAnimation(.standardSpring) {
            currentPageIndex = index
        }
    }

    // MARK: - Selection Methods
    func setWeightUnit(_ unit: WeightUnit) {
        weightUnit = unit
    }

    func setDefaultRestTimer(_ seconds: Int) {
        defaultRestTimer = seconds
    }

    // MARK: - Completion
    func completeOnboarding() {
        saveState()
        UserDefaults.standard.set(true, forKey: StorageKeys.hasCompletedOnboarding)
        withAnimation(.standardSpring) {
            isOnboardingComplete = true
        }
        // Notify the app to switch views
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }

    // MARK: - Persistence
    func saveState() {
        UserDefaults.standard.set(weightUnit.rawValue, forKey: StorageKeys.weightUnit)
        UserDefaults.standard.set(defaultRestTimer, forKey: StorageKeys.defaultRestTimer)
        UserDefaults.standard.set(autoProgress, forKey: StorageKeys.autoProgress)
    }

    static func hasCompletedOnboarding() -> Bool {
        UserDefaults.standard.bool(forKey: StorageKeys.hasCompletedOnboarding)
    }

    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: StorageKeys.weightUnit)
        UserDefaults.standard.removeObject(forKey: StorageKeys.defaultRestTimer)
        UserDefaults.standard.removeObject(forKey: StorageKeys.autoProgress)
    }

    // MARK: - Page Builder
    private static func buildPages() -> [OnboardingPage] {
        [
            // Screen 1: Welcome
            OnboardingPage(
                type: .static,
                title: "Welcome to LiftLog",
                subtitle: "A Progressive Overload Training App",
                description: "Every great transformation begins with incremental improvement. By downloading this app you're investing in a stronger, more capable version of yourself. \n\n We're here to guide you every rep of the way.",
                systemImage: "figure.walk",
                order: 1
            ),

            // Screen 2: Settings (Unit and Timer)
            OnboardingPage(
                type: .settings,
                title: "Your Preferences",
                subtitle: "Set your defaults for tracking",
                description: nil,
                systemImage: "gearshape.2.fill",
                order: 2
            ),

            // Screen 3: Guided Setup Walkthrough
            OnboardingPage(
                type: .interactive,
                title: "Let's Set Up Your First Exercise",
                subtitle: "We'll walk you through it",
                description: nil,
                systemImage: "gearshape.fill",
                order: 3
            ),

            // Screen 4: Progress Demonstration
            OnboardingPage(
                type: .static,
                title: "Watch Your Progress Grow",
                subtitle: "We'll keep you moving forward",
                description: "FitNotes tracks every rep and automatically suggests when it's time to increase weight. You'll get gentle nudges to push harder—and celebrate every PR along the way.",
                systemImage: "arrow.up.forward.circle.fill",
                order: 4
            ),

            // Screen 5: Analytics Preview
            OnboardingPage(
                type: .static,
                title: "Insights That Matter",
                subtitle: "Data-driven progress",
                description: "Track your volume trends, monitor muscle balance, and see your PRs at a glance. The more you log, the smarter your insights become.",
                systemImage: "chart.xyaxis.line",
                order: 5
            )
        ]
    }
}
