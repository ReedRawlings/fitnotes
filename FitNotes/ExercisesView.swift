import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var selectedMuscleGroup: String = ""
    @State private var selectedEquipment: String = ""
    @State private var showingAddExercise = false
    @State private var selectedExercise: Exercise?
    
    
    private var filteredExercises: [Exercise] {
        ExerciseSearchService.shared.searchExercises(
            query: "",
            category: selectedMuscleGroup.isEmpty ? nil : selectedMuscleGroup,
            equipment: selectedEquipment.isEmpty ? nil : selectedEquipment,
            exercises: allExercises
        )
    }
    
    private var muscleGroups: [String] {
        let groups = Set(allExercises.map { $0.primaryCategory })
        return groups.sorted()
    }
    
    var body: some View {
        ZStack {
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter Section
                VStack(spacing: 12) {
                    // Equipment Filter
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
                                        .background(
                                            selectedEquipment == equipment
                                                ? Color.accentPrimary
                                                : Color.tertiaryBg
                                        )
                                        .foregroundColor(
                                            selectedEquipment == equipment
                                                ? .textInverse
                                                : .textPrimary
                                        )
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
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
                                                ? Color.accentPrimary
                                                : Color.tertiaryBg
                                        )
                                        .foregroundColor(
                                            selectedMuscleGroup == group
                                                ? .textInverse
                                                : .textPrimary
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
                        searchText: .constant(""),
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
            ExerciseDetailView(exercise: exercise, appState: appState)
                .environmentObject(appState)
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

    @State private var name: String
    @State private var selectedCategory = "Chest"
    @State private var selectedEquipment = "Free Weight"
    @State private var notes = ""
    @FocusState private var focusedField: Bool
    
    init(name: String = "") {
        _name = State(initialValue: name)
    }

    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Exercise Details Card
                    FormSectionCard(title: "Exercise Details") {
                        LabeledTextInput(
                            label: "Exercise Name",
                            placeholder: "e.g., Bench Press",
                            text: $name
                        )
                        
                        LabeledMenuPicker(
                            label: "Muscle Group",
                            options: ExerciseDatabaseService.muscleGroups,
                            selection: $selectedCategory
                        )
                        
                        LabeledMenuPicker(
                            label: "Equipment",
                            options: ExerciseDatabaseService.equipmentTypes,
                            selection: $selectedEquipment
                        )
                    }
                    
                    // Notes Card
                    FormSectionCard(title: "Notes (Optional)") {
                        TextField("Personal notes...", text: $notes, axis: .vertical)
                            .font(.bodyFont)
                            .foregroundColor(.textPrimary)
                            .padding(12)
                            .background(Color.tertiaryBg)
                            .cornerRadius(10)
                            .lineLimit(2...4)
                            .focused($focusedField)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Dismiss keyboard when tapping outside input fields
                focusedField = false
            }

            // Fixed CTA at bottom
            FixedModalCTAButton(
                title: "Save Exercise",
                icon: "checkmark",
                isEnabled: !name.isEmpty,
                action: saveExercise
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
    
    private func saveExercise() {
        let exercise = Exercise(
            name: name,
            primaryCategory: selectedCategory,
            secondaryCategories: [],
            equipment: selectedEquipment,
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

#Preview {
    ExercisesView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, RoutineExercise.self, Routine.self], inMemory: true)
}
