import SwiftUI

// MARK: - Exercise Library View
public struct ExerciseLibraryView: View {
    
    @StateObject private var viewModel: ExerciseLibraryViewModel
    @State private var showingFilters = false
    
    public init(exerciseLibraryService: ExerciseLibraryService) {
        self._viewModel = StateObject(wrappedValue: ExerciseLibraryViewModel(exerciseLibraryService: exerciseLibraryService))
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Filter Bar
                filterBar
                
                // Exercise List
                exerciseList
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filters") {
                        showingFilters = true
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading exercises...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                }
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search exercises...", text: $viewModel.searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: viewModel.searchQuery) { _ in
                    viewModel.applyFilters()
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Muscle Group Filter
                Menu {
                    Button("All Muscle Groups") {
                        viewModel.setMuscleGroupFilter(nil)
                    }
                    
                    ForEach(viewModel.getMuscleGroups(), id: \.self) { muscleGroup in
                        Button(muscleGroup.rawValue) {
                            viewModel.setMuscleGroupFilter(muscleGroup)
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedMuscleGroup?.rawValue ?? "All Muscle Groups")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                // Exercise Type Filter
                Menu {
                    Button("All Types") {
                        viewModel.setExerciseTypeFilter(nil)
                    }
                    
                    ForEach(viewModel.getExerciseTypes(), id: \.self) { exerciseType in
                        Button(exerciseType.rawValue) {
                            viewModel.setExerciseTypeFilter(exerciseType)
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedExerciseType?.rawValue ?? "All Types")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                
                // Bodyweight Filter
                Button(action: viewModel.toggleBodyweightFilter) {
                    HStack {
                        Image(systemName: viewModel.showBodyweightOnly ? "checkmark.circle.fill" : "circle")
                        Text("Bodyweight")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.showBodyweightOnly ? Color.orange : Color.orange.opacity(0.1))
                    .foregroundColor(viewModel.showBodyweightOnly ? .white : .orange)
                    .cornerRadius(8)
                }
                
                // Weighted Filter
                Button(action: viewModel.toggleWeightedFilter) {
                    HStack {
                        Image(systemName: viewModel.showWeightedOnly ? "checkmark.circle.fill" : "circle")
                        Text("Weighted")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.showWeightedOnly ? Color.purple : Color.purple.opacity(0.1))
                    .foregroundColor(viewModel.showWeightedOnly ? .white : .purple)
                    .cornerRadius(8)
                }
                
                // Clear Filters
                if viewModel.hasActiveFilters {
                    Button("Clear") {
                        viewModel.clearFilters()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Exercise List
    private var exerciseList: some View {
        List {
            if viewModel.filteredExercises.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.filteredExercises, id: \.id) { exercise in
                    ExerciseRowView(exercise: exercise)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No exercises found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try adjusting your filters or search terms")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if viewModel.hasActiveFilters {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Exercise Row View
struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(exercise.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Text(exercise.type)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text(exercise.unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter View
struct FilterView: View {
    @ObservedObject var viewModel: ExerciseLibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Muscle Group") {
                    ForEach(viewModel.getMuscleGroups(), id: \.self) { muscleGroup in
                        Button(action: {
                            viewModel.setMuscleGroupFilter(muscleGroup)
                        }) {
                            HStack {
                                Text(muscleGroup.rawValue)
                                Spacer()
                                if viewModel.selectedMuscleGroup == muscleGroup {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("Exercise Type") {
                    ForEach(viewModel.getExerciseTypes(), id: \.self) { exerciseType in
                        Button(action: {
                            viewModel.setExerciseTypeFilter(exerciseType)
                        }) {
                            HStack {
                                Text(exerciseType.rawValue)
                                Spacer()
                                if viewModel.selectedExerciseType == exerciseType {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("Exercise Category") {
                    Toggle("Bodyweight Only", isOn: $viewModel.showBodyweightOnly)
                    Toggle("Weighted Only", isOn: $viewModel.showWeightedOnly)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        viewModel.clearFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ExerciseLibraryView(exerciseLibraryService: ExerciseLibraryService(exerciseRepository: InMemoryExerciseRepository()))
}