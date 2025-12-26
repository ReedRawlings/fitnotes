//
//  OnboardingModels.swift
//  FitNotes
//
//  Onboarding data models for the 17-screen onboarding flow
//

import Foundation

// MARK: - OnboardingPageType
/// Defines the different types of onboarding screens
enum OnboardingPageType: String, Codable {
    case `static`       // Informational only
    case singleSelect   // Pick one option
    case multiSelect    // Pick multiple options
    case settings       // Unit and timer preferences
    case interactive    // Guided setup walkthrough
    case conditional    // Content varies based on previous answers
    case emailCapture   // Email input
    case paywall        // Subscription options
    case research       // Combined research & quotes screen with bottom continue button
}

// MARK: - WeightUnit
/// User's preferred weight unit
enum WeightUnit: String, Codable, CaseIterable {
    case kg = "kg"
    case lbs = "lbs"

    var displayName: String {
        switch self {
        case .kg: return "Kilograms (kg)"
        case .lbs: return "Pounds (lbs)"
        }
    }

    var shortName: String {
        rawValue
    }
}

// MARK: - OnboardingOption
/// Represents a selectable option in single/multi-select screens
struct OnboardingOption: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String?
    let value: String  // The stored value (e.g., "brand_new", "beginner")

    init(id: UUID = UUID(), title: String, subtitle: String? = nil, value: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.value = value
    }
}

// MARK: - OnboardingPage
/// Represents a single page in the onboarding flow
struct OnboardingPage: Identifiable {
    let id: UUID
    let type: OnboardingPageType
    let title: String
    let subtitle: String?
    let description: String?
    let systemImage: String
    let options: [OnboardingOption]?
    let isRequired: Bool
    let order: Int

    init(
        id: UUID = UUID(),
        type: OnboardingPageType,
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        systemImage: String,
        options: [OnboardingOption]? = nil,
        isRequired: Bool = true,
        order: Int
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.systemImage = systemImage
        self.options = options
        self.isRequired = isRequired
        self.order = order
    }
}

// MARK: - ExperienceLevel
/// User's fitness experience level
enum ExperienceLevel: String, Codable, CaseIterable {
    case brandNew = "brand_new"
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        switch self {
        case .brandNew: return "Brand New"
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var description: String {
        switch self {
        case .brandNew: return "Never lifted weights before"
        case .beginner: return "Some experience, inconsistent"
        case .intermediate: return "Regular lifting, 6+ months"
        case .advanced: return "Years of consistent training"
        }
    }
}

// MARK: - PrimaryLift
/// Common compound lifts for selection
enum PrimaryLift: String, Codable, CaseIterable {
    case benchPress = "bench_press"
    case squat = "squat"
    case deadlift = "deadlift"
    case overheadPress = "overhead_press"
    case barbellRow = "barbell_row"
    case pullUp = "pull_up"
    case dip = "dip"
    case legPress = "leg_press"

    var displayName: String {
        switch self {
        case .benchPress: return "Bench Press"
        case .squat: return "Squat"
        case .deadlift: return "Deadlift"
        case .overheadPress: return "Overhead Press"
        case .barbellRow: return "Barbell Row"
        case .pullUp: return "Pull-up"
        case .dip: return "Dip"
        case .legPress: return "Leg Press"
        }
    }
}

// MARK: - HealthGoal
/// Additional health goals beyond lifting
enum HealthGoal: String, Codable, CaseIterable {
    case weightLoss = "weight_loss"
    case cardiovascular = "cardiovascular"
    case flexibility = "flexibility"
    case injuryRecovery = "injury_recovery"
    case generalWellness = "general_wellness"

    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .cardiovascular: return "Cardiovascular Health"
        case .flexibility: return "Flexibility"
        case .injuryRecovery: return "Injury Recovery"
        case .generalWellness: return "General Wellness"
        }
    }
}

// MARK: - SubscriptionPlan
/// Available subscription options
enum SubscriptionPlan: String, Codable {
    case free = "free"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
}

// MARK: - StarterRoutine
/// Available starter routines for beginners during onboarding
enum StarterRoutine: String, Codable, CaseIterable {
    case fullBody = "full_body"
    case pushPullLegs = "push_pull_legs"
    case upperLower = "upper_lower"

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body Starter"
        case .pushPullLegs: return "Push/Pull/Legs"
        case .upperLower: return "Upper/Lower Split"
        }
    }

    var subtitle: String {
        switch self {
        case .fullBody: return "3 days/week • Perfect for beginners"
        case .pushPullLegs: return "3-6 days/week • Flexible split"
        case .upperLower: return "4 days/week • Balanced approach"
        }
    }

    var icon: String {
        switch self {
        case .fullBody: return "figure.walk"
        case .pushPullLegs: return "arrow.left.arrow.right"
        case .upperLower: return "arrow.up.arrow.down"
        }
    }

    /// Minimum number of workout days required for this routine
    var minimumDays: Int {
        switch self {
        case .fullBody: return 3
        case .pushPullLegs: return 3  // Can work with 3 (1x each) or 6 (2x each)
        case .upperLower: return 4
        }
    }

    /// Description of the day requirement for UI
    var daysRequirement: String {
        switch self {
        case .fullBody: return "Select at least 3 days"
        case .pushPullLegs: return "Select 3-6 days"
        case .upperLower: return "Select at least 4 days"
        }
    }
}
