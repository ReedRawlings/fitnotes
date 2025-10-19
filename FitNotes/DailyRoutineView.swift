import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingAddExercise = false
    @State private var selectedDate = Date()
    
    var todaysWorkout: Workout? {
        let calendar = Calendar.current
        return workouts.first { workout in
            calendar.isDate(workout.date, inSameDayAs: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Blue gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.blue.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Show active workout if it exists and we're viewing today
                    if let activeWorkout = appState.activeWorkout,
                       Calendar.current.isDateInToday(selectedDate) {
                        ActiveWorkoutContentView(workoutId: activeWorkout.workoutId)
                    } else {
                        // Date Picker
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                        
                        Divider()
                        
                        if let workout = getWorkoutForDate(selectedDate) {
                            WorkoutDetailView(workout: workout)
                        } else {
                            EmptyWorkoutView(selectedDate: selectedDate) {
                                showingAddExercise = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout")
            .toolbar {
                if appState.activeWorkout == nil || !Calendar.current.isDateInToday(selectedDate) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddExercise = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToWorkoutView(selectedDate: selectedDate)
        }
    }
    
    private func getWorkoutForDate(_ date: Date) -> Workout? {
        let calendar = Calendar.current
        return workouts.first { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }
}

// MARK: - WorkoutDetailView
struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddExercise = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Minimal Header
                HStack {
                    Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Exercises Section
                if workout.exercises.isEmpty {
                    EmptyStateView(
                        icon: "dumbbell",
                        title: "No exercises in this workout",
                        subtitle: "Add exercises to get started"
                    )
                    .padding(.horizontal)
                } else {
                    CardListView(workout.exercises.sorted { $0.order < $1.order }) { workoutExercise in
                        WorkoutExerciseRowView(workoutExercise: workoutExercise)
                    }
                }
                
                Spacer(minLength: 20)
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToWorkoutView(selectedDate: workout.date, workout: workout)
        }
    }
}

struct WorkoutExerciseRowView: View {
    let workoutExercise: WorkoutExercise
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    
    private var exercise: Exercise? {
        exercises.first { $0.id == workoutExercise.exerciseId }
    }
    
    private var sortedSets: [WorkoutSet] {
        workoutExercise.sets.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        BaseCardView {
            VStack(alignment: .leading, spacing: 8) {
                // Exercise name and delete button
                HStack {
                    Text(exercise?.name ?? "Unknown Exercise")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: { deleteExercise() }) {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                
                // Divider line
                Divider()
                
                // Individual sets
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sortedSets, id: \.id) { set in
                        HStack(spacing: 0) {
                            // Weight
                            Text("\(Int(set.weight)).0 kg")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                                .frame(minWidth: 16)
                            
                            // Separator
                            Text("×")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                                .frame(minWidth: 16)
                            
                            // Reps
                            Text("\(set.reps) reps")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func deleteExercise() {
        if let workout = workoutExercise.workout {
            WorkoutService.shared.removeExerciseFromWorkout(
                workoutExercise: workoutExercise,
                modelContext: modelContext
            )
        }
    }
}

struct EmptyWorkoutView: View {
    let selectedDate: Date
    let onAddExercise: () -> Void
    @State private var showingRoutineTemplates = false
    
    var body: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                icon: "dumbbell",
                title: "No workout for this day",
                subtitle: "Start a workout from the Home tab or add exercises manually",
                actionTitle: "Add Exercise",
                onAction: onAddExercise
            )
            
            SecondaryActionButton(
                title: "Use Routine Template",
                icon: "list.bullet.rectangle",
                onTap: { showingRoutineTemplates = true }
            )
        }
        .padding()
        .sheet(isPresented: $showingRoutineTemplates) {
            RoutineTemplateSelectorView(selectedDate: selectedDate)
        }
    }
}

// MARK: - AddExerciseToWorkoutView
struct AddExerciseToWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let selectedDate: Date
    var workout: Workout?
    
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @State private var numberOfSets = 1
    @State private var setData: [(reps: Int, weight: Double, duration: Int?, distance: Double?)] = []
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
                        
                        Section("Number of Sets") {
                            Stepper("Sets: \(numberOfSets)", value: $numberOfSets, in: 1...20)
                                .onChange(of: numberOfSets) { _, newValue in
                                    updateSetData(for: exercise, newCount: newValue)
                                }
                        }
                        
                        Section("Set Details") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(0..<numberOfSets, id: \.self) { index in
                                    HStack(spacing: 12) {
                                        Text("Set \(index + 1)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .frame(width: 50, alignment: .leading)
                                        
                                        if exercise.type == "Strength" {
                                            TextField("Reps", value: $setData[index].reps, format: .number)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .frame(width: 60)
                                            
                                            Text("×")
                                                .foregroundColor(.secondary)
                                            
                                            TextField("Weight", value: $setData[index].weight, format: .number)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .frame(width: 80)
                                            
                                            Text("kg")
                                                .foregroundColor(.secondary)
                                        } else if exercise.type == "Cardio" {
                                            TextField("Duration", value: $setData[index].duration, format: .number)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .frame(width: 80)
                                            
                                            Text("sec")
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
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
                            initializeSetData(for: exercise)
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
    
    private func initializeSetData(for exercise: Exercise) {
        setData = []
        for _ in 0..<numberOfSets {
            if exercise.type == "Strength" {
                setData.append((reps: 10, weight: 0, duration: nil, distance: nil))
            } else if exercise.type == "Cardio" {
                setData.append((reps: 0, weight: 0, duration: 60, distance: nil))
            } else {
                setData.append((reps: 0, weight: 0, duration: nil, distance: nil))
            }
        }
    }
    
    private func updateSetData(for exercise: Exercise, newCount: Int) {
        if newCount > setData.count {
            // Add new sets
            for _ in setData.count..<newCount {
                if exercise.type == "Strength" {
                    setData.append((reps: 10, weight: 0, duration: nil, distance: nil))
                } else if exercise.type == "Cardio" {
                    setData.append((reps: 0, weight: 0, duration: 60, distance: nil))
                } else {
                    setData.append((reps: 0, weight: 0, duration: nil, distance: nil))
                }
            }
        } else {
            // Remove excess sets
            setData.removeLast(setData.count - newCount)
        }
    }
    
    private func addExercise() {
        guard let exercise = selectedExercise else { return }
        
        // Create workout if it doesn't exist
        let currentWorkout: Workout
        if let existingWorkout = workout {
            currentWorkout = existingWorkout
        } else {
            currentWorkout = WorkoutService.shared.createWorkout(
                name: "Workout - \(selectedDate.formatted(date: .abbreviated, time: .omitted))",
                date: selectedDate,
                modelContext: modelContext
            )
        }
        
        _ = WorkoutService.shared.addExerciseToWorkoutWithSets(
            workout: currentWorkout,
            exerciseId: exercise.id,
            setData: setData,
            notes: notes.isEmpty ? nil : notes,
            modelContext: modelContext
        )
        
        dismiss()
    }
}

// MARK: - RoutineTemplateSelectorView
struct RoutineTemplateSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]
    
    let selectedDate: Date
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if routines.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("No routine templates")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("Create routine templates in the Routines tab first")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    List(routines) { routine in
                        Button(action: {
                            useRoutineTemplate(routine)
                        }) {
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
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Use Template")
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
    
    private func useRoutineTemplate(_ routine: Routine) {
        _ = RoutineService.shared.createWorkoutFromTemplate(
            routine: routine,
            date: selectedDate,
            modelContext: modelContext
        )
        
        dismiss()
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, WorkoutSet.self, RoutineExercise.self, Routine.self], inMemory: true)
}