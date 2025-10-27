//
//  FitNotesApp.swift
//  FitNotes
//
//  Created by Reed Rawlings on 10/14/25.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct FitNotesApp: App {
    
    init() {
        // Configure tab bar and navigation bar appearance globally
        configureAppearance()
    }
    
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            BodyMetric.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            RoutineExercise.self,
            Routine.self
        ])
        
        // Use a specific URL for the database to make it easier to manage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databaseURL = documentsPath.appendingPathComponent("FitNotes.sqlite")
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: databaseURL,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            // If there's a schema issue, try to delete the old database and recreate
            print("ModelContainer creation failed: \(error)")
            print("Attempting to recreate database...")
            
            // Delete the existing database file
            try? FileManager.default.removeItem(at: databaseURL)
            
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("Successfully recreated ModelContainer")
                return container
            } catch {
                fatalError("Could not create ModelContainer even after recreation: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func configureAppearance() {
        // Configure Tab Bar Appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(hex: "#0A0E14") // primaryBg
        
        // Active tab styling (coral-orange accent)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "#FF6B35") // accentPrimary
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(hex: "#FF6B35"),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        // Inactive tab styling (muted secondary)
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex: "#8B92A0") // textSecondary
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(hex: "#8B92A0"),
            .font: UIFont.systemFont(ofSize: 12, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Configure Navigation Bar Appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(hex: "#0A0E14") // primaryBg
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(hex: "#FFFFFF") // textPrimary
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(hex: "#FFFFFF") // textPrimary
        ]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}

// MARK: - UIColor Extension for Hex (for FitNotesApp)
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
