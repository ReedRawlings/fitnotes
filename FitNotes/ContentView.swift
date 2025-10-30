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

// MARK: - Stats Header Component
struct StatsHeaderView: View {
    let weeksActive: Int
    let totalVolume: String
    let daysSinceLastLift: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Weeks Active
            VStack(alignment: .leading, spacing: 4) {
                Text("\(weeksActive)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.accentPrimary)
                Text("Weeks Active")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
                .overlay(Color.white.opacity(0.1))
            
            // Total Volume
            VStack(alignment: .leading, spacing: 4) {
                Text(totalVolume)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.accentPrimary)
                Text("Total Volume")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
                .overlay(Color.white.opacity(0.1))
            
            // Days Since Last Lift
            VStack(alignment: .leading, spacing: 4) {
                Text(daysSinceLastLift)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.accentPrimary)
                Text("Last Workout")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
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
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query private var allSets: [WorkoutSet]
    @State private var expandedRoutineId: UUID?
    @State private var showingRoutineDetail: Routine?
    @State private var cachedStats: (weeksActive: Int?, totalVolume: String?, daysSince: String?) = (nil, nil, nil)
    
    private var weeksActive: Int {
        StatsService.shared.getWeeksActiveStreak(workouts: workouts)
    }
    
    private var totalVolumeFormatted: String {
        let volume = StatsService.shared.getTotalVolume(allSets: allSets)
        return StatsService.shared.formatVolume(volume)
    }
    
    private var daysSinceLastLiftText: String {
        StatsService.shared.getDaysSinceLastLift(workouts: workouts)
    }
    
    var body: some View {
        ZStack {
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        // Stats header
                        StatsHeaderView(
                            weeksActive: weeksActive,
                            totalVolume: totalVolumeFormatted,
                            daysSinceLastLift: daysSinceLastLiftText
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
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
            // Invalidate cache on appear
            cachedStats = (nil, nil, nil)
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
    @State private var addExerciseRoutine: Routine?
    
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
                        actionTitle: nil,
                        onAction: nil
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
            
            // Fixed bottom button - overlay on top (always visible for consistency)
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
        .sheet(item: $addExerciseRoutine) { routine in
            AddExerciseToRoutineTemplateView(routine: routine)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowAddExerciseForRoutine"))) { notification in
            if let routine = notification.object as? Routine {
                addExerciseRoutine = routine
            }
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
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Routine Details Card
                    FormSectionCard(title: "Routine Details") {
                        LabeledTextInput(
                            label: "Routine Name",
                            placeholder: "e.g., Upper Body Day",
                            text: $name
                        )
                        
                        LabeledTextInput(
                            label: "Description (optional)",
                            placeholder: "Add a description...",
                            text: $description,
                            axis: .vertical,
                            lineLimit: 3...6
                        )
                    }
                    
                    Spacer(minLength: 100) // Space for fixed button
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            
            // Fixed CTA at bottom
            FixedModalCTAButton(
                title: "Create Routine",
                icon: "checkmark",
                isEnabled: !name.isEmpty,
                action: createRoutine
            )
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
        }
    }
    
    private func createRoutine() {
        let routine = RoutineService.shared.createRoutine(
            name: name,
            description: description.isEmpty ? nil : description,
            modelContext: modelContext
        )
        
        // Immediately present the Add Exercises picker for the new routine
        // Using sheet to keep consistent with modal add flows
        // Dismiss creation view and then show picker
        DispatchQueue.main.async {
            dismiss()
            // Present AddExerciseToRoutineTemplateView for the new routine
            // This relies on RoutinesView's sheet presentation when a routine is selected
            NotificationCenter.default.post(
                name: Notification.Name("ShowAddExerciseForRoutine"),
                object: routine
            )
        }
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
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if routine.exercises.isEmpty {
                    EmptyStateView(
                        icon: "dumbbell",
                        title: "No exercises added",
                        subtitle: "Add exercises to build your routine",
                        actionTitle: nil,
                        onAction: nil
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Routine Header Card
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
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                            
                            // Exercises List with reordering support
                            List {
                                ForEach(sortedExercises, id: \.id) { routineExercise in
                                    RoutineTemplateExerciseRowView(routineExercise: routineExercise)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets())
                                }
                                .onMove { indices, newOffset in
                                    RoutineService.shared.reorderRoutineExercises(
                                        routine: routine,
                                        from: indices,
                                        to: newOffset,
                                        modelContext: modelContext
                                    )
                                }
                            }
                            .listStyle(.plain)
                            .frame(maxHeight: .infinity)
                            
                            Spacer(minLength: 80) // Space for fixed button
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Routine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .overlay(
                // Fixed bottom button - overlay on top
                VStack {
                    Spacer()
                    PrimaryActionButton(title: "Add Exercise") {
                        showingAddExercise = true
                    }
                    .padding(.bottom, 8) // Small padding above safe area
                }
            )
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
    @State private var selectedMuscleGroup: String = ""
    @State private var selectedEquipment: String = ""
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
                        addExercisesToRoutine(ids: [exercise.id])
                    },
                    context: .picker,
                    selectedIds: $selectedIds
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
            // Fixed CTA at bottom
            FixedModalCTAButton(
                title: selectedIds.isEmpty ? "Select exercises" : "Add \(selectedIds.count) Exercise\(selectedIds.count == 1 ? "" : "s")",
                icon: "checkmark",
                isEnabled: !selectedIds.isEmpty,
                action: {
                    addExercisesToRoutine(ids: Array(selectedIds))
                }
            )
        }
    }
    
    private func defaultsForExercise(exercise: Exercise) -> (sets: Int, reps: Int?, weight: Double?, duration: Int?) {
        var sets = 1
        var reps: Int? = nil
        var weight: Double? = nil
        var duration: Int? = nil
        if let lastSession = ExerciseService.shared.getLastSessionForExercise(
            exerciseId: exercise.id,
            modelContext: modelContext
        ), let firstSet = lastSession.first {
            sets = lastSession.count
            reps = firstSet.reps
            weight = firstSet.weight
            duration = firstSet.duration
        } else {
            if exercise.equipment == "Body" || exercise.primaryCategory == "Cardio" {
                duration = 60
                reps = nil
                weight = nil
            } else {
                reps = 10
                weight = 0
                duration = nil
            }
        }
        return (sets, reps, weight, duration)
    }
    
    private func addExercisesToRoutine(ids: [UUID]) {
        // Map selected IDs to Exercise models
        let byId = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        for id in ids {
            guard let exercise = byId[id] else { continue }
            let defaults = defaultsForExercise(exercise: exercise)
            _ = RoutineService.shared.addExerciseToRoutine(
                routine: routine,
                exerciseId: exercise.id,
                sets: defaults.sets,
                reps: defaults.reps,
                weight: defaults.weight,
                duration: defaults.duration,
                notes: nil,
                modelContext: modelContext
            )
        }
        dismiss()
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Segmented Control for Settings Sections
                    HStack(spacing: 0) {
                        // Routines Tab
                        Button(action: {
                            withAnimation(.standardSpring) {
                                selectedTab = 0
                            }
                        }) {
                            Text("Routines")
                                .font(selectedTab == 0 ? .system(size: 15, weight: .semibold) : .tabFont)
                                .foregroundColor(selectedTab == 0 ? .textPrimary : .textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedTab == 0 ? Color.tertiaryBg : Color.clear)
                                )
                                .scaleEffect(selectedTab == 0 ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: selectedTab)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Exercises Tab
                        Button(action: {
                            withAnimation(.standardSpring) {
                                selectedTab = 1
                            }
                        }) {
                            Text("Exercises")
                                .font(selectedTab == 1 ? .system(size: 15, weight: .semibold) : .tabFont)
                                .foregroundColor(selectedTab == 1 ? .textPrimary : .textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedTab == 1 ? Color.tertiaryBg : Color.clear)
                                )
                                .scaleEffect(selectedTab == 1 ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: selectedTab)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(4)
                    .background(Color.secondaryBg)
                    .cornerRadius(12)
                    .padding()
                    
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
            // Sync active workout state from SwiftData on app launch
            appState.syncActiveWorkoutFromSwiftData(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, RoutineExercise.self, Routine.self], inMemory: true)
}

