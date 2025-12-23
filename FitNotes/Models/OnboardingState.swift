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

    // MARK: - User Selections (Phase 2)
    @Published var experienceLevel: ExperienceLevel?
    @Published var primaryLifts: Set<PrimaryLift> = []

    // MARK: - Settings State (Phase 2.5)
    @Published var weightUnit: WeightUnit = .lbs
    @Published var defaultRestTimer: Int = 90  // seconds
    @Published var autoProgress: Bool = true  // Auto-apply progression recommendations

    // MARK: - Setup State (Phase 3)
    @Published var selectedSetupExercise: PrimaryLift?
    @Published var hasCompletedSetup: Bool = false

    // MARK: - Conversion (Phase 3)
    @Published var email: String = ""
    @Published var hasProvidedEmail: Bool = false
    @Published var selectedPlan: SubscriptionPlan = .free
    @Published var hasCommitted: Bool = false

    // MARK: - Navigation State (Early Email Capture for Beginners)
    @Published var showedEarlyEmailCapture: Bool = false
    private var returnToPageAfterEmailCapture: Int?

    // MARK: - Persistence Keys
    private enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let experienceLevel = "onboarding_experienceLevel"
        static let primaryLifts = "onboarding_primaryLifts"
        static let weightUnit = "onboarding_weightUnit"
        static let defaultRestTimer = "onboarding_defaultRestTimer"
        static let autoProgress = "onboarding_autoProgress"
        static let email = "onboarding_email"
        static let selectedPlan = "onboarding_selectedPlan"
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
        case .singleSelect:
            return hasMadeRequiredSelection
        case .multiSelect:
            return !currentPage.isRequired || hasMadeRequiredSelection
        case .settings:
            return true // Unit and timer always have defaults
        case .interactive:
            return hasCompletedSetup
        case .conditional:
            return true
        case .emailCapture:
            return true // Skip is allowed
        case .paywall:
            return true
        case .research:
            return true // Has its own continue button
        }
    }

    var progress: Double {
        // When showing email capture early to beginners, show progress as if still in normal flow
        // This prevents the jarring jump from ~40% to ~93%
        if returnToPageAfterEmailCapture != nil && currentPage.type == .emailCapture {
            // Show progress as if we're at the return page (where we'll go after email capture)
            return Double(returnToPageAfterEmailCapture! + 1) / Double(pages.count)
        }
        return Double(currentPageIndex + 1) / Double(pages.count)
    }

    /// Visual page index for display purposes (accounts for early email redirect)
    var visualPageIndex: Int {
        if returnToPageAfterEmailCapture != nil && currentPage.type == .emailCapture {
            return returnToPageAfterEmailCapture!
        }
        return currentPageIndex
    }

    var isFirstPage: Bool {
        currentPageIndex == 0
    }

    var isLastPage: Bool {
        currentPageIndex == pages.count - 1
    }

    private var hasMadeRequiredSelection: Bool {
        switch currentPage.order {
        case 6: // Experience Level
            return experienceLevel != nil
        case 7: // Settings (unit/timer)
            return true
        case 8: // Primary Lifts
            return !primaryLifts.isEmpty
        default:
            return true
        }
    }

    // MARK: - Navigation Methods
    func nextPage() {
        guard currentPageIndex < pages.count - 1 else {
            completeOnboarding()
            return
        }

        // Check if returning from early email capture for beginners
        if let returnPage = returnToPageAfterEmailCapture, currentPage.type == .emailCapture {
            returnToPageAfterEmailCapture = nil
            withAnimation(.standardSpring) {
                currentPageIndex = returnPage
            }
            return
        }

        // Check if on experience level page with beginner/brand new selected
        // Redirect to email capture (Free Guide) immediately
        if currentPage.order == 6,
           let level = experienceLevel,
           (level == .brandNew || level == .beginner),
           !showedEarlyEmailCapture {
            showedEarlyEmailCapture = true
            // Find the email capture page index (order 13)
            if let emailCaptureIndex = pages.firstIndex(where: { $0.order == 13 }) {
                returnToPageAfterEmailCapture = currentPageIndex + 1  // Return to settings (order 7)
                withAnimation(.standardSpring) {
                    currentPageIndex = emailCaptureIndex
                }
                return
            }
        }

        // Move to next page
        var nextIndex = currentPageIndex + 1

        // Skip email capture if already shown early to beginners
        if showedEarlyEmailCapture && nextIndex < pages.count && pages[nextIndex].order == 13 {
            nextIndex += 1
        }

        withAnimation(.standardSpring) {
            currentPageIndex = min(nextIndex, pages.count - 1)
        }
    }

    func previousPage() {
        guard currentPageIndex > 0 else { return }

        // If we're on email capture and came from early redirect, go back to experience level
        if returnToPageAfterEmailCapture != nil, currentPage.type == .emailCapture {
            showedEarlyEmailCapture = false  // Allow showing again if they go forward
            returnToPageAfterEmailCapture = nil
            // Go back to experience level page (order 6)
            if let experiencePageIndex = pages.firstIndex(where: { $0.order == 6 }) {
                withAnimation(.standardSpring) {
                    currentPageIndex = experiencePageIndex
                }
                return
            }
        }

        // Move to previous page
        var prevIndex = currentPageIndex - 1

        // Skip email capture if already shown early to beginners
        if showedEarlyEmailCapture && prevIndex >= 0 && pages[prevIndex].order == 13 {
            prevIndex -= 1
        }

        withAnimation(.standardSpring) {
            currentPageIndex = max(prevIndex, 0)
        }
    }

    func skipPage() {
        // Only allowed for non-required pages
        guard !currentPage.isRequired else { return }

        // If skipping early email capture, return to where we were
        if let returnPage = returnToPageAfterEmailCapture, currentPage.type == .emailCapture {
            returnToPageAfterEmailCapture = nil
            withAnimation(.standardSpring) {
                currentPageIndex = returnPage
            }
            return
        }

        nextPage()
    }

    func goToPage(_ index: Int) {
        guard index >= 0 && index < pages.count else { return }
        withAnimation(.standardSpring) {
            currentPageIndex = index
        }
    }

    // MARK: - Selection Methods
    func selectExperienceLevel(_ level: ExperienceLevel) {
        experienceLevel = level
    }

    func togglePrimaryLift(_ lift: PrimaryLift) {
        if primaryLifts.contains(lift) {
            primaryLifts.remove(lift)
        } else {
            primaryLifts.insert(lift)
        }
    }

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
        if let level = experienceLevel {
            UserDefaults.standard.set(level.rawValue, forKey: StorageKeys.experienceLevel)
        }

        let liftValues = primaryLifts.map { $0.rawValue }
        UserDefaults.standard.set(liftValues, forKey: StorageKeys.primaryLifts)

        UserDefaults.standard.set(weightUnit.rawValue, forKey: StorageKeys.weightUnit)
        UserDefaults.standard.set(defaultRestTimer, forKey: StorageKeys.defaultRestTimer)
        UserDefaults.standard.set(autoProgress, forKey: StorageKeys.autoProgress)

        if !email.isEmpty {
            UserDefaults.standard.set(email, forKey: StorageKeys.email)
        }

        UserDefaults.standard.set(selectedPlan.rawValue, forKey: StorageKeys.selectedPlan)
    }

    static func hasCompletedOnboarding() -> Bool {
        UserDefaults.standard.bool(forKey: StorageKeys.hasCompletedOnboarding)
    }

    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: StorageKeys.experienceLevel)
        UserDefaults.standard.removeObject(forKey: StorageKeys.primaryLifts)
        UserDefaults.standard.removeObject(forKey: StorageKeys.weightUnit)
        UserDefaults.standard.removeObject(forKey: StorageKeys.defaultRestTimer)
        UserDefaults.standard.removeObject(forKey: StorageKeys.autoProgress)
        UserDefaults.standard.removeObject(forKey: StorageKeys.email)
        UserDefaults.standard.removeObject(forKey: StorageKeys.selectedPlan)
    }

    // MARK: - Page Builder
    private static func buildPages() -> [OnboardingPage] {
        [
            // MARK: Phase 1 - Education (Screens 1-7)

            // Screen 1: Welcome
            OnboardingPage(
                type: .static,
                title: "Welcome to LiftLog",
                subtitle: "A Progressive Overload Training App",
                description: "Every great transformation begins with incremental improvement. By downloading this app you're investing in a stronger, more capable version of yourself. \n\n We're here to guide you every rep of the way.",
                systemImage: "figure.walk",
                order: 1
            ),

            // Screen 2: Progressive Overload Introduction
            OnboardingPage(
                type: .static,
                title: "The Secret to Real Progress",
                subtitle: "Progressive Overload",
                description: "Progressive overload means gradually increasing the demands on your muscles over time.\n It's simple: lift a little more weight, do one more rep, add another set, or reduce the time you rest. Small improvements compound into massive results over time.",
                systemImage: "chart.line.uptrend.xyaxis",
                order: 2
            ),

            // Screen 3: Benefits of Progressive Overload
            OnboardingPage(
                type: .static,
                title: "Why It Works",
                subtitle: "The benefits are undeniable",
                description: "• Consistent strength gains week after week\n• Visible muscle growth you can measure\n• Clear progress you can track and celebrate\n\nNo more guessing. No more plateaus. Just results.",
                systemImage: "trophy.fill",
                order: 3
            ),

            // Screen 4: Long-Term Vision
            OnboardingPage(
                type: .static,
                title: "Picture Yourself in 12 Months",
                subtitle: "Real, achievable progress",
                description: "Imagine lifting 50% more than you can today. Imagine looking in the mirror and seeing the definition you've been working toward. Progressive overload along with your determination are the difference between massive gains and a plateau.",
                systemImage: "calendar",
                order: 4
            ),

            // Screen 5: Combined Research & Quotes (scrolling page with bottom continue)
            OnboardingPage(
                type: .research,
                title: "The Science Behind It",
                subtitle: "Research-backed results",
                description: nil,
                systemImage: "brain.head.profile",
                order: 5
            ),

            // MARK: Phase 2 - Personalization (Screens 6-9)

            // Screen 6: Experience Level
            OnboardingPage(
                type: .singleSelect,
                title: "Where Are You Starting?",
                subtitle: "This helps us personalize your experience",
                description: nil,
                systemImage: "figure.strengthtraining.traditional",
                options: ExperienceLevel.allCases.map { level in
                    OnboardingOption(
                        title: level.displayName,
                        subtitle: level.description,
                        value: level.rawValue
                    )
                },
                order: 6
            ),

            // Screen 7: Settings (Unit and Timer)
            OnboardingPage(
                type: .settings,
                title: "Your Preferences",
                subtitle: "Set your defaults for tracking",
                description: nil,
                systemImage: "gearshape.2.fill",
                order: 7
            ),

            // Screen 8: Primary Lifts
            OnboardingPage(
                type: .multiSelect,
                title: "Your Key Lifts",
                subtitle: "Select the lifts you want to focus on",
                description: nil,
                systemImage: "dumbbell.fill",
                options: PrimaryLift.allCases.map { lift in
                    OnboardingOption(
                        title: lift.displayName,
                        subtitle: nil,
                        value: lift.rawValue
                    )
                },
                order: 8
            ),

            // MARK: Phase 3 - Setup & Conversion (Screens 9-13)

            // Screen 9: Guided Setup Walkthrough
            OnboardingPage(
                type: .interactive,
                title: "Let's Set Up Your First Exercise",
                subtitle: "We'll walk you through it",
                description: nil,
                systemImage: "gearshape.fill",
                order: 9
            ),

            // Screen 10: Progress Demonstration
            OnboardingPage(
                type: .static,
                title: "Watch Your Progress Grow",
                subtitle: "We'll keep you moving forward",
                description: "FitNotes tracks every rep and automatically suggests when it's time to increase weight. You'll get gentle nudges to push harder—and celebrate every PR along the way.",
                systemImage: "arrow.up.forward.circle.fill",
                order: 10
            ),

            // Screen 11: Analytics Preview
            OnboardingPage(
                type: .static,
                title: "Insights That Matter",
                subtitle: "Data-driven progress",
                description: "Track your volume trends, monitor muscle balance, and see your PRs at a glance. The more you log, the smarter your insights become.",
                systemImage: "chart.xyaxis.line",
                order: 11
            ),

            // Screen 12: Experience-Based Guidance
            OnboardingPage(
                type: .conditional,
                title: "Your Next Steps",
                subtitle: nil,
                description: nil,
                systemImage: "list.bullet.rectangle",
                order: 12
            ),

            // Screen 13: Email Capture
            OnboardingPage(
                type: .emailCapture,
                title: "Get Our Free Guide",
                subtitle: "The Complete Progressive Overload Handbook",
                description: "Learn the science, history, and practical strategies behind progressive overload. Enter your email and we'll send it straight to your inbox.",
                systemImage: "book.fill",
                isRequired: false,
                order: 13
            ),

            // Screen 14: Commitment + Paywall
            OnboardingPage(
                type: .paywall,
                title: "Ready to Commit?",
                subtitle: "Are you ready to become the most fit you've ever been?",
                description: nil,
                systemImage: "checkmark.circle.fill",
                order: 14
            )
        ]
    }
}
