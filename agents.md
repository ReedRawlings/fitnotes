# FitNotes iOS App - Agent Documentation

## Project Overview

FitNotes is a workout tracking iOS app built with SwiftUI and SwiftData. The app helps users track exercises, create routines, and monitor workout progress with a focus on simplicity and modern design.

## Development Context

This codebase is actively developed with Claude Code (both terminal and web interfaces). When making changes:
- Always run the app after modifications to verify functionality
- Check for compilation errors before committing changes
- Test affected views in the iOS simulator
- Verify SwiftData schema changes don't break existing data

## Architecture

### Data Models

**Core Models (SwiftData)**
- `Exercise`: Exercise definitions with muscle groups, equipment type, and metadata
- `Workout`: Daily workout sessions containing multiple exercises
- `WorkoutExercise`: Junction table linking exercises to specific workout sessions
- `WorkoutSet`: Individual set records with weight, reps, completion status
- `Routine`: Reusable exercise templates
- `RoutineExercise`: Exercises within routine templates with default sets/reps
- `BodyMetric`: User body measurements over time

**Key Relationships**
- Workouts contain multiple WorkoutExercises (one-to-many)
- Each WorkoutExercise references an Exercise by UUID
- WorkoutSets are tracked independently by exerciseId and date
- Routines contain RoutineExercises which reference Exercises

### Application State

**AppState (ObservableObject)**
- `selectedExercise`: Currently viewed exercise in modal
- `activeWorkout`: Tracks today's active workout session
- `selectedTab`: Current tab selection
- `weightUnit`: Global weight unit preference
- `showWorkoutFinishedBanner`: Success notification state

### Service Layer

**ExerciseService**
- `getLastSessionForExercise()`: Retrieve most recent sets for pre-population
- `getExerciseHistory()`: Fetch all historical sessions grouped by date
- `saveSets()`: Persist workout sets with date and completion status
- `getSetsByDate()`: Query sets for specific exercise and date

**WorkoutService**
- `createWorkout()`: Generate new workout session
- `addExerciseToWorkout()`: Add exercise to existing workout
- `getTodaysWorkout()`: Fetch current day's workout
- `getOrCreateWorkoutForDate()`: Ensure workout exists for date

**RoutineService**
- `createRoutine()`: Build new routine template
- `addExerciseToRoutine()`: Add exercise to routine with defaults
- `createWorkoutFromTemplate()`: Generate workout from routine
- `addExercisesFromRoutineToWorkout()`: Append routine exercises to existing workout

**ExerciseDatabaseService**
- `createDefaultExercises()`: Seed default exercise library
- Provides muscle group and equipment type constants

**ExerciseSearchService**
- `searchExercises()`: Filter exercises by query, category, equipment

**StatsService**
- `getWeeksActiveStreak()`: Calculate consecutive weeks with workouts
- `getTotalVolume()`: Sum all completed volume (weight × reps)
- `getDaysSinceLastLift()`: Time since last workout

## File Organization

### Key Files
- `ContentView.swift`: Main app structure with TabView and AppState
- `ExerciseDetailView.swift`: Exercise tracking modal with Track/History tabs
- `TrackTabView.swift`: Set tracking interface with inline inputs
- `DailyRoutineView.swift`: Workout view and related components
- `DesignSystem.swift`: Color, typography, spacing, animation constants
- `Components.swift`: Reusable UI components (buttons, cards, forms)
- `Exercise.swift`, `DailyRoutine.swift`, `Models.swift`: SwiftData model definitions
- `*Service.swift`: Business logic and data operations

### Design System
- `DESIGN-SYSTEM-V2.md`: Comprehensive design specification (reference this for all UI decisions)
- `DesignSystem.swift`: Swift implementation of design tokens

## View Hierarchy

### Navigation Structure

```
ContentView (TabView)
├── HomeView (Tab 0)
│   ├── StatsHeaderView
│   ├── RoutineCardView (expandable)
│   └── RoutineDetailView (sheet)
├── InsightsView (Tab 1)
├── WorkoutView (Tab 2)
│   ├── WorkoutDetailView
│   │   └── WorkoutExerciseRowView
│   ├── AddExerciseToWorkoutView
│   └── RoutineTemplateSelectorView
└── SettingsView (Tab 3)
    ├── RoutinesView
    │   ├── AddRoutineView
    │   └── RoutineDetailView
    └── ExercisesView
        ├── ExerciseListView
        └── AddExerciseView
```

### Key Views

**ExerciseDetailView** (Modal)
- Custom tab bar switching between Track and History
- Presented via `appState.selectedExercise`
- Dismisses automatically after save when opened from workout context

**TrackTabView**
- Inline numeric inputs for weight/reps (no picker wheel)
- Real-time persistence on every change via `persistCurrentSets()`
- Checkbox completion with haptic feedback
- Auto-advance to next incomplete exercise on completion
- Fixed save button at bottom

