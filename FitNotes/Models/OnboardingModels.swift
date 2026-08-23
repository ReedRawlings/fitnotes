//
//  OnboardingModels.swift
//  FitNotes
//
//  Onboarding data models for the onboarding flow
//

import Foundation

// MARK: - OnboardingPageType
/// Defines the different types of onboarding screens
enum OnboardingPageType: String, Codable {
    case `static`       // Informational only
    case settings       // Unit and timer preferences
    case interactive    // Guided setup walkthrough
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

// MARK: - OnboardingPage
/// Represents a single page in the onboarding flow
struct OnboardingPage: Identifiable {
    let id: UUID
    let type: OnboardingPageType
    let title: String
    let subtitle: String?
    let description: String?
    let systemImage: String
    let isRequired: Bool
    let order: Int

    init(
        id: UUID = UUID(),
        type: OnboardingPageType,
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        systemImage: String,
        isRequired: Bool = true,
        order: Int
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.systemImage = systemImage
        self.isRequired = isRequired
        self.order = order
    }
}

// MARK: - PrimaryLift
/// Common compound lifts for the guided first-exercise setup
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
