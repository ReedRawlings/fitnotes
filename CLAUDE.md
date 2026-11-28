# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository. Studio-wide rules (approvals, health-claim wording, brand voice) live in `../../CLAUDE.md`; status and release blockers live in `ROADMAP.md`.

## Product

**Progressive Lift** (the repo, scheme, targets and Swift module are still called FitNotes) is a free, private gym log for iPhone. You log sets and reps fast with a custom number pad. It suggests your next weight when you hit the top of your rep range (progressive overload), tracks estimated 1RM and weight PRs, and offers routines with weekday or every-N-days schedules, supersets, a plate calculator, a rest timer with a Live Activity, insights (volume, streaks, muscle groups, recovery heatmap, goals, year in review) and CSV export. It's for people who lift weights and want a no-account, no-ads logbook. **Monetization: none.** It's fully free, with no StoreKit purchases, ads or analytics. StoreKit is imported only for `requestReview`. Paywall, StoreKit subscriptions, MailerLite and Supabase auth all existed in 2025 and were removed in 2026-08.

## Store facts (verified in project.pbxproj, 2026-11-26)

| | |
|---|---|
| Display name | `Progressive Lift` (`INFOPLIST_KEY_CFBundleDisplayName`, `AppInfo.displayName`). Planned App Store name: `Progressive Lift: Gym Log` (`appstore/listing.md`) |
| Bundle ID | `Future-Selves.FitNotes`. Widget: `Future-Selves.FitNotes.RestTimerWidget` |
| Version / build | `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 19` (all 8 build configs must match; bump every config) |
| Min iOS | 17.0. iPhone only (`TARGETED_DEVICE_FAMILY = 1`), portrait only |
| Team | `6N75SAQ2KX`, automatic signing. Copyright "Future Selves" |
| iCloud container | `iCloud.Future-Selves.FitNotes` (CloudKit, private DB) |
| Capabilities | iCloud/CloudKit, push (`aps-environment`, needed for CloudKit silent pushes), `remote-notification` background mode, Live Activities (`NSSupportsLiveActivities`), local notifications |
| Not used | HealthKit, App Groups, home-screen widgets, IAP, third-party SDKs |
| Category | Health & Fitness (`LSApplicationCategoryType`) |
| Encryption | `ITSAppUsesNonExemptEncryption = NO` |
| Support / privacy URLs | https://reedrawlings.github.io/fitnotes/ and `/privacy.html` (from `docs/`, GitHub Pages) |
| App Store Connect record / Apple ID | "Progressive Lift: Gym Log", Apple ID 6754669063, version 1.0 in Prepare for Submission; builds 17 to 19 in TestFlight |

## Repo layout

- `FitNotes/App/`: `FitNotesApp.swift` (ModelContainer, schema versions, migration plan, store recovery) and `ContentView.swift` (~2,700 lines: TabView, Home, Insights, Routines, Settings, Preferences views all live here)
- `FitNotes/Models/`: `Exercise.swift`, `DailyRoutine.swift` (Routine, Workout, RoutineExercise, WorkoutExercise, WorkoutSet), `Models.swift` (FitnessGoal, BodyMetric, UserPreferences), `Superset.swift`, frozen `SchemaV1.swift` / `SchemaV2.swift`, onboarding models
- `FitNotes/Services/`: singleton services (see below), plus `SyncDeduplicator.swift` (also holds `CloudSync`), `DevDataSeeder.swift`, `DataExportService.swift`, `ExerciseDatabaseService.swift` (built-in exercise library)
- `FitNotes/Views/`: `Exercise/` (detail, Track/History tabs, stats), `Workout/DailyRoutineView.swift`, `Insights/`, `Onboarding/`, `Routine/`, `AboutSettingsSection.swift`
- `FitNotes/Utilities/`: rest timer and Live Activity attributes, custom numeric keyboard, `PlateCalculator`, `ReviewPrompt`, `AppInfo`
- `FitNotes/Components/`: `DesignSystem.swift`, shared `Components.swift`
- `RestTimerWidget/`: the widget extension, which holds only the rest-timer Live Activity
- `FitNotesTests/FitNotesTests.swift`: ~51 unit tests (E1RM/PR, progression, supersets, schema migration, sync dedup, review prompt). `FitNotesUITests/` contains only template tests
- `appstore/`: `listing.md` (full App Store Connect draft), `privacy.html` (an older copy that differs from `docs/`), `Screenshots/6.9in` and `6.3in` (6 PNGs each)
- `docs/`: GitHub Pages support and privacy pages. These are public, so keep them in sync with in-app `PrivacyPolicyView` copy
- Stale docs: `agents.md` (older architecture notes; mentions services such as WorkoutService that no longer exist), `ONBOARDING-SCREENS-SPEC.md` (historical; flow is now 5 screens), `.cursor/plans/` (old plan), `Readme.md` and `DesignSYSTEM.md` (both empty). Trust the code and this file over them

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

