//
//  ContentView.swift
//  FitNotes
//
//  Created by Reed Rawlings on 10/14/25.
//

import SwiftUI
import SwiftData

// MARK: - App State Management
public class AppState: ObservableObject {
    private var _activeWorkout: ActiveWorkoutState?
    @Published var selectedTab: Int = 0
    
    var activeWorkout: ActiveWorkoutState? {
        get {
            guard let workout = _activeWorkout,
                  Calendar.current.isDateInToday(workout.startDate) else {
                _activeWorkout = nil
                UserDefaults.standard.removeObject(forKey: "activeWorkout")
                return nil
            }
            return workout
        }
        set {
            _activeWorkout = newValue
            if let workout = newValue {
                if let data = try? JSONEncoder().encode(workout) {
                    UserDefaults.standard.set(data, forKey: "activeWorkout")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "activeWorkout")
            }
        }
    }
    
    init() {
        // Restore active workout from UserDefaults on app launch
        if let data = UserDefaults.standard.data(forKey: "activeWorkout"),
           let workout = try? JSONDecoder().decode(ActiveWorkoutState.self, from: data) {
            _activeWorkout = workout
        }
    }
    
    func startWorkout(workoutId: UUID, routineId: UUID?, routineName: String, totalExercises: Int) {
        activeWorkout = ActiveWorkoutState(
            workoutId: workoutId,
            routineId: routineId,
            routineName: routineName,
            startDate: Date(),
            completedExercisesCount: 0,
            totalExercisesCount: totalExercises
        )
    }
    
    func updateWorkoutProgress(completedExercises: Int) {
        guard var workout = activeWorkout else { return }
        workout.completedExercisesCount = completedExercises
        activeWorkout = workout
    }
    
    func completeWorkout() {
        activeWorkout = nil
    }
    
    func startWorkoutAndNavigate(workoutId: UUID, routineId: UUID?, routineName: String, totalExercises: Int) {
        startWorkout(workoutId: workoutId, routineId: routineId, routineName: routineName, totalExercises: totalExercises)
        selectedTab = 2 // Switch to Workout tab (index 2)
    }
    
    func continueWorkoutAndNavigate() {
        selectedTab = 2 // Switch to Workout tab (index 2)
    }
}

// MARK: - Active Workout State
public struct ActiveWorkoutState: Codable {
    let workoutId: UUID
    let routineId: UUID?
    let routineName: String
    let startDate: Date
    var completedExercisesCount: Int
    var totalExercisesCount: Int
    
    var progressText: String {
        "\(completedExercisesCount)/\(totalExercisesCount) exercises"
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var expandedRoutineId: UUID?
    @State private var showingRoutineDetail: Routine?
    
    var body: some View {
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
                ScrollView {
                    VStack(spacing: 12) {
                        // Routine cards
                        LazyVStack(spacing: 12) {
                            ForEach(routines) { routine in
                                RoutineCardView(
                                    routine: routine,
                                    isExpanded: expandedRoutineId == routine.id,
                                    isActiveWorkout: appState.activeWorkout != nil,
                                    lastDoneText: RoutineService.shared.getDaysSinceLastUsed(
                                        for: routine,
                                        modelContext: modelContext
                                    ),
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            if expandedRoutineId == routine.id {
                                                expandedRoutineId = nil
                                            } else {
                                                expandedRoutineId = routine.id
                                            }
                                        }
                                    },
                                    onView: {
                                        showingRoutineDetail = routine
                                    },
                                    onStart: {
                                        // Start workout directly from routine
                                        let workout = RoutineService.shared.createWorkoutFromTemplate(
                                            routine: routine,
                                            modelContext: modelContext
                                        )
                                        
                                        appState.startWorkoutAndNavigate(
                                            workoutId: workout.id,
                                            routineId: routine.id,
                                            routineName: routine.name,
                                            totalExercises: routine.exercises.count
                                        )
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 100) // Space for tab bar
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $showingRoutineDetail) { routine in
            RoutineDetailView(routine: routine)
        }
        .onTapGesture {
            // Tap outside to collapse expanded card
            if expandedRoutineId != nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedRoutineId = nil
                }
            }
        }
    }
    
}

// MARK: - UnifiedCardView Component
struct UnifiedCardView: View {
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let onTap: () -> Void
    
    init(title: String, subtitle: String? = nil, showChevron: Bool = false, onTap: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                // Scale down effect on tap
            }
        }
    }
}


