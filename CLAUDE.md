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

**OnboardingState** - 17-screen onboarding flow state, persists via UserDefaults.

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
Sets save immediately on every change via `persistCurrentSets()`. No manual save button for internal data—this ensures data survives app backgrounding.

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

### Reordering
Uses cached arrays for immediate UI updates. Commits to database only on view disappear.

## Design System

Colors via SwiftUI extensions: `.primaryBg`, `.secondaryBg`, `.accentPrimary`
Typography via Font extensions: `.exerciseTitle`, `.dataFont`, `.buttonFont`
Spacing via `Spacing` struct: `.xs`, `.md`, `.xl`
Animations: `.quickFeedback`, `.standardSpring`

All numeric data uses monospaced fonts. Primary actions use coral-orange gradient. Dark-first design.

## Common Issues

- **SwiftData schema changes require database reset** - Delete app from simulator
- **Modal dismiss timing** - Use `DispatchQueue.main.asyncAfter` when needed
- **Exercise not found warnings** - Indicate stale UUIDs or missing relationships

## Development Notes

- DEBUG builds auto-seed demo data via `DevDataSeeder.seedIfNeeded()`
- Database stored at `{Documents}/FitNotes.sqlite`
- CloudKit disabled (`.none`)
- RestTimerWidget provides Live Activity for rest timer notifications
