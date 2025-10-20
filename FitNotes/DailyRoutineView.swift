import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingAddExercise = false
    @State private var selectedDate = Date()
    
    var displayDate: Date {
        if let activeWorkout = appState.activeWorkout {
            return activeWorkout.startDate
        } else {
            return selectedDate
        }
    }
    
    var addExerciseButtonLabel: String {
        if getWorkoutForDate(selectedDate) != nil {
            return "Add Exercise"
        } else {
            return "Start New Workout"
        }
    }
    
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
                    // Date header
                    HStack {
                        if Calendar.current.isDateInToday(displayDate) {
                            Text("Today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 12) {
                                Button(action: { goToPreviousDay() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(displayDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { goToNextDay() }) {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    Divider()
                    
                    // Always use the same view for workouts
                    if let workout = getWorkoutForDate(displayDate) {
                        WorkoutDetailView(workout: workout)
                    } else {
                        EmptyWorkoutView(selectedDate: displayDate) {
                            showingAddExercise = true
                        }
                    }
                    
                    Spacer()
                    
                    // Prominent Add Exercise button at bottom - always show
                    PrimaryActionButton(title: addExerciseButtonLabel, icon: "plus") {
                        showingAddExercise = true
                    }
                    .padding(.bottom, 8) // Small padding above tab bar
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddExercise) {
            if let workout = getWorkoutForDate(displayDate) {
                // Workout exists - add exercises to it
                AddExerciseToWorkoutView(selectedDate: displayDate, workout: workout)
            } else {
                // No workout - create new one
                AddExerciseToWorkoutView(selectedDate: displayDate, workout: nil)
            }
        }
        .onAppear {
            // If active workout exists, set selectedDate to active workout's date
            if let activeWorkout = appState.activeWorkout {
                selectedDate = activeWorkout.startDate
            } else {
                selectedDate = Date()
            }
        }
    }
    
    private func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
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
    @State private var selectedExercise: WorkoutExercise?
    @State private var showingEditExercise = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if workout.exercises.isEmpty {
                    EmptyStateView(
                        icon: "dumbbell",
                        title: "No exercises",
                        subtitle: "Add exercises to get started",
                        actionTitle: nil,
                        onAction: nil
                    )
                    .padding(.horizontal)
                } else {
                    CardListView(workout.exercises.sorted { $0.order < $1.order }) { workoutExercise in
                        WorkoutExerciseRowView(workoutExercise: workoutExercise, workout: workout)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToWorkoutView(selectedDate: workout.date, workout: workout)
        }
    }
}

struct WorkoutExerciseRowView: View {
    let workoutExercise: WorkoutExercise
    let workout: Workout
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
                // Header with delete
                HStack {
                    Text(exercise?.name ?? "Unknown Exercise")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { deleteExercise() }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Divider()
                
                // Sets list
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sortedSets, id: \.id) { set in
                        HStack(spacing: 0) {
                            if set.weight > 0 {
                                Text("\(Int(set.weight)) kg")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                    .frame(minWidth: 16)
                                
                                Text("×")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                    .frame(minWidth: 16)
                                
                                Text("\(set.reps) reps")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            } else if let duration = set.duration {
                                Text("\(duration) sec")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            } else {
                                Text("\(set.reps) reps")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(12)
        }
        .onTapGesture {
            // Navigate to edit view when card is tapped (but not when delete button is tapped)
        }
    }
    
    private func deleteExercise() {
        print("Attempting to delete exercise: \(exercise?.name ?? "Unknown")")
        WorkoutService.shared.removeExerciseFromWorkout(
            workoutExercise: workoutExercise,
            modelContext: modelContext
        )
        print("Delete operation completed")
    }
}

// MARK: - EditWorkoutExerciseView
struct EditWorkoutExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    
    let workoutExercise: WorkoutExercise
    let workout: Workout
    
    @State private var showingHistory = false
    
    private var exercise: Exercise? {
        exercises.first { $0.id == workoutExercise.exerciseId }
    }
    
    private var sortedSets: [WorkoutSet] {
        workoutExercise.sets.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Exercise name header with history button
                    HStack {
                        Text(exercise?.name ?? "Unknown Exercise")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { showingHistory = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("View History")
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sets editor
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sets")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, set in
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Text("Set \(index + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        TextField("Weight", value: Binding(
                                            get: { set.weight },
                                            set: { newValue in
                                                if let idx = workoutExercise.sets.firstIndex(where: { $0.id == set.id }) {
                                                    workoutExercise.sets[idx].weight = newValue
                                                    workoutExercise.sets[idx].updatedAt = Date()
                                                }
                                            }
                                        ), format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 60)
                                        
                                        Text("kg")
                                            .foregroundColor(.secondary)
                                        
                                        TextField("Reps", value: Binding(
                                            get: { set.reps },
                                            set: { newValue in
                                                if let idx = workoutExercise.sets.firstIndex(where: { $0.id == set.id }) {
                                                    workoutExercise.sets[idx].reps = newValue
                                                    workoutExercise.sets[idx].updatedAt = Date()
                                                }
                                            }
                                        ), format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 60)
                                        
                                        Text("reps")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Button(action: { deleteSet(set) }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Remove set")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        Button(action: { addNewSet() }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Set")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveChanges()
                    }
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            if let exercise = exercise {
                ExerciseHistoryView(exercise: exercise)
            }
        }
    }
    
    private func addNewSet() {
        let newOrder = (workoutExercise.sets.map { $0.order }.max() ?? 0) + 1
        let newSet = WorkoutSet(
            exerciseId: workoutExercise.exerciseId,
            workoutId: workout.id,
            order: newOrder,
            reps: 10,
            weight: 0,
            date: workout.date
        )
        workoutExercise.sets.append(newSet)
        modelContext.insert(newSet)
        try? modelContext.save()
    }
    
    private func deleteSet(_ set: WorkoutSet) {
        workoutExercise.sets.removeAll { $0.id == set.id }
        try? modelContext.save()
    }
    
    private func saveChanges() {
        try? modelContext.save()
        dismiss()
    }
}

struct EmptyWorkoutView: View {
    let selectedDate: Date
    let onAddExercise: () -> Void
    @State private var showingRoutineTemplates = false
    
    var body: some View {
        VStack(spacing: 24) {
            EmptyStateView(
                icon: "dumbbell",
                title: "No workout for this day",
                subtitle: "Choose how to get started",
                actionTitle: nil,
                onAction: nil
            )
            
            VStack(spacing: 12) {
                // Option 1: Manual
                Button(action: { onAddExercise() }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Exercises")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Option 2: Template
                Button(action: { showingRoutineTemplates = true }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Use Routine Template")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
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
        ExerciseSearchService.shared.searchExercises(
            query: searchText,
            category: nil,
            exercises: exercises
        )
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
                    ExerciseListView(
                        exercises: filteredExercises,
                        searchText: $searchText,
                        onExerciseSelected: { exercise in
                            selectedExercise = exercise
                            initializeSetData(for: exercise)
                        },
                        context: .picker
                    )
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
        
        // Try to get last session data for this exercise
        if let lastSession = ExerciseService.shared.getLastSessionForExercise(
            exerciseId: exercise.id,
            modelContext: modelContext
        ) {
            // Pre-populate with last session data
            numberOfSets = lastSession.count
            for set in lastSession {
                setData.append((
                    reps: set.reps,
                    weight: set.weight,
                    duration: set.duration,
                    distance: set.distance
                ))
            }
        } else {
            // No history found, use defaults
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
        
        // Fetch or create workout for selectedDate
        let targetWorkout: Workout
        if let existing = workout {
            targetWorkout = existing
        } else {
            // Create new workout for selectedDate
            targetWorkout = WorkoutService.shared.createWorkout(
                name: "Workout - \(selectedDate.formatted(date: .abbreviated, time: .omitted))",
                date: selectedDate,
                modelContext: modelContext
            )
        }
        
        // Add exercise to that workout
        _ = WorkoutService.shared.addExerciseToWorkoutWithSets(
            workout: targetWorkout,
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