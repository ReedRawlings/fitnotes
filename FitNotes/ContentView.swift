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
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var workoutExercises: [WorkoutExercise] = []
    @State private var showingAddExercise = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Workout Header
                VStack(spacing: 16) {
                    Text("New Workout")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                
                Divider()
                
                // Exercises Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Exercises")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        Button(action: { showingAddExercise = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Exercise")
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal)
                    }
                    
                    if workoutExercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("No exercises added")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Add exercises to start your workout")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(workoutExercises.indices, id: \.self) { index in
                                    WorkoutExerciseRowView(
                                        workoutExercise: $workoutExercises[index],
                                        onRemove: {
                                            workoutExercises.remove(at: index)
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                Spacer()
                
                // Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Workout notes (optional)", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .disabled(workoutExercises.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToWorkoutView { exercise in
                addExerciseToWorkout(exercise)
            }
        }
    }
    
    private func addExerciseToWorkout(_ exercise: Exercise) {
        let workoutExercise = WorkoutExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            order: workoutExercises.count + 1
        )
        workoutExercises.append(workoutExercise)
    }
    
    private func saveWorkout() {
        let workout = Workout(
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes
        )
        workout.totalVolume = calculateTotalVolume()
        
        modelContext.insert(workout)
        
        // Create WorkoutSet entries for each exercise
        for (index, workoutExercise) in workoutExercises.enumerated() {
            let workoutSet = WorkoutSet(
                exerciseId: workoutExercise.exerciseId,
                order: index + 1,
                weight: workoutExercise.weight,
                reps: workoutExercise.reps,
                completed: workoutExercise.completed
            )
            workoutSet.workout = workout
            modelContext.insert(workoutSet)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving workout: \(error)")
        }
    }
    
    private func calculateTotalVolume() -> Double {
        return workoutExercises.reduce(0) { total, exercise in
            let effectiveWeight: Double
            if exercise.weight < 0 {
                // For assisted exercises, assume 70kg body weight minus assistance
                let bodyWeight = 70.0 // Default body weight assumption
                effectiveWeight = bodyWeight + exercise.weight // weight is negative, so this subtracts assistance
            } else {
                effectiveWeight = exercise.weight
            }
            return total + (effectiveWeight * Double(exercise.reps))
        }
    }
}

struct WorkoutExercise: Identifiable {
    let id = UUID()
    var exerciseId: UUID
    var exerciseName: String
    var order: Int
    var sets: Int = 1
    var reps: Int = 10
    var weight: Double = 0
    var completed: Bool = false
}

struct WorkoutExerciseRowView: View {
    @Binding var workoutExercise: WorkoutExercise
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutExercise.exerciseName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Set \(workoutExercise.sets)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            // Exercise Details
            HStack(spacing: 16) {
                // Reps
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper("\(workoutExercise.reps)", value: $workoutExercise.reps, in: 1...100)
                        .labelsHidden()
                }
                
                // Weight
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutExercise.weight < 0 ? "Assistance (kg)" : "Weight (kg)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper(workoutExercise.weight < 0 ? "-\(Int(-workoutExercise.weight))" : "\(Int(workoutExercise.weight))", 
                           value: $workoutExercise.weight, in: -100...500, step: 1)
                        .labelsHidden()
                }
                
                // Completed Toggle
                VStack(alignment: .leading, spacing: 4) {
                    Text("Done")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        workoutExercise.completed.toggle()
                    }) {
                        Image(systemName: workoutExercise.completed ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(workoutExercise.completed ? .green : .gray)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddExerciseToWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    let onAddExercise: (Exercise) -> Void
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup = "All"
    
    private var filteredExercises: [Exercise] {
        var filtered = exercises
        
        if selectedMuscleGroup != "All" {
            filtered = filtered.filter { $0.category == selectedMuscleGroup }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered
    }
    
    private var muscleGroups: [String] {
        let groups = Set(exercises.map { $0.category })
        return ["All"] + groups.sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(muscleGroups, id: \.self) { group in
                                Button(action: {
                                    selectedMuscleGroup = group
                                }) {
                                    Text(group)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedMuscleGroup == group
                                                ? Color.accentColor
                                                : Color(.systemGray5)
                                        )
                                        .foregroundColor(
                                            selectedMuscleGroup == group
                                                ? .white
                                                : .primary
                                        )
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Exercises List
                if filteredExercises.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No exercises found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredExercises) { exercise in
                        Button(action: {
                            onAddExercise(exercise)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 8) {
                                        Text(exercise.category)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.2))
                                            .foregroundColor(.accentColor)
                                            .cornerRadius(4)
                                        
                                        Text(exercise.equipment)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
// ExercisesView is now in its own file
struct InsightsView: View { var body: some View { Text("Insights") } }
struct SettingsView: View { var body: some View { Text("Settings") } }

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            DailyRoutineView()
                .tabItem { Label("Routine", systemImage: "calendar") }
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "list.bullet") }
            ProgramsView()
                .tabItem { Label("Programs", systemImage: "list.bullet.rectangle") }
            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "dumbbell") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, Program.self, BodyMetric.self, DailyRoutine.self, RoutineExercise.self], inMemory: true)
}
