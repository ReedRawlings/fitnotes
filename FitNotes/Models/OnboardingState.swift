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
    @Published var fitnessGoal: OnboardingFitnessGoal?
    @Published var primaryLifts: Set<PrimaryLift> = []
    @Published var healthGoals: Set<HealthGoal> = []

    // MARK: - Setup State (Phase 3)
    @Published var selectedSetupExercise: PrimaryLift?
    @Published var hasCompletedSetup: Bool = false

    // MARK: - Conversion (Phase 3)
    @Published var email: String = ""
    @Published var hasProvidedEmail: Bool = false
    @Published var selectedPlan: SubscriptionPlan = .free
    @Published var hasCommitted: Bool = false

    // MARK: - Persistence Keys
    private enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let experienceLevel = "onboarding_experienceLevel"
        static let fitnessGoal = "onboarding_fitnessGoal"
        static let primaryLifts = "onboarding_primaryLifts"
        static let healthGoals = "onboarding_healthGoals"
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
        case .interactive:
            return hasCompletedSetup
        case .conditional:
            return true
        case .emailCapture:
            return true // Skip is allowed
        case .paywall:
            return true
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

    private var hasMadeRequiredSelection: Bool {
        switch currentPage.order {
        case 8: // Experience Level
            return experienceLevel != nil
        case 9: // Goals
            return fitnessGoal != nil
        case 10: // Primary Lifts
            return !primaryLifts.isEmpty
        case 11: // Health Goals (optional)
            return true
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
    func selectExperienceLevel(_ level: ExperienceLevel) {
        experienceLevel = level
    }

    func selectFitnessGoal(_ goal: OnboardingFitnessGoal) {
        fitnessGoal = goal
    }

    func togglePrimaryLift(_ lift: PrimaryLift) {
        if primaryLifts.contains(lift) {
            primaryLifts.remove(lift)
        } else {
            primaryLifts.insert(lift)
        }
    }

    func toggleHealthGoal(_ goal: HealthGoal) {
        if healthGoals.contains(goal) {
            healthGoals.remove(goal)
        } else {
            healthGoals.insert(goal)
        }
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
        if let goal = fitnessGoal {
            UserDefaults.standard.set(goal.rawValue, forKey: StorageKeys.fitnessGoal)
        }

        let liftValues = primaryLifts.map { $0.rawValue }
        UserDefaults.standard.set(liftValues, forKey: StorageKeys.primaryLifts)

        let healthValues = healthGoals.map { $0.rawValue }
        UserDefaults.standard.set(healthValues, forKey: StorageKeys.healthGoals)

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
        UserDefaults.standard.removeObject(forKey: StorageKeys.fitnessGoal)
        UserDefaults.standard.removeObject(forKey: StorageKeys.primaryLifts)
        UserDefaults.standard.removeObject(forKey: StorageKeys.healthGoals)
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
                title: "Welcome to FitNotes",
                subtitle: "Your journey starts here",
                description: "Every great transformation begins with a single step. You're not just downloading an app—you're investing in a stronger, more capable version of yourself. We're here to guide you every rep of the way.",
                systemImage: "figure.walk",
                order: 1
            ),

            // Screen 2: Progressive Overload Introduction
            OnboardingPage(
                type: .static,
                title: "The Secret to Real Progress",
                subtitle: "Progressive Overload",
                description: "Progressive overload means gradually increasing the demands on your muscles over time. It's simple: lift a little more weight, do one more rep, or add one more set. Small improvements compound into massive results.",
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
                description: "Imagine lifting 50% more than you can today. Imagine looking in the mirror and seeing the definition you've been working toward. With progressive overload, these aren't dreams—they're milestones you'll hit.",
                systemImage: "calendar",
                order: 4
            ),

            // Screen 5: Science-Backed Benefit
            OnboardingPage(
                type: .static,
                title: "Backed by Science",
                subtitle: "Research proves it works",
                description: "A study in the Journal of Strength and Conditioning Research found that lifters who followed progressive overload principles gained 25% more strength over 12 weeks compared to those who trained without a structured progression plan.",
                systemImage: "brain.head.profile",
                order: 5
            ),

            // Screen 6: Expert Quote
            OnboardingPage(
                type: .static,
                title: "From the Experts",
                subtitle: nil,
                description: "\"Progressive overload is the number one driver of muscle growth. If you're not progressively challenging your muscles, you're leaving gains on the table. It's not optional—it's essential.\"\n\n— Greg Doucette, IFBB Pro & Fitness Coach",
                systemImage: "quote.bubble.fill",
                order: 6
            ),

            // Screen 7: Final Research Point
            OnboardingPage(
                type: .static,
                title: "Built for Longevity",
                subtitle: "Train smarter, not just harder",
                description: "Research from the American College of Sports Medicine shows that progressive resistance training not only builds strength but also reduces injury risk by 30% and improves joint health over time.",
                systemImage: "checkmark.seal.fill",
                order: 7
            ),

            // MARK: Phase 2 - Personalization (Screens 8-11)

            // Screen 8: Experience Level
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
                order: 8
            ),

            // Screen 9: Goals
            OnboardingPage(
                type: .singleSelect,
                title: "What's Your Goal?",
                subtitle: "We'll tailor your tracking to match",
                description: nil,
                systemImage: "target",
                options: OnboardingFitnessGoal.allCases.map { goal in
                    OnboardingOption(
                        title: goal.displayName,
                        subtitle: goal.description,
                        value: goal.rawValue
                    )
                },
                order: 9
            ),

            // Screen 10: Primary Lifts
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
                order: 10
            ),

            // Screen 11: Health Goals (Optional)
            OnboardingPage(
                type: .multiSelect,
                title: "Any Other Goals?",
                subtitle: "Optional—select any that apply",
                description: nil,
                systemImage: "heart.text.square.fill",
                options: HealthGoal.allCases.map { goal in
                    OnboardingOption(
                        title: goal.displayName,
                        subtitle: nil,
                        value: goal.rawValue
                    )
                },
                isRequired: false,
                order: 11
            ),

            // MARK: Phase 3 - Setup & Conversion (Screens 12-17)

            // Screen 12: Guided Setup Walkthrough
            OnboardingPage(
                type: .interactive,
                title: "Let's Set Up Your First Exercise",
                subtitle: "We'll walk you through it",
                description: nil,
                systemImage: "gearshape.fill",
                order: 12
            ),

            // Screen 13: Progress Demonstration
            OnboardingPage(
                type: .static,
                title: "Watch Your Progress Grow",
                subtitle: "We'll keep you moving forward",
                description: "FitNotes tracks every rep and automatically suggests when it's time to increase weight. You'll get gentle nudges to push harder—and celebrate every PR along the way.",
                systemImage: "arrow.up.forward.circle.fill",
                order: 13
            ),

            // Screen 14: Analytics Preview
            OnboardingPage(
                type: .static,
                title: "Insights That Matter",
                subtitle: "Data-driven progress",
                description: "Track your volume trends, monitor muscle balance, and see your PRs at a glance. The more you log, the smarter your insights become.",
                systemImage: "chart.xyaxis.line",
                order: 14
            ),

            // Screen 15: Experience-Based Guidance
            OnboardingPage(
                type: .conditional,
                title: "Your Next Steps",
                subtitle: nil,
                description: nil,
                systemImage: "list.bullet.rectangle",
                order: 15
            ),

            // Screen 16: Email Capture
            OnboardingPage(
                type: .emailCapture,
                title: "Get Our Free Guide",
                subtitle: "The Complete Progressive Overload Handbook",
                description: "Learn the science, history, and practical strategies behind progressive overload. Enter your email and we'll send it straight to your inbox.",
                systemImage: "book.fill",
                isRequired: false,
                order: 16
            ),

            // Screen 17: Commitment + Paywall
            OnboardingPage(
                type: .paywall,
                title: "Ready to Commit?",
                subtitle: "Are you ready to become the most fit you've ever been?",
                description: nil,
                systemImage: "checkmark.circle.fill",
                order: 17
            )
        ]
    }
}
