//
//  ContentView.swift
//  FitNotes
//
//  Created by Reed Rawlings on 10/14/25.
//

import SwiftUI
import SwiftData

// MARK: - UIColor Extension for Hex
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

// MARK: - App State Management
public class AppState: ObservableObject {
    private var _activeWorkout: ActiveWorkoutState?
    @Published var selectedTab: Int = 0
    @Published var weightUnit: String = "kg" // Global unit preference for set history display
    
    var activeWorkout: ActiveWorkoutState? {
        get {
            guard let workout = _activeWorkout,
                  Calendar.current.isDateInToday(workout.startDate) else {
                _activeWorkout = nil
                return nil
            }
            return workout
        }
        set {
            _activeWorkout = newValue
        }
    }
    
    init() {
        // Start with no active workout
        // WorkoutView or HomeView will set this on app launch if needed
        _activeWorkout = nil
    }
    
    func startWorkout(workoutId: UUID, routineId: UUID?, totalExercises: Int) {
        activeWorkout = ActiveWorkoutState(
            workoutId: workoutId,
            routineId: routineId,
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
    
    func startWorkoutAndNavigate(workoutId: UUID, routineId: UUID?, totalExercises: Int) {
        startWorkout(workoutId: workoutId, routineId: routineId, totalExercises: totalExercises)
        selectedTab = 2 // Switch to Workout tab (index 2)
    }
    
    func continueWorkoutAndNavigate() {
        selectedTab = 2 // Switch to Workout tab (index 2)
    }
    
    func syncActiveWorkoutFromSwiftData(modelContext: ModelContext) {
        // Query SwiftData for today's workout
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.date >= today && workout.date < tomorrow
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            if let activeWorkout = workouts.first {
                // Set active workout state
                self.activeWorkout = ActiveWorkoutState(
                    workoutId: activeWorkout.id,
                    routineId: activeWorkout.routineTemplateId,
                    startDate: activeWorkout.date,
                    completedExercisesCount: 0, // This could be calculated from completed sets
                    totalExercisesCount: activeWorkout.exercises.count
                )
            }
        } catch {
            print("Error syncing active workout from SwiftData: \(error)")
        }
    }
}

// MARK: - Active Workout State
public struct ActiveWorkoutState: Codable {
    let workoutId: UUID
    let routineId: UUID?
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
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        // Routine cards
                        LazyVStack(spacing: 0) {
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
                                            totalExercises: routine.exercises.count
                                        )
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        Spacer(minLength: 100) // Space for tab bar
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $showingRoutineDetail) { routine in
            RoutineDetailView(routine: routine)
                .onAppear {
                    // Fix for RTIInputSystemClient error - dismiss any active text input before showing routine detail
                    DispatchQueue.main.async {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
        }
        .onTapGesture {
            // Tap outside to collapse expanded card
            if expandedRoutineId != nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedRoutineId = nil
                }
            }
        }
        .onAppear {
            // Fix for RTIInputSystemClient error - dismiss any active text input
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                        .foregroundColor(.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
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
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            
                        // Action buttons
                        HStack(spacing: 12) {
                            if isActiveWorkout {
                                // Only View button when workout is active
                                Button(action: onView) {
                                    Text("View")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(.accentPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.secondaryBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
                                        )
                                }
                            } else {
                                // View and Start buttons when no active workout
                                Button(action: onView) {
                                    Text("View")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(.accentPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.secondaryBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
                                        )
                                }
                                
                                Button(action: onStart) {
                                    Text("Start")
                                        .font(.buttonFont)
                                        .foregroundColor(.textInverse)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            LinearGradient(
                                                colors: [.accentPrimary, .accentSecondary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .shadow(
                                            color: .accentPrimary.opacity(0.3),
                                            radius: 12,
                                            x: 0,
                                            y: 4
                                        )
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
                                .foregroundColor(.textPrimary)
                            
                            Text(lastDoneText)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}


// MARK: - RoutinesView
struct RoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var showingAddRoutine = false
    @State private var selectedRoutine: Routine?
    
    var body: some View {
        ZStack {
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if routines.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No routines yet",
                        subtitle: "Create reusable exercise routines that you can easily add to any day",
                        actionTitle: "New Routine",
                        onAction: {
                            showingAddRoutine = true
                        }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            LazyVStack(spacing: 0) {
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
                            .padding(.top, 12)
                            
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




// MARK: - AddRoutineView
struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()
                
                Form {
                    Section("Routine Details") {
                        TextField("Routine Name", text: $name)
                            .foregroundColor(.textPrimary)
                        TextField("Description (optional)", text: $description, axis: .vertical)
                            .foregroundColor(.textPrimary)
                            .lineLimit(3...6)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createRoutine()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? .textTertiary : .accentPrimary)
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
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Routine Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(routine.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        if let description = routine.routineDescription, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding()
                    .background(Color.secondaryBg)
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                
                // Exercises Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Exercises")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Button(action: { showingAddExercise = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Exercise")
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentPrimary)
                        }
                    }
                    .padding(.horizontal)
                    
                    if routine.exercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 32))
                                .foregroundColor(.textSecondary)
                            
                            Text("No exercises added")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            
                            Text("Add exercises to build your routine")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.secondaryBg)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(sortedExercises, id: \.id) { routineExercise in
                                    RoutineTemplateExerciseRowView(routineExercise: routineExercise)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                    Spacer()
                }
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
                .onAppear {
                    // Fix for RTIInputSystemClient error - ensure clean text input state
                    DispatchQueue.main.async {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
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
                        .foregroundColor(.textPrimary)
                    
                HStack(spacing: 8) {
                    if routineExercise.sets > 0 {
                        Text("\(routineExercise.sets)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                        Text("sets")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                    if let reps = routineExercise.reps {
                        Text("\(reps)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                        Text("reps")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    }
                    
                    if let weight = routineExercise.weight {
                        Text("\(Int(weight))")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                        Text("kg")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    }
                    
                    if let duration = routineExercise.duration {
                        Text("\(duration)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                        Text("sec")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
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
                    .foregroundColor(.errorRed)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
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
                                .onTapGesture {
                                    // Ensure proper focus management
                                    DispatchQueue.main.async {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }
                        }
                    .padding()
                
                    }
                    if let exercise = selectedExercise {
                        // Exercise Details Form
                        Form {
                            Section("Exercise") {
                                HStack {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(exercise.category)
                                            .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentPrimary.opacity(0.2))
                                        .foregroundColor(.accentPrimary)
                                        .cornerRadius(4)
                                }
                            }
                        
                            Section("Workout Details") {
                                Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                                
                                if exercise.equipment == "Body" || exercise.category == "Cardio" {
                                    Stepper("Duration: \(sets * 60) sec", value: $sets, in: 1...60)
                                } else {
                                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                                    Stepper("Weight: \(Int(weight)) kg", value: $weight, in: 0...500, step: 1)
                                }
                            }
                            
                            Section("Notes") {
                                TextField("Notes (optional)", text: $notes, axis: .vertical)
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(2...4)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                    // Exercise List
                    ExerciseListView(
                        exercises: filteredExercises,
                        searchText: $searchText,
                        onExerciseSelected: { exercise in
                            selectedExercise = exercise
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
                        .foregroundColor(.accentPrimary)
                    }
                    
                    if selectedExercise != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                addExercise()
                            }
                            .foregroundColor(.accentPrimary)
                        }
                    }
                }
            }
        }
    
    private func addExercise() {
        guard let exercise = selectedExercise else { return }
        
        let isCardio = exercise.equipment == "Body" || exercise.category == "Cardio"
        
        _ = RoutineService.shared.addExerciseToRoutine(
            routine: routine,
            exerciseId: exercise.id,
            sets: sets,
            reps: isCardio ? nil : reps,
            weight: isCardio ? nil : weight,
            duration: isCardio ? sets * 60 : nil,
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
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Control for Settings Sections
                    Picker("Settings Section", selection: $selectedTab) {
                        Text("Routines").tag(0)
                        Text("Exercises").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .tint(.textPrimary)
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        RoutinesView()
                    } else {
                        ExercisesView()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
    @Environment(\.modelContext) private var modelContext
    
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
        .accentColor(.accentPrimary)
        .environmentObject(appState)
        .onAppear {
            // Customize tab bar appearance - Dark theme with coral-orange accent
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(hex: "#0A0E14") // primaryBg
            
            // Active tab styling (coral-orange accent)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "#FF6B35") // accentPrimary
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(hex: "#FF6B35"),
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
            ]
            
            // Inactive tab styling (muted secondary)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex: "#8B92A0") // textSecondary
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(hex: "#8B92A0"),
                .font: UIFont.systemFont(ofSize: 12, weight: .regular)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onAppear {
            // Sync active workout state from SwiftData on app launch
            appState.syncActiveWorkoutFromSwiftData(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, RoutineExercise.self, Routine.self], inMemory: true)
}
