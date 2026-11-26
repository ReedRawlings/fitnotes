# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the project
xcodebuild -scheme FitNotes -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
xcodebuild test -scheme FitNotes -destination 'platform=iOS Simulator,name=iPhone 17'

# Run a single test file
xcodebuild test -scheme FitNotes -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:FitNotesTests/FitNotesTests

# Open in Xcode (for running/debugging)
open FitNotes.xcodeproj
```

## Architecture Overview

FitNotes is a workout tracking iOS app built with **SwiftUI + SwiftData**. No external dependencies—uses only Apple native frameworks.

### State Management Pattern

**AppState (ObservableObject)** - Central app-wide state injected at root level:
- `selectedExercise` - Currently viewed exercise modal
- `activeWorkout` - Current workout session
- `selectedTab` - Tab navigation (0=Home, 1=Insights, 2=Workout, 3=Settings)
- `weightUnit` - Global unit preference (kg/lbs)

**OnboardingState** - 5-screen onboarding flow state (Welcome, Preferences, First Exercise setup, two feature explainers), persists via UserDefaults.

### Service Layer

Singleton pattern with ModelContext injection:
- **ExerciseService** - Exercise CRUD, history queries, set persistence
- **DailyRoutineService** - Workout creation/management
- **RoutineService** - Routine templates and scheduling
- **InsightsService** - Analytics (volume trends, streaks, PRs)
- **StatsService** - Volume calculations, streak data

### Data Models (SwiftData)

Key relationships:
- `Workout` → `WorkoutExercise` (one-to-many)
- `WorkoutExercise` → `Exercise` (by UUID reference)
- `WorkoutSet` grouped by `exerciseId + date` (not workoutId)
- `Routine` → `RoutineExercise` (cascade delete)

### View Hierarchy

```
ContentView (TabView)
├── HomeView         - Stats + routine cards
├── InsightsView     - Analytics charts
├── WorkoutView      - Daily workout tracking
└── SettingsView     - Routines, exercises, preferences
    └── ExercisesView/RoutinesView
```

**ExerciseDetailView** - Modal presented via `appState.selectedExercise`, contains Track/History tabs.

## Key Patterns

### Real-Time Persistence
Sets save immediately on every change via `persistCurrentSets()`. No manual save button for internal data—this ensures data survives app backgrounding. `ExerciseService.saveSets` diffs sets in place (stable UUIDs, one save, preserved notes/duration/distance)—do NOT revert it to delete-and-reinsert.

### Derived Stats Stay Out of `body`
HomeView, InsightsView, and PreferencesView cache expensive aggregations (volume, PRs, streaks) in `@State`, refreshed on appear/tab-switch/period-change. Computing them in `body` or computed properties re-runs full-history fetches on every AppState publish (i.e., every tap) and was the cause of app-wide tap latency. Keep `@Query` properties predicate-filtered—never fetch whole tables.

### E1RM and PRs
`E1RMCalculator.fromSession` returns the best (highest) E1RM among completed sets; a 1-rep set's E1RM is the weight itself; >10 reps yields no estimate (Epley validity). A PR is a new best WEIGHT for an exercise (kg-normalized) — not set volume: 225×2 outranks 150×20. Reps-only exercises (`Exercise.trackingType == .repsOnly`, e.g. jump rope) never store a weight; their PR is best reps and progression only ever recommends +1 rep. Insights PR lists are still weight-only. Covered by unit tests in `FitNotesTests`. There is no "needs rest" recommendation — deliberately lighter sessions are not a failure state.

### SwiftData Predicates
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

### Supersets
`WorkoutExercise`/`RoutineExercise.supersetGroupId`: ADJACENT exercises (by `order`) sharing an id form a superset. All grouping logic lives in `SupersetLayout` (`Models/Superset.swift`, unit-tested); never compare group ids directly in views. The link button on a row toggles "superset with the next exercise". In TrackTabView, checking a set mid-round skips the rest timer and opens the next member; the last member starts the rest and goes back to the first member with sets left. Links are copied routine ↔ workout.

### Finishing a Workout
Workouts are only finished by the user tapping Finish Workout in WorkoutView, which sets `Workout.finishedAt` (and asks first if sets are unchecked). Checking the last set never finishes a workout: TrackTabView opens the next exercise with sets left (below first, then wrapping to earlier ones), or returns to the workout list when everything is checked.

### Reordering
Uses cached arrays for immediate UI updates. Commits to database only on view disappear.

## Design System

Colors via SwiftUI extensions: `.primaryBg`, `.secondaryBg`, `.accentPrimary`
Typography via Font extensions: `.exerciseTitle`, `.dataFont`, `.buttonFont`
Spacing via `Spacing` struct: `.xs`, `.md`, `.xl`
Animations: `.quickFeedback`, `.standardSpring`

All numeric data uses monospaced fonts. Primary actions use coral-orange gradient. Dark-first design.

## Common Issues

- **SwiftData schema changes need a migration stage** - The store is versioned: `FitNotesSchemaV1` (frozen nested model copies in `Models/SchemaV1.swift`, never edit), `FitNotesSchemaV2` (the live models) and `FitNotesMigrationPlan` in `FitNotesApp.swift`. Any @Model change must freeze the current shape of the changed models (plus any model whose relationships point at them) into a new `SchemaVN` file, add the version and a migration stage, and extend `SchemaMigrationTests`. If the store can't be opened it's moved to `Documents/RecoveredStores/`; never delete user data. In the simulator you can still just delete the app.
- **Modal dismiss timing** - Use `DispatchQueue.main.asyncAfter` when needed
- **Exercise not found warnings** - Indicate stale UUIDs or missing relationships

## Development Notes

- The app is fully free and 100% local: no premium/StoreKit gating, no accounts/auth, no backend or sync (Supabase was removed 2026-08; prefer CloudKit if sync ever returns)
- DEBUG builds auto-seed demo data via `DevDataSeeder.seedIfNeeded()`
- Database stored at `{Documents}/FitNotes.sqlite`
- CloudKit disabled (`.none`)
- RestTimerWidget provides only the rest-timer Live Activity (the Xcode template widget and control were removed)
- iPhone-only, portrait-only for v1 (`TARGETED_DEVICE_FAMILY = 1`)
- App name, support URL and privacy-policy URL live in `AppInfo` (`Utilities/AppInfo.swift`). Support and privacy pages are `docs/` served by GitHub Pages at reedrawlings.github.io/fitnotes; the display name also lives in the `INFOPLIST_KEY_CFBundleDisplayName` build setting
- Privacy manifests: `FitNotes/PrivacyInfo.xcprivacy` (UserDefaults CA92.1) and `RestTimerWidget/PrivacyInfo.xcprivacy`. Update them if you add a required-reason API
- Settings → Preferences ends with `AboutSettingsSection` (CSV export via `DataExportService`, in-app privacy policy, support, version)
- Notification permission is requested the first time a rest timer starts, not at launch
