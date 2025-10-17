import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var selectedMuscleGroup: String = "All"
    @State private var searchText = ""
    @State private var showingAddExercise = false
    
    private var filteredExercises: [Exercise] {
        var exercises = allExercises
        
        if selectedMuscleGroup != "All" {
            exercises = exercises.filter { $0.category == selectedMuscleGroup }
        }
        
        if !searchText.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return exercises
    }
    
    private var muscleGroups: [String] {
        let groups = Set(allExercises.map { $0.category })
        return ["All"] + groups.sorted()
    }
    
    var body: some View {
        NavigationView {
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
                .padding(.vertical, 8)
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
                        Text("Try adjusting your search or filter")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List(filteredExercises) { exercise in
                        ExerciseRowView(exercise: exercise)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddExercise = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView()
        }
        .onAppear {
            // Initialize default exercises if none exist
            if allExercises.isEmpty {
                ExerciseDatabaseService.shared.createDefaultExercises(modelContext: modelContext)
            }
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 12) {
                // Exercise Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: exerciseIcon(for: exercise.category))
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                // Exercise Info
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
                        
                        if !exercise.equipment.isEmpty {
                            Text(exercise.equipment)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(exercise.difficulty)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor(exercise.difficulty).opacity(0.2))
                            .foregroundColor(difficultyColor(exercise.difficulty))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailView(exercise: exercise)
        }
    }
    
    private func exerciseIcon(for category: String) -> String {
        switch category.lowercased() {
        case "chest": return "heart"
        case "back": return "figure.strengthtraining.traditional"
        case "shoulders": return "figure.arms.open"
        case "arms": return "figure.arms.open"
        case "legs": return "figure.walk"
        case "core": return "circle.grid.cross"
        case "glutes": return "figure.strengthtraining.functional"
        case "cardio": return "heart.fill"
        default: return "dumbbell"
        }
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedCategory = "Chest"
    @State private var selectedType = "Strength"
    @State private var selectedEquipment = "Bodyweight"
    @State private var selectedDifficulty = "Beginner"
    @State private var instructions = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExerciseDatabaseService.muscleGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(ExerciseDatabaseService.exerciseTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    Picker("Equipment", selection: $selectedEquipment) {
                        ForEach(ExerciseDatabaseService.equipmentTypes, id: \.self) { equipment in
                            Text(equipment).tag(equipment)
                        }
                    }
                    
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(ExerciseDatabaseService.difficultyLevels, id: \.self) { difficulty in
                            Text(difficulty).tag(difficulty)
                        }
                    }
                }
                
                Section("Instructions") {
                    TextField("Exercise instructions...", text: $instructions, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Notes") {
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
            equipment: selectedEquipment,
            difficulty: selectedDifficulty,
            instructions: instructions.isEmpty ? nil : instructions,
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
                            
                            Text(exercise.equipment)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
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
                        DetailCard(title: "Difficulty", value: exercise.difficulty)
                    }
                    .padding(.horizontal)
                    
                    // Instructions
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(.headline)
                            
                            Text(instructions)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
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
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, Program.self, BodyMetric.self, DailyRoutine.self, RoutineExercise.self], inMemory: true)
}
