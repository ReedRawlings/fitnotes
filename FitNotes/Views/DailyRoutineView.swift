import SwiftUI
import SwiftData

struct DailyRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyRoutine.date, order: .reverse) private var routines: [DailyRoutine]
    @State private var showingAddRoutine = false
    @State private var selectedDate = Date()
    
    var todaysRoutine: DailyRoutine? {
        let calendar = Calendar.current
        return routines.first { routine in
            calendar.isDate(routine.date, inSameDayAs: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date Picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                
                Divider()
                
                if let routine = getRoutineForDate(selectedDate) {
                    RoutineDetailView(routine: routine)
                } else {
                    EmptyRoutineView(selectedDate: selectedDate) {
                        showingAddRoutine = true
                    }
                }
            }
            .navigationTitle("Daily Routine")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRoutine = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineView(selectedDate: selectedDate)
        }
    }
    
    private func getRoutineForDate(_ date: Date) -> DailyRoutine? {
        let calendar = Calendar.current
        return routines.first { routine in
            calendar.isDate(routine.date, inSameDayAs: date)
        }
    }
}

struct RoutineDetailView: View {
    let routine: DailyRoutine
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddExercise = false
    @State private var showingEditRoutine = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Routine Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(routine.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if routine.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let notes = routine.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
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
                            
                            Text("Add exercises to start your routine")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(routine.exercises.sorted { $0.order < $1.order }, id: \.id) { routineExercise in
                                RoutineExerciseRowView(routineExercise: routineExercise)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if !routine.exercises.isEmpty {
                        Button(action: {
                            DailyRoutineService.shared.completeRoutine(routine, modelContext: modelContext)
                        }) {
                            HStack {
                                Image(systemName: routine.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                                Text(routine.isCompleted ? "Completed" : "Mark Complete")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(routine.isCompleted ? Color.green : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(routine.isCompleted)
                    }
                    
                    Button(action: { showingEditRoutine = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Routine")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
        }
    }
}

struct RoutineExerciseRowView: View {
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
                    if let sets = routineExercise.sets, sets > 0 {
                        Text("\(sets) sets")
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
            
            // Complete Button
            Button(action: {
                routineExercise.isCompleted.toggle()
                try? modelContext.save()
            }) {
                Image(systemName: routineExercise.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(routineExercise.isCompleted ? .green : .gray)
            }
            
            // Delete Button
            Button(action: {
                if let routine = routineExercise.dailyRoutine {
                    DailyRoutineService.shared.removeExerciseFromRoutine(
                        routineExercise: routineExercise,
                        modelContext: modelContext
                    )
                }
            }) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptyRoutineView: View {
    let selectedDate: Date
    let onAddRoutine: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No routine for this day")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Create a daily routine to track your exercises")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onAddRoutine) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Routine")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let selectedDate: Date
    @State private var name = ""
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Routine Details") {
                    TextField("Routine Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
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
        .onAppear {
            date = selectedDate
        }
    }
    
    private func createRoutine() {
        let routine = DailyRoutineService.shared.createDailyRoutine(
            name: name,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            modelContext: modelContext
        )
        
        dismiss()
    }
}

struct AddExerciseToRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let routine: DailyRoutine
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
        
        DailyRoutineService.shared.addExerciseToRoutine(
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

#Preview {
    DailyRoutineView()
        .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, Program.self, BodyMetric.self, DailyRoutine.self, RoutineExercise.self], inMemory: true)
}
