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
            Routine.self,
            UserPreferences.self
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