# Screenshot data (DEBUG + simulator only): launch with the -screenshotData argument for ~13 weeks of history
```

- There is one shared scheme, `FitNotes`. The `.gitignore` expects local builds to use `-derivedDataPath .deriveddata`.
- If iPhone 17 isn't installed, list simulators with `xcrun simctl list devices available`.
- App Store uploads go through fastlane with the owner's local App Store Connect API key (see the studio CLAUDE.md). Lanes: `fastlane check` (key and build-number check, no upload) and `fastlane upload` (Release archive to TestFlight); see `fastlane/Fastfile`.

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

- **SwiftData schema changes need a migration stage** - The store is versioned: `FitNotesSchemaV1` and `FitNotesSchemaV2` (frozen nested model copies in `Models/SchemaV1.swift` / `SchemaV2.swift`, never edit), `FitNotesSchemaV3` (the live models) and `FitNotesMigrationPlan` in `FitNotesApp.swift`. Any @Model change must freeze the current shape of the changed models (plus any model whose relationships point at them) into a new `SchemaVN` file, add the version and a migration stage, and extend `SchemaMigrationTests`. If the store can't be opened it's moved to `Documents/RecoveredStores/`; never delete user data. In the simulator you can still just delete the app.
- **Modal dismiss timing** - Use `DispatchQueue.main.asyncAfter` when needed
- **Exercise not found warnings** - Indicate stale UUIDs or missing relationships

## Development Notes

- The app is fully free with no premium/StoreKit gating, no accounts/auth and no backend of its own (Supabase was removed 2026-08). Sync goes only through the user's private iCloud
- DEBUG builds auto-seed demo data via `DevDataSeeder.seedIfNeeded()`
- Database stored at `{Documents}/FitNotes.sqlite`
- iCloud sync via SwiftData + CloudKit private database (`iCloud.Future-Selves.FitNotes`, `CloudSync` in `Services/SyncDeduplicator.swift`; off under XCTest). Models must stay CloudKit-compatible: no `@Attribute(.unique)`, a default on every non-optional property, to-many relationships optional with an explicit inverse (`Routine/Workout.exerciseItems`, wrapped by non-optional `exercises`). Test containers pass `cloudKitDatabase: .none`
- Without uniqueness, devices can create duplicates before syncing. `SyncDeduplicator` merges same-name built-in exercises (remapping every `exerciseId`), same-day workouts and extra `UserPreferences`, keeping the oldest record so devices agree. It runs at launch, on scene activation and after remote changes
- Every CloudKit schema change must be deployed from Development to Production in the CloudKit Console before a TestFlight/App Store build ships it
- DEBUG demo seeding runs only in the simulator, so a debug build on a phone never syncs demo data to iCloud
- RestTimerWidget provides only the rest-timer Live Activity (the Xcode template widget and control were removed)
- iPhone-only, portrait-only for v1 (`TARGETED_DEVICE_FAMILY = 1`)
- App name, support URL and privacy-policy URL live in `AppInfo` (`Utilities/AppInfo.swift`). Support and privacy pages are `docs/` served by GitHub Pages at reedrawlings.github.io/fitnotes; the display name also lives in the `INFOPLIST_KEY_CFBundleDisplayName` build setting
- Privacy manifests: `FitNotes/PrivacyInfo.xcprivacy` (UserDefaults CA92.1) and `RestTimerWidget/PrivacyInfo.xcprivacy`. Update them if you add a required-reason API
- Settings → Preferences ends with `AboutSettingsSection` (CSV export via `DataExportService`, in-app privacy policy, support, version)
- Notification permission is requested the first time a rest timer starts, not at launch

## Gotchas

- **Naming:** the user-facing name is "Progressive Lift". Never add "FitNotes" to user-visible strings. "FitNotes" is also the name of an established third-party workout log (not verified here), so it can't be the store name.
- **Secrets:** git history (commits `fb7b1a6`/`21346dd`, 2025-12-26, until `207dc0a`) contains a Supabase project URL and an `sb_secret_` key in `FitNotes/Config/Secrets.swift`. The GitHub repo is **public**. The key must be revoked in Supabase (owner action). Never re-add secrets: `Secrets.swift` and `*.xcconfig` are gitignored.
- **CloudKit sync is on by default** (`CloudSync.isEnabled` reads UserDefaults `iCloudSyncEnabled`, default true). No UI sets that key yet. Turning it off would need a relaunch.
- `aps-environment` is `development` in the entitlements. Automatic signing switches it to production on App Store export. Don't hand-edit it.
- `.DS_Store` and `xcuserdata/` files are tracked in git despite `.gitignore`, so they show up as modified constantly. Don't commit them.
- The design is dark-only (`.preferredColorScheme(.dark)` at the root).
- `ContentView.swift` is huge. Search by `struct <Name>View` rather than reading it whole.
- Don't start `xcodebuild` while other agents in the studio are building (shared machine).