**WorkoutView**
- Date navigation with chevrons
- Lists today's exercises with set summaries
- Tap exercise row to open ExerciseDetailView modal
- Add exercise button always visible (fixed bottom)
- Reorderable exercise list with drag handles

**HomeView**
- Stats header (weeks active, total volume, days since last)
- Expandable routine cards with View/Start buttons
- Starts workout and switches to workout tab

## Design System Integration

The app follows a comprehensive design system documented in `DESIGN-SYSTEM-V2.md`:

**Colors**: Access via SwiftUI Color extensions (`.primaryBg`, `.secondaryBg`, `.accentPrimary`, etc.)

**Typography**: Use predefined Font extensions (`.exerciseTitle`, `.dataFont`, `.buttonFont`, etc.)

**Spacing**: Reference `Spacing` struct constants (`.xs`, `.md`, `.xl`, etc.)

**Animations**: Use predefined Animation extensions (`.quickFeedback`, `.standardSpring`, etc.)

**Component Patterns**: Follow established patterns for cards, buttons, modals, lists

All numeric data must use monospaced fonts. Primary actions use coral-orange gradient. Dark-first design with three-level depth hierarchy.

## Important Patterns

### Data Persistence
- Sets are saved immediately on every change (weight, reps, checkbox)
- `persistCurrentSets()` writes to database after each modification
- This ensures data survives app backgrounding or crashes

### Duplicate Prevention
- Check for existing exercises before adding to workouts/routines
- `WorkoutService.exerciseExistsInWorkout()` prevents duplicates
- Multi-select mode tracks selections in `Set<UUID>`

### Active Workout Flow
1. User starts routine from HomeView
2. Creates workout and sets `appState.activeWorkout`
3. Switches to workout tab automatically
4. Completing all sets in last exercise dismisses modal and shows banner

### Set Completion Detection
- When all sets marked complete, checks for next incomplete exercise
- If found, auto-advances to next exercise modal
- If none, shows "Workout Finished" banner

### Reordering
- Uses cached array for immediate UI updates
- Commits to database only on view disappear
- `hasUncommittedChanges` flag prevents premature saves

## Common Operations

### Adding Exercise to Workout
1. Present `AddExerciseToWorkoutView` with date and optional workout
2. User selects exercises (multi-select supported)
3. Creates workout if needed, adds `WorkoutExercise` records
4. No sets created initially - user adds via ExerciseDetailView

### Creating Workout from Routine
1. Call `RoutineService.createWorkoutFromTemplate()`
2. Copies all routine exercises to new workout
3. Hydrates initial sets based on template defaults or last session
4. Sets active workout state and navigates to workout tab

### Tracking Exercise Session
1. Open `ExerciseDetailView` from workout row or direct navigation
2. `TrackTabView` loads today's sets or prefills from last session
3. User modifies weight/reps inline, checks off completed sets
4. Save button persists all sets and ensures workout record exists

## Database Queries

**SwiftData Predicates**
- Use `#Predicate` macro for type-safe queries
- Filter by date ranges using `startOfDay` comparisons
- Sort with `SortDescriptor` for consistent ordering

**Common Patterns**
```swift
// Today's workout
#Predicate { workout in
    workout.date >= today && workout.date < tomorrow
}

// Exercise sets by date
#Predicate { set in
    set.exerciseId == exerciseId &&
    set.date >= startOfDay &&
    set.date < endOfDay
}
```

## Testing & Verification

When making changes:
1. Build the project to check for compilation errors
2. Run in iOS simulator to verify UI changes
3. Test affected user flows end-to-end
4. Verify database operations don't corrupt data
5. Check console for SwiftData errors or warnings

**Common Issues**
- SwiftData schema changes require database reset (delete app from simulator)
- Modal dismiss timing issues (use `DispatchQueue.main.asyncAfter` when needed)
- Exercise not found warnings indicate stale UUIDs or missing relationships

## Haptic Feedback

- Medium impact: Button taps, add/delete actions, drag reorder
- Success notification: Workout saved successfully
- Error notification: Save failures

## Accessibility

- All interactive elements have 44pt minimum tap targets
- Accessibility labels on buttons and inputs
- VoiceOver hints for completion checkboxes
- One-handed optimization with bottom-biased primary actions

## Error Handling

- Print errors to console for debugging
- Services return Bool success indicators
- SwiftData operations wrapped in do-catch blocks
- Graceful degradation when data unavailable (show empty states)

## Performance Considerations

- Lazy loading with `LazyVStack` for long lists
- Client-side filtering for exercise search (all in memory)
- Cached arrays for reorderable lists to avoid database thrashing
- Single database save per user action (batched when possible)

## Code Style

- Follow existing patterns for consistency
- Use `MARK:` comments to organize code sections
- Keep view files focused (extract complex logic to services)
- Prefer composition over inheritance
- Use SwiftUI best practices (avoid force unwrapping, use proper state management)