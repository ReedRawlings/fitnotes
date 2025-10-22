import SwiftUI
import SwiftData

struct HistoryTabView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allSets: [WorkoutSet]
    @State private var showingEditSheet = false
    @State private var selectedSet: WorkoutSet?
    @State private var showingDeleteAlert = false
    @State private var setToDelete: WorkoutSet?
    
    private var groupedSets: [(Date, [WorkoutSet])] {
        let filteredSets = allSets.filter { $0.exerciseId == exercise.id }
        let grouped = Dictionary(grouping: filteredSets) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        if groupedSets.isEmpty {
            EmptyStateView(
                icon: "clock.arrow.circlepath",
                title: "No History",
                subtitle: "Complete a workout to see your progress",
                actionTitle: nil,
                onAction: nil
            )
        } else {
            List {
                ForEach(groupedSets, id: \.0) { date, sets in
                    Section(header: DateHeaderView(date: date)) {
                        ForEach(sets.sorted { $0.order < $1.order }) { set in
                            SetHistoryRowView(
                                set: set,
                                onTap: {
                                    selectedSet = set
                                    showingEditSheet = true
                                },
                                onDelete: {
                                    setToDelete = set
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .sheet(isPresented: $showingEditSheet) {
            if let set = selectedSet {
                EditSetSheet(
                    set: set,
                    onSave: { weight, reps in
                        _ = ExerciseService.shared.updateSet(
                            setId: set.id,
                            weight: weight,
                            reps: reps,
                            modelContext: modelContext
                        )
                    }
                )
            }
        }
        .alert("Delete Set", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let set = setToDelete {
                    _ = ExerciseService.shared.deleteSet(
                        setId: set.id,
                        modelContext: modelContext
                    )
                }
            }
        } message: {
            Text("Are you sure you want to delete this set? This action cannot be undone.")
        }
    }
}

struct DateHeaderView: View {
    let date: Date
    
    var body: some View {
        Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day(.twoDigits)))
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .textCase(.uppercase)
            .padding(.vertical, 8)
    }
}

struct SetHistoryRowView: View {
    let set: WorkoutSet
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onTap) {
                HStack {
                    Text("\(String(format: "%.1f", set.weight)) kg × \(set.reps) reps")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
    }
}

struct EditSetSheet: View {
    let set: WorkoutSet
    let onSave: (Double, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.headline)
                    
                    HStack {
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.headline)
                    
                    TextField("0", text: $repsText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let weight = Double(weightText),
                           let reps = Int(repsText) {
                            onSave(weight, reps)
                            dismiss()
                        }
                    }
                    .disabled(weightText.isEmpty || repsText.isEmpty)
                }
            }
        }
        .onAppear {
            weightText = set.weight > 0 ? String(format: "%.1f", set.weight) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
}

#Preview {
    HistoryTabView(exercise: Exercise(
        name: "Bench Press",
        category: "Chest",
        type: "Strength"
    ))
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
}
