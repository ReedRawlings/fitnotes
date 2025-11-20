# Swift Predicate Error Fix Instructions

## Problem
**File**: `FitNotes/DailyRoutineView.swift`
**Lines**: 1045-1051
**Error**: "Predicate body may only contain one expression (from macro 'Predicate')"

The `#Predicate` macro cannot capture values from SwiftUI ForEach closure scope. This is a known Swift limitation.

## Current Broken Code
```swift
// Line 987: SaveWorkoutAsRoutineView struct
struct SaveWorkoutAsRoutineView: View {
    @Binding var isPresented: Bool
    let workout: Workout?
    let modelContext: ModelContext
    let onSave: (String, String?) -> Void

    @State private var routineName = ""
    @State private var routineDescription = ""
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        // ... navigation and text fields ...

        // Lines 1038-1051: THE PROBLEMATIC CODE
        ForEach(workout.exercises.sorted { $0.order < $1.order }, id: \.id) { workoutExercise in
            let exerciseId = workoutExercise.exerciseId
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentSuccess)
                    .font(.system(size: 16))

                if let exercise = try? modelContext.fetch(FetchDescriptor<Exercise>(predicate: #Predicate<Exercise> { exercise in
                    exercise.id == exerciseId
                })).first {
                    Text(exercise.name)
                        .font(.system(size: 14))
                        .foregroundColor(.textPrimary)
                }

                Spacer()
            }
        }
    }
}
```

## Solution: Add @Query and Use In-Memory Filtering

### Step 1: Add @Query property to SaveWorkoutAsRoutineView

Add this property declaration after line 995 (after the @FocusState line):

```swift
@Query(sort: \Exercise.name) private var allExercises: [Exercise]
```

### Step 2: Replace the FetchDescriptor predicate with in-memory filtering

Replace lines 1045-1051 with:

```swift
if let exercise = allExercises.first(where: { $0.id == workoutExercise.exerciseId }) {
    Text(exercise.name)
        .font(.system(size: 14))
        .foregroundColor(.textPrimary)
}
```

### Step 3: Remove the unused variable

Remove line 1039:
```swift
let exerciseId = workoutExercise.exerciseId
```

## Complete Fixed Code

```swift
struct SaveWorkoutAsRoutineView: View {
    @Binding var isPresented: Bool
    let workout: Workout?
    let modelContext: ModelContext
    let onSave: (String, String?) -> Void

    @State private var routineName = ""
    @State private var routineDescription = ""
    @FocusState private var isNameFieldFocused: Bool
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]  // ← ADD THIS

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Routine Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)

                        TextField("e.g., Push Day, Leg Day", text: $routineName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.secondaryBg)
                            .cornerRadius(8)
                            .foregroundColor(.textPrimary)
                            .focused($isNameFieldFocused)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)

                        TextField("e.g., Chest, Shoulders, Triceps", text: $routineDescription)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.secondaryBg)
                            .cornerRadius(8)
                            .foregroundColor(.textPrimary)
                    }

                    if let workout = workout {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exercises to Include")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)

                            VStack(spacing: 8) {
                                ForEach(workout.exercises.sorted { $0.order < $1.order }, id: \.id) { workoutExercise in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentSuccess)
                                            .font(.system(size: 16))

                                        // ← REPLACE THE FetchDescriptor CODE WITH THIS:
                                        if let exercise = allExercises.first(where: { $0.id == workoutExercise.exerciseId }) {
                                            Text(exercise.name)
                                                .font(.system(size: 14))
                                                .foregroundColor(.textPrimary)
                                        }

                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Color.secondaryBg)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Save as Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(routineName, routineDescription.isEmpty ? nil : routineDescription)
                        isPresented = false
                    }
                    .foregroundColor(.accentColor)
                    .disabled(routineName.isEmpty)
                }
            }
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }
}
```

## Why This Works

1. **@Query fetches once**: All exercises are fetched when the view appears
2. **In-memory filtering**: `.first(where:)` is a simple Swift array operation, not a SwiftData predicate
3. **No macro issues**: We're not using `#Predicate` at all anymore
4. **Fast performance**: Exercise list is small, in-memory filtering is instant
5. **Matches existing patterns**: WorkoutExerciseRowView uses the same approach (line 388)

## Testing

After implementing:
1. Build the project - should compile without errors
2. Navigate to a workout with exercises
3. Tap "Save as Routine" button
4. Verify exercise names display correctly in the preview list
5. Save the routine and verify it creates correctly

## Notes

- This ONLY affects the preview display in the dialog
- The actual routine creation logic (lines 166-211) is unchanged
- Your routine architecture works exactly the same way
