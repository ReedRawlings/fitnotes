//
//  ContentView.swift
//  FitNotes
//
//  Created by Reed Rawlings on 10/14/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingNewWorkout = false
    
    var recentWorkouts: [Workout] {
        Array(workouts.prefix(7))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Recent Workouts Section
                    if !recentWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Workouts")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            LazyVStack(spacing: 8) {
                                ForEach(recentWorkouts) { workout in
                                    WorkoutRowView(workout: workout)
                                }
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No workouts yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Tap the + button to start your first workout")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("FitNotes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewWorkout = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewWorkout) {
            NewWorkoutView()
        }
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !workout.sets.isEmpty {
                    Text("\(workout.sets.count) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if workout.totalVolume > 0 {
                Text("\(Int(workout.totalVolume)) kg")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            VStack {
                Text("New Workout")
                    .font(.largeTitle)
                    .padding()
                
                Text("Workout creation coming soon!")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WorkoutsView: View { var body: some View { Text("Workouts") } }
struct ProgramsView: View { var body: some View { Text("Programs") } }
struct ExercisesView: View {
    @StateObject private var exerciseLibraryService = ExerciseLibraryService(exerciseRepository: InMemoryExerciseRepository())
    
    var body: some View {
        ExerciseLibraryView(exerciseLibraryService: exerciseLibraryService)
    }
}
struct InsightsView: View { var body: some View { Text("Insights") } }
struct SettingsView: View { var body: some View { Text("Settings") } }

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "calendar") }
            ProgramsView()
                .tabItem { Label("Programs", systemImage: "list.bullet.rectangle") }
            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "dumbbell") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, Program.self, BodyMetric.self], inMemory: true)
}
