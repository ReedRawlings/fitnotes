import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var selectedMuscleGroup: String = ""
    @State private var searchText = ""
    @State private var showingAddExercise = false
    @State private var selectedExercise: Exercise?
    
    private var filteredExercises: [Exercise] {
        ExerciseSearchService.shared.searchExercises(
            query: searchText,
            category: selectedMuscleGroup.isEmpty ? nil : selectedMuscleGroup,
            exercises: allExercises
        )
    }
    
    private var muscleGroups: [String] {
        let groups = Set(allExercises.map { $0.category })
        return groups.sorted()
    }
    
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
                // Search and Filter Section
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Muscle Group Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(muscleGroups, id: \.self) { group in
                                Button(action: {
                                    selectedMuscleGroup = selectedMuscleGroup == group ? "" : group
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
                .padding(.vertical, 8)
                .background(Color.clear)
                
                // Exercises List
                if filteredExercises.isEmpty {
                    EmptyStateView(
                        icon: "dumbbell",
                        title: "No exercises found",
                        subtitle: "Try adjusting your search or filter",
                        actionTitle: "Add Exercise",
                        onAction: {
                            showingAddExercise = true
                        }
                    )
                } else {
                    ExerciseListView(
                        exercises: filteredExercises,
                        searchText: $searchText,
                        onExerciseSelected: { exercise in
                            selectedExercise = exercise
                        },
                        context: .browse
                    )
                }
            }
            
            // Fixed bottom button - overlay on top
            VStack {
                Spacer()
                PrimaryActionButton(title: "Add Exercise") {
                    showingAddExercise = true
                }
                .padding(.bottom, 8) // Small padding above tab bar
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView()
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .onAppear {
            // Initialize default exercises if none exist
            if allExercises.isEmpty {
                ExerciseDatabaseService.shared.createDefaultExercises(modelContext: modelContext)
            }
        }
    }
}


struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedCategory = "Chest"
    @State private var selectedType = "Strength"
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                    
                    Picker("Muscle Group", selection: $selectedCategory) {
                        ForEach(ExerciseDatabaseService.muscleGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(ExerciseDatabaseService.exerciseTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Personal notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveExercise() {
        let exercise = Exercise(
            name: name,
            category: selectedCategory,
            type: selectedType,
            notes: notes.isEmpty ? nil : notes,
            isCustom: true
        )
        
        modelContext.insert(exercise)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving exercise: \(error)")
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 12) {
                            Text(exercise.category)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Details Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DetailCard(title: "Type", value: exercise.type)
                        DetailCard(title: "Category", value: exercise.category)
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    if let notes = exercise.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    ExercisesView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, RoutineExercise.self, Routine.self], inMemory: true)
}