// MARK: - RoutineCardView Component (Homepage specific)
struct RoutineCardView: View {
    let routine: Routine
    let isExpanded: Bool
    let isActiveWorkout: Bool
    let lastDoneText: String
    let onTap: () -> Void
    let onView: () -> Void
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if isExpanded {
                    // Expanded state with buttons
                    VStack(spacing: 16) {
                        // Routine name
                            HStack {
                            Text(routine.name)
                                    .font(.headline)
                                .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                        // Action buttons
                        HStack(spacing: 0) {
                            if isActiveWorkout {
                                // Only View button when workout is active
                                Button(action: onView) {
                                    Text("View")
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.accentColor, lineWidth: 2)
                                        )
                                }
                            } else {
                                // View and Start buttons when no active workout
                                Button(action: onView) {
                                    Text("View")
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.accentColor, lineWidth: 2)
                                        )
                                }
                                
                                Button(action: onStart) {
                                    Text("Start")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    } else {
                    // Default state with routine name and last done text
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(lastDoneText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

// MARK: - ActiveWorkoutContentView Component (for inline use)
struct ActiveWorkoutContentView: View {
    let workoutId: UUID
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    
    private var workout: Workout? {
        workouts.first { $0.id == workoutId }
    }
    
    private var sortedExercises: [WorkoutExercise] {
        workout?.exercises.sorted { $0.order < $1.order } ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let workout = workout {
                // Workout Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Started \(workout.date, style: .time)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                Divider()
                
                // Exercises List
                if sortedExercises.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No exercises in this workout")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(sortedExercises, id: \.id) { workoutExercise in
                            ActiveWorkoutExerciseRowView(
                                workoutExercise: workoutExercise,
                                exercise: exercises.first { $0.id == workoutExercise.exerciseId }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: pauseWorkout) {
                        HStack {
                            Image(systemName: "pause.circle")
                            Text("Pause Workout")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Workout not found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func pauseWorkout() {
        // Navigate back to Home tab
        appState.selectedTab = 0
    }
}

// MARK: - ActiveWorkoutView Component (for modal use - keeping for compatibility)
struct ActiveWorkoutView: View {
    let workoutId: UUID
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    
    private var workout: Workout? {
        workouts.first { $0.id == workoutId }
    }
    
    private var sortedExercises: [WorkoutExercise] {
        workout?.exercises.sorted { $0.order < $1.order } ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let workout = workout {
                    // Workout Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Started \(workout.date, style: .time)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    
                    Divider()
                    
                    // Exercises List
                    if sortedExercises.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "dumbbell")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No exercises in this workout")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        List {
                            ForEach(sortedExercises, id: \.id) { workoutExercise in
                                ActiveWorkoutExerciseRowView(
                                    workoutExercise: workoutExercise,
                                    exercise: exercises.first { $0.id == workoutExercise.exerciseId }
                                )
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: pauseWorkout) {
                            HStack {
                                Image(systemName: "pause.circle")
                                Text("Pause Workout")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Workout not found")
                            .font(.headline)
                                .foregroundColor(.secondary)
                        
                        Button("Close") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func pauseWorkout() {
        // Navigate back to Home tab
        appState.selectedTab = 0
        dismiss()
    }
}

struct ActiveWorkoutExerciseRowView: View {
    let workoutExercise: WorkoutExercise
    let exercise: Exercise?
    @Environment(\.modelContext) private var modelContext
    
    private var sortedSets: [WorkoutSet] {
        workoutExercise.sets.sorted { $0.order < $1.order }
    }
    
    private var completedSets: Int {
        sortedSets.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise?.name ?? "Unknown Exercise")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    if !sortedSets.isEmpty {
                        Text("\(completedSets)/\(sortedSets.count) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Show first set as example
                    if let firstSet = sortedSets.first {
                        if firstSet.weight > 0 {
                            Text("\(Int(firstSet.weight)) kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if firstSet.duration != nil {
                            Text("\(firstSet.duration ?? 0) sec")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Progress indicator
            if !sortedSets.isEmpty {
                Text("\(Int(Double(completedSets) / Double(sortedSets.count) * 100))%")
                    .font(.caption)
                    .foregroundColor(completedSets == sortedSets.count ? .green : .secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(completedSets == sortedSets.count ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(8)
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
                if routines.isEmpty {
                    EmptyRoutinesView {
                        showingAddRoutine = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            LazyVStack(spacing: 12) {
                                ForEach(routines) { routine in
                                    UnifiedCardView(
                                        title: routine.name,
                                        subtitle: RoutineService.shared.getDaysSinceLastUsed(
                                            for: routine,
                                            modelContext: modelContext
                                        )
                                    ) {
                                        selectedRoutine = routine
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            Spacer(minLength: 100) // Space for bottom button and tab bar
                        }
                    }
                }
            }
            
            // Fixed bottom button - overlay on top
            VStack {
                Spacer()
                PrimaryActionButton(title: "New Routine") {
                    showingAddRoutine = true
                }
                .padding(.bottom, 8) // Small padding above tab bar
            }
        }
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineView()
        }
        .sheet(item: $selectedRoutine) { routine in
            RoutineDetailView(routine: routine)
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

// MARK: - SettingsView
struct SettingsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control for Settings Sections
                Picker("Settings Section", selection: $selectedTab) {
                    Text("Routines").tag(0)
                    Text("Exercises").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Divider()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    RoutinesView()
                } else {
                    ExercisesView()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct InsightsView: View { 
    var body: some View { 
        Text("Insights") 
    } 
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { 
                    VStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                }
                .tag(0)
            InsightsView()
                .tabItem { 
                    VStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Insights")
                    }
                }
                .tag(1)
            WorkoutView()
                .tabItem { 
                    VStack {
                        Image(systemName: "dumbbell.fill")
                        Text("Workout")
                    }
                }
                .tag(2)
            SettingsView()
                .tabItem { 
                    VStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                }
                .tag(3)
        }
        .accentColor(.blue)
        .environmentObject(appState)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, RoutineExercise.self, Routine.self], inMemory: true)
}
