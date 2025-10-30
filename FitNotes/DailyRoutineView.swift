import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingAddExercise = false
    @State private var selectedDate = Date()
    
    // Track the last workout count to force refresh
    private var workoutCount: Int { workouts.count }
    
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
        NavigationStack {
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
                            .id(workout.id) // Force refresh when workout changes
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
    @State private var editMode: EditMode = .inactive
    
    private var sortedExercises: [WorkoutExercise] {
        workout.exercises.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if sortedExercises.isEmpty {
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
                    List {
                        ForEach(sortedExercises, id: \.id) { workoutExercise in
                            WorkoutExerciseRowView(workoutExercise: workoutExercise, workout: workout)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                        }
                        .onMove { indices, newOffset in
                            WorkoutService.shared.reorderExercises(
                                workout: workout,
                                from: indices,
                                to: newOffset,
                                modelContext: modelContext
                            )
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, .constant(.active))
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
    
    private var exercise: Exercise? {
        exercises.first { $0.id == workoutExercise.exerciseId }
    }
    
    private var sortedSets: [WorkoutSet] {
        let exerciseSets = allSets.filter { 
            $0.exerciseId == workoutExercise.exerciseId && 
            Calendar.current.isDate($0.date, inSameDayAs: workout.date)
        }
        return exerciseSets.sorted { $0.order < $1.order }
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
                ExerciseDetailView(exercise: exercise, shouldDismissOnSave: true)
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
    @State private var selectedMuscleGroup: String = ""
    @State private var selectedEquipment: String = ""
    @State private var showingDuplicateAlert = false
    @State private var duplicateExerciseName = ""
    @State private var selectedIds: Set<UUID> = []
    
    private var filteredExercises: [Exercise] {
        ExerciseSearchService.shared.searchExercises(
            query: searchText,
            category: selectedMuscleGroup.isEmpty ? nil : selectedMuscleGroup,
            equipment: selectedEquipment.isEmpty ? nil : selectedEquipment,
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
                
                // Filters
                VStack(spacing: 8) {
                    // Equipment chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ExerciseDatabaseService.equipmentTypes, id: \.self) { equipment in
                                Button(action: {
                                    selectedEquipment = selectedEquipment == equipment ? "" : equipment
                                }) {
                                    Text(equipment)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedEquipment == equipment ? Color.accentPrimary : Color.tertiaryBg)
                                        .foregroundColor(selectedEquipment == equipment ? .textInverse : .textPrimary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    // Muscle group chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            let groups = Array(Set(exercises.map { $0.primaryCategory })).sorted()
                            ForEach(groups, id: \.self) { group in
                                Button(action: {
                                    selectedMuscleGroup = selectedMuscleGroup == group ? "" : group
                                }) {
                                    Text(group)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedMuscleGroup == group ? Color.accentPrimary : Color.tertiaryBg)
                                        .foregroundColor(selectedMuscleGroup == group ? .textInverse : .textPrimary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            
            // Exercise List with multi-select support
            ExerciseListView(
                exercises: filteredExercises,
                searchText: $searchText,
                onExerciseSelected: { exercise in
                    // Fallback single add (should not trigger when selectedIds is provided)
                    addExercises(selected: [exercise.id])
                },
                context: .picker,
                selectedIds: $selectedIds
            )
        }
        // Fixed CTA at bottom (overlayed, not affecting list layout)
        FixedModalCTAButton(
            title: selectedIds.isEmpty ? "Select exercises" : "Add \(selectedIds.count) Exercise\(selectedIds.count == 1 ? "" : "s")",
            icon: "checkmark",
            isEnabled: !selectedIds.isEmpty,
            action: {
                addExercises(selected: Array(selectedIds))
            }
        )
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
        .onAppear {
            // Ensure the exercise library is seeded the first time this view is opened
            if exercises.isEmpty {
                ExerciseDatabaseService.shared.createDefaultExercises(modelContext: modelContext)
            }
        }
    }
    
    private func addExercises(selected: [UUID]) {
        // Fetch or create workout for selectedDate
        let targetWorkout: Workout
        if let existing = workout {
            targetWorkout = existing
        } else {
            targetWorkout = WorkoutService.shared.createWorkout(
                name: "Workout - \(selectedDate.formatted(date: .abbreviated, time: .omitted))",
                date: selectedDate,
                modelContext: modelContext
            )
        }
        
        // Add each selected exercise, skipping duplicates
        for exerciseId in selected {
            if WorkoutService.shared.exerciseExistsInWorkout(workout: targetWorkout, exerciseId: exerciseId) {
                continue
            }
            _ = WorkoutService.shared.addExerciseToWorkout(
                workout: targetWorkout,
                exerciseId: exerciseId,
                sets: 0,
                reps: nil,
                weight: nil,
                duration: nil,
                distance: nil,
                notes: nil,
                modelContext: modelContext
            )
        }
        
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
        ZStack {
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Text("Use Template")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.accentPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()
                
                // Content
                if routines.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No routine templates",
                        subtitle: "Create routine templates in the Routines tab first",
                        actionTitle: nil,
                        onAction: nil
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(routines) { routine in
                                RoutineTemplateCardView(routine: routine) {
                                    useRoutineTemplate(routine)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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

// MARK: - RoutineTemplateCardView
struct RoutineTemplateCardView: View {
    let routine: Routine
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                if let description = routine.routineDescription, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                Text("\(routine.exercises.count) exercises")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentPrimary, Color.accentSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.accentPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, WorkoutSet.self, RoutineExercise.self, Routine.self], inMemory: true)
}