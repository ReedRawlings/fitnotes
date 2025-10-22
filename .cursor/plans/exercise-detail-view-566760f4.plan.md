<!-- 566760f4-3e0f-4536-a068-8ef5bc49ac83 f2da5e4b-ee46-4652-b2e4-0e32f2fa12cd -->
# Exercise Detail View Implementation

## Overview

Implement a comprehensive Exercise Detail View with Track and History tabs, allowing users to log workouts, view past sessions, and edit historical data. This replaces the current ExerciseHistoryView with a more robust solution.

## Data Model Changes

### 1. Refactor WorkoutSet Model

**File:** `FitNotes/DailyRoutine.swift`

- Remove `workoutId` dependency from `WorkoutSet`
- Group sets by `exerciseId` + `date` instead of `workoutId`
- Keep `date` field for querying sets by day
- Remove `workoutId` from `WorkoutSet` model (lines 105-146)
- Update `WorkoutExercise.sets` relationship if needed

### 2. Update ExerciseService

**File:** `FitNotes/ExerciseService.swift`

- Update `getLastSessionForExercise()` to group by date instead of workoutId (lines 27-63)
- Update `getExerciseHistory()` to return sets grouped by date (lines 69-111)
- Create new method: `getSetsByDate(exerciseId: UUID, date: Date)` for Track tab
- Create new method: `saveSets(exerciseId: UUID, date: Date, sets: [(weight: Double, reps: Int)])` 
- Create new method: `updateSet(setId: UUID, weight: Double, reps: Int)`
- Create new method: `deleteSet(setId: UUID)`

## New View Components

### 3. Create ExerciseDetailView (Main Container)

**New File:** `FitNotes/ExerciseDetailView.swift`

Structure:

- Header: Exercise name (large title), category badge, type label
- Segmented control: "Track" | "History" tabs
- Tab content area with conditional rendering
- Pass exercise object as parameter
- Use `@State` for selected tab (default: Track)

### 4. Create TrackTabView (For Current Workout)

**New File:** `FitNotes/TrackTabView.swift`

Features:

- Display "Last Session" summary (read-only)
- Editable set list with Add/Delete functionality
- Each set row: Weight input (kg) + Reps input + Delete button
- "Add Set" button (prominent, top and bottom)
- "Save" button at bottom
- Pre-populate with last session data on load
- Create/update workout for today on save

State management:

- `@State var sets: [(id: UUID, weight: Double, reps: Int)]`
- `@State var lastSessionSummary: String?`

### 5. Create HistoryTabView (For Past Sessions)

**New File:** `FitNotes/HistoryTabView.swift`

Features:

- List grouped by date (most recent first)
- Date headers: "FRIDAY, JANUARY 12" format (uppercase)
- Set rows: "105.0 kg × 5 reps" format
- Tap set to edit (modal sheet)
- Swipe to delete with confirmation
- Use `@Query` for automatic updates

### 6. Create EditSetSheet (Modal for Editing)

**Component in:** `FitNotes/HistoryTabView.swift`

Features:

- Modal title: "Edit Set"
- Weight input field (with kg unit)
- Reps input field
- Cancel/Save buttons
- Save updates SwiftData immediately

## Service Layer Updates

### 7. Create WorkoutService Helper

**File:** `FitNotes/DailyRoutineService.swift` (if exists) or new file

Add method:

- `getOrCreateWorkoutForDate(date: Date)` - finds existing workout or creates default one
- Returns workout to attach sets to

## Integration Points

### 8. Update Navigation from Existing Views

**Files to modify:**

- `FitNotes/ExerciseListView.swift` - Navigate to ExerciseDetailView on tap
- `FitNotes/DailyRoutineView.swift` - Navigate to ExerciseDetailView from workout
- `FitNotes/ExercisesView.swift` - Navigate to ExerciseDetailView from library

Replace current history modal navigation with new ExerciseDetailView navigation.

### 9. Remove Old ExerciseHistoryView

**File:** `FitNotes/ExerciseHistoryView.swift`

Delete after confirming all references updated to use new ExerciseDetailView.

## UI/UX Standards

- Use existing app design system (blue gradients, white cards)
- Standard iOS input styling for text fields
- Accent color for primary actions (Save button)
- 16-20px section padding, 12px field spacing, 8px set row spacing
- Empty states with helpful messages
- Loading states where appropriate
- Confirmation dialogs for destructive actions (delete)

## Testing Considerations

- Test pre-population with and without history
- Test saving multiple sets
- Test editing historical sets
- Test deleting sets (including last set for a date)
- Test navigation from all three contexts (routine, workout, library)
- Verify workout creation when none exists for today

### To-dos

- [ ] Remove workoutId dependency from WorkoutSet model, update to use exerciseId + date grouping
- [ ] Update ExerciseService methods to work with date-based grouping and add CRUD operations
- [ ] Create main ExerciseDetailView container with header and tab navigation
- [ ] Implement TrackTabView with set list, add/delete, and save functionality
- [ ] Implement HistoryTabView with date-grouped list and edit/delete actions
- [ ] Create EditSetSheet modal for editing historical sets
- [ ] Add getOrCreateWorkoutForDate helper method to WorkoutService
- [ ] Update all navigation points to use new ExerciseDetailView
- [ ] Remove old ExerciseHistoryView after verifying new implementation