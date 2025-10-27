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
    
    var todaysWorkout: Workout? {
        let calendar = Calendar.current
        return workouts.first { workout in
            calendar.isDate(workout.date, inSameDayAs: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark theme background
                Color.primaryBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Date header
                    HStack {
                        if Calendar.current.isDateInToday(displayDate) {
                            Text("Today")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        } else {
                            HStack(spacing: 12) {
                                Button(action: { goToPreviousDay() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Text(displayDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                Button(action: { goToNextDay() }) {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    Divider()
                    
                    // Always use the same view for workouts
                    if let workout = getWorkoutForDate(displayDate) {
                        WorkoutDetailView(workout: workout)
                    } else {
                        EmptyWorkoutView(selectedDate: displayDate)
                    }
                    
                    Spacer()
                    
                    // V2 Gradient Add Exercise button
                    PrimaryActionButton(title: "Add Exercise") {
                        showingAddExercise = true
                    }
                    .padding(.bottom, 20) // 20pt from safe area
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
    @State private var showingRoutineTemplates = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if workout.exercises.isEmpty {
                    VStack(spacing: 24) {
                        EmptyStateView(
                            icon: "dumbbell",
                            title: "No exercises",
                            subtitle: "Choose how to get started",
                            actionTitle: nil,
                            onAction: nil
                        )
                        
                        VStack(spacing: 12) {
                            // Use Routine Template button
                            Button(action: { showingRoutineTemplates = true }) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                    Text("Use Routine Template")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondaryBg)
                                .foregroundColor(.textPrimary)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                } else {
                    CardListView(workout.exercises.sorted { $0.order < $1.order }) { workoutExercise in
                        WorkoutExerciseRowView(workoutExercise: workoutExercise, workout: workout)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .sheet(isPresented: $showingRoutineTemplates) {
            RoutineTemplateSelectorView(selectedDate: workout.date, existingWorkout: workout)
        }
    }
}

struct WorkoutExerciseRowView: View {
    let workoutExercise: WorkoutExercise
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var exercises: [Exercise]
    @Query private var allSets: [WorkoutSet]
    
    @State private var showingExerciseDetail = false
    @State private var cachedSets: [WorkoutSet] = []
    
    private var exercise: Exercise? {
        exercises.first { $0.id == workoutExercise.exerciseId }
    }
    
    private var sortedSets: [WorkoutSet] {
        if cachedSets.isEmpty {
            let exerciseSets = allSets.filter { 
                $0.exerciseId == workoutExercise.exerciseId && 
                Calendar.current.isDate($0.date, inSameDayAs: workout.date)
            }
            cachedSets = exerciseSets.sorted { $0.order < $1.order }
        }
        return cachedSets
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header with exercise name and delete
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise?.name ?? "Unknown Exercise")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    // Set history - grid layout (2 columns)
                    if !sortedSets.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), alignment: .leading),
                            GridItem(.flexible(), alignment: .leading)
                        ], spacing: 8) {
                            ForEach(sortedSets, id: \.id) { set in
                                Text("\(set.reps)×\(Int(set.weight)) \(appState.weightUnit)")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                    
                Spacer()
                
                Button(action: { deleteExercise() }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.errorRed)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .cardStyle()
        .onTapGesture {
            showingExerciseDetail = true
        }
        .sheet(isPresented: $showingExerciseDetail) {
            if let exercise = exercise {
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
    
    private func deleteExercise() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Attempting to delete exercise: \(exercise?.name ?? "Unknown")")
        
        withAnimation(.deleteAnimation) {
            WorkoutService.shared.removeExerciseFromWorkout(
                workoutExercise: workoutExercise,
                modelContext: modelContext
            )
        }
        print("Delete operation completed")
    }
}

struct EmptyWorkoutView: View {
    let selectedDate: Date
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
                // Use Routine Template button
                Button(action: { showingRoutineTemplates = true }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Use Routine Template")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryBg)
                    .foregroundColor(.textPrimary)
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
    @State private var showingDuplicateAlert = false
    @State private var duplicateExerciseName = ""
    
    private var filteredExercises: [Exercise] {
        ExerciseSearchService.shared.searchExercises(
            query: searchText,
            category: nil,
            equipment: nil,
            exercises: exercises
        )
    }
    
    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    TextField("Search exercises...", text: $searchText)
                        .foregroundColor(.textPrimary)
                        .padding(8)
                        .background(Color.tertiaryBg)
                        .cornerRadius(10)
                }
                .padding()
            
            // Exercise List - simplified to single-step selection
            ExerciseListView(
                exercises: filteredExercises,
                searchText: $searchText,
                onExerciseSelected: { exercise in
                    addExerciseImmediately(exercise)
                },
                context: .picker
            )
        }
        .navigationTitle("Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
        }
        .alert("Exercise already exists", isPresented: $showingDuplicateAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(duplicateExerciseName) is already in this workout.")
        }
    }
    
    private func addExerciseImmediately(_ exercise: Exercise) {
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
        
        // Check if exercise already exists in workout
        if WorkoutService.shared.exerciseExistsInWorkout(workout: targetWorkout, exerciseId: exercise.id) {
            duplicateExerciseName = exercise.name
            showingDuplicateAlert = true
            return
        }
        
        // Try to get last session data for this exercise
        var setData: [(reps: Int, weight: Double, duration: Int?, distance: Double?)] = []
        
        if let lastSession = ExerciseService.shared.getLastSessionForExercise(
            exerciseId: exercise.id,
            modelContext: modelContext
        ) {
            // Pre-populate with last session data
            for set in lastSession {
                setData.append((
                    reps: set.reps,
                    weight: set.weight,
                    duration: set.duration,
                    distance: set.distance
                ))
            }
        } else {
            // No history found, use sensible defaults based on equipment type
            if exercise.equipment == "Body" || exercise.category == "Cardio" {
                setData.append((reps: 0, weight: 0, duration: 60, distance: nil))
            } else {
                setData.append((reps: 10, weight: 0, duration: nil, distance: nil))
            }
        }
        
        // Add exercise to workout with the prepared set data
        _ = WorkoutService.shared.addExerciseToWorkoutWithSets(
            workout: targetWorkout,
            exerciseId: exercise.id,
            setData: setData,
            notes: nil, // No notes on initial add - user can add them in workout view
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
    let existingWorkout: Workout?
    
    init(selectedDate: Date, existingWorkout: Workout? = nil) {
        self.selectedDate = selectedDate
        self.existingWorkout = existingWorkout
    }
    
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
        if let existingWorkout = existingWorkout {
            // Add exercises to existing workout
            _ = RoutineService.shared.addExercisesFromRoutineToWorkout(
                workout: existingWorkout,
                routine: routine,
                modelContext: modelContext
            )
        } else {
            // Create new workout
            _ = RoutineService.shared.createWorkoutFromTemplate(
                routine: routine,
                date: selectedDate,
                modelContext: modelContext
            )
        }
        
        dismiss()
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, WorkoutSet.self, RoutineExercise.self, Routine.self], inMemory: true)
}