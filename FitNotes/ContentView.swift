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
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(workout.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !workout.exercises.isEmpty {
                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if workout.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
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
    
    @State private var name = ""
    @State private var selectedDate = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Workout Details") {
                    TextField("Workout Name", text: $name)
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
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
                    Button("Create") {
                        createWorkout()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createWorkout() {
        _ = WorkoutService.shared.createWorkout(
            name: name,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes,
            modelContext: modelContext
        )
        
        dismiss()
    }
}

// WorkoutExercise and WorkoutExerciseRowView are now in DailyRoutineView.swift

// AddExerciseToWorkoutView is now in DailyRoutineView.swift

// MARK: - RoutinesView
struct RoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var showingAddRoutine = false
    @State private var selectedRoutine: Routine?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if routines.isEmpty {
                    EmptyRoutinesView {
                        showingAddRoutine = true
                    }
                } else {
                    List {
                        ForEach(routines) { routine in
                            RoutineRowView(routine: routine) {
                                selectedRoutine = routine
                            }
                        }
                        .onDelete(perform: deleteRoutines)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRoutine = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineView()
        }
        .sheet(item: $selectedRoutine) { routine in
            RoutineDetailView(routine: routine)
        }
    }
    
    private func deleteRoutines(offsets: IndexSet) {
        for index in offsets {
            let routine = routines[index]
            RoutineService.shared.deleteRoutine(routine: routine, modelContext: modelContext)
        }
    }
}

struct RoutineRowView: View {
    let routine: Routine
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = routine.routineDescription, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("\(routine.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyRoutinesView: View {
    let onCreateRoutine: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No routines yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Create reusable exercise routines that you can easily add to any day")
                        .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onCreateRoutine) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Routine")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - AddRoutineView
struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Routine Details") {
                    TextField("Routine Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createRoutine()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createRoutine() {
        _ = RoutineService.shared.createRoutine(
            name: name,
            description: description.isEmpty ? nil : description,
            modelContext: modelContext
        )
        
        dismiss()
    }
}

// MARK: - RoutineDetailView
struct RoutineDetailView: View {
    let routine: Routine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @State private var showingAddExercise = false
    
    private var sortedExercises: [RoutineExercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Routine Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(routine.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let description = routine.routineDescription, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                Divider()
                
                // Exercises Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Exercises")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddExercise = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Exercise")
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    if routine.exercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            
                            Text("No exercises added")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Add exercises to build your routine")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        List {
                            ForEach(sortedExercises, id: \.id) { routineExercise in
                                RoutineTemplateExerciseRowView(routineExercise: routineExercise)
                            }
                            .onDelete(perform: deleteExercises)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Routine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToRoutineTemplateView(routine: routine)
        }
    }
    
    private func deleteExercises(offsets: IndexSet) {
        for index in offsets {
            let exercise = sortedExercises[index]
            RoutineService.shared.removeExerciseFromRoutine(
                routineExercise: exercise,
                modelContext: modelContext
            )
        }
    }
}

struct RoutineTemplateExerciseRowView: View {
    let routineExercise: RoutineExercise
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    
    private var exercise: Exercise? {
        exercises.first { $0.id == routineExercise.exerciseId }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise?.name ?? "Unknown Exercise")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    if routineExercise.sets > 0 {
                        Text("\(routineExercise.sets) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let reps = routineExercise.reps {
                        Text("\(reps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let weight = routineExercise.weight {
                        Text("\(Int(weight)) kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let duration = routineExercise.duration {
                        Text("\(duration) sec")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: {
                RoutineService.shared.removeExerciseFromRoutine(
                    routineExercise: routineExercise,
                    modelContext: modelContext
                )
            }) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AddExerciseToRoutineTemplateView
struct AddExerciseToRoutineTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let routine: Routine
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @State private var sets = 1
    @State private var reps = 10
    @State private var weight: Double = 0
    @State private var notes = ""
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                .padding()
                
                if let exercise = selectedExercise {
                    // Exercise Details Form
                    Form {
                        Section("Exercise") {
                            HStack {
                                Text(exercise.name)
                                    .font(.headline)
                                Spacer()
                                Text(exercise.category)
                                        .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.2))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Section("Workout Details") {
                            Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                            
                            if exercise.type == "Strength" {
                                Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                                Stepper("Weight: \(Int(weight)) kg", value: $weight, in: 0...500, step: 1)
                            } else if exercise.type == "Cardio" {
                                Stepper("Duration: \(sets * 60) sec", value: $sets, in: 1...60)
                            }
                        }
                        
                        Section("Notes") {
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(2...4)
                        }
                    }
                } else {
                    // Exercise List
                    List(filteredExercises) { exercise in
                        Button(action: {
                            selectedExercise = exercise
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 8) {
                                        Text(exercise.category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(exercise.equipment)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(selectedExercise == nil ? "Add Exercise" : "Configure Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(selectedExercise == nil ? "Cancel" : "Back") {
                        if selectedExercise != nil {
                            selectedExercise = nil
                        } else {
                            dismiss()
                        }
                    }
                }
                
                if selectedExercise != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add") {
                            addExercise()
                        }
                    }
                }
            }
        }
    }
    
    private func addExercise() {
        guard let exercise = selectedExercise else { return }
        
        _ = RoutineService.shared.addExerciseToRoutine(
            routine: routine,
            exerciseId: exercise.id,
            sets: sets,
            reps: exercise.type == "Strength" ? reps : nil,
            weight: exercise.type == "Strength" ? weight : nil,
            duration: exercise.type == "Cardio" ? sets * 60 : nil,
            notes: notes.isEmpty ? nil : notes,
            modelContext: modelContext
        )
        
        dismiss()
    }
}

// ExercisesView is now in its own file
struct InsightsView: View { var body: some View { Text("Insights") } }
struct SettingsView: View { var body: some View { Text("Settings") } }

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                WorkoutView()
                    .tabItem { Label("Today", systemImage: "calendar") }
            RoutinesView()
                .tabItem { Label("Routines", systemImage: "list.bullet") }
            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "dumbbell") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, Program.self, BodyMetric.self, WorkoutExercise.self, RoutineExercise.self, Routine.self], inMemory: true)
}
