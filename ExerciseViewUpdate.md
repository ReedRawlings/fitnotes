# Exercise Detail View Architecture & Design

## Overview

The Exercise Detail View is the central hub for viewing and tracking an individual exercise. Users access it from any context (routine template, daily workout view, exercise library) and see the same unified interface. The view has two tabs: **Track** (for current workout logging) and **History** (for past sessions).

---

## Data Model Requirements

### Current State

The app must track the following per exercise per day:

- **Exercise ID** (UUID)
- **Date** (associated workout date)
- **Sets** (integer)
- **Reps** (integer)
- **Weight** (double, in kg)

This data is already captured in `WorkoutSet` but needs to be surfaced and editable through the Exercise Detail View.

### Last Session Lookup

When users open Exercise Detail or add an exercise to a workout, the system must query the most recent `WorkoutSet` records for that exercise to pre-populate the Track tab. The `ExerciseService.getLastSessionForExercise()` method already does this—it should be used consistently.

---

## View Structure

### Exercise Detail View (Parent)

**Entry Points:**
- From routine template exercise list (tapping an exercise)
- From daily workout view (tapping an exercise in the workout)
- From exercise library/settings (tapping an exercise)

All entry points open the same view with no context-specific behavior changes.

**Header Section:**
- Exercise name (large, bold)
- Exercise category badge (e.g., "Chest")
- Exercise type (e.g., "Strength") — shown but not prominent

**Tab Navigation:**
- Two segmented tabs: "Track" | "History"
- Default to "Track" tab on open

---

## Tab 1: Track

### Purpose
Display input fields for the current workout day, pre-populated with the last session's data. User adjusts numbers as they work through their sets during the day.

### Layout

**Current Metrics Section (Read-only display of last session):**
- Headline: "Last Session"
- Display: "X sets × Y reps @ Z kg" 
- If no history exists, show placeholder: "No history yet"

**Add Set Button:**
- Prominent button (green/accent color) to add a new set row
- Label: "Add Set" or "+" icon

**Individual Set Rows (Editable List):**
- Each row contains:
  - **Weight** input field (double, with "kg" unit label)
  - **Reps** input field (integer)
  - **Delete** button (trash icon or "-" button)
- User can add as many sets as needed
- Each set can have different weight and reps (e.g., Set 1: 185kg × 5, Set 2: 185kg × 3, Set 3: 175kg × 8)
- Sets are displayed in order added (Set 1, Set 2, Set 3, etc.)
- User can delete individual sets mid-workout if needed

**Example Display:**
```
ADD SET button

Set 1: [Weight: 185] kg  [Reps: 5]  [Delete]
Set 2: [Weight: 185] kg  [Reps: 3]  [Delete]
Set 3: [Weight: 175] kg  [Reps: 8]  [Delete]

ADD SET button (appears again at bottom for convenience)

[SAVE button]
```

**Save Button:**
- Located at bottom of Track tab
- When tapped, persists all entered/modified sets to history for today's date
- After save, user receives visual confirmation (toast/alert)
- If any sets already exist for today, they are replaced with the new data
- If user augments the workout mid-day and saves, the new data overwrites what was previously saved

### Behavior

**On View Load (Track Tab):**
- Query `ExerciseService.getLastSessionForExercise()` for this exercise
- If history exists, pre-populate a single set row with last session's data (weight and reps from most recent set)
- If no history, populate one empty set row with placeholders (0 weight, 0 reps)
- User can immediately add more set rows or modify existing ones

**User Adds/Edits Sets:**
- Fields are live-editable as user works through their workout
- User can add unlimited sets via "Add Set" button
- User can delete individual sets anytime
- No data is persisted until user taps Save

**User Taps Save:**
- All current set rows are written to history tied to today's date
- If sets already exist for this exercise today, they are replaced entirely
- Confirmation message shown to user
- Track tab remains open (user can continue editing if needed)

**Navigation Away:**
- If user leaves Track tab without saving, data is lost (no persistence)
- If user navigates back to Track tab, it reloads with the most recent saved data or last session data

---

## Tab 2: History

### Purpose
Display all past sessions for this exercise, grouped by date, with full data for each set. Users can edit or delete individual history entries.

### Layout

**History List:**
- Group by date (most recent first)
- Date header format: "FRIDAY, JANUARY 12" (uppercase, clear)
- Under each date header, list all sets from that day:
  - Format per set: "X kg × Y reps"
  - Each set should be a row/card

**Example Structure:**
```
FRIDAY, JANUARY 12
  105.0 kg × 5 reps
  102.5 kg × 5 reps
  100.0 kg × 5 reps
  80.0 kg × 5 reps
  60.0 kg × 5 reps

TUESDAY, JANUARY 9
  92.5 kg × 3 reps
  92.5 kg × 3 reps
  92.5 kg × 3 reps
  75.0 kg × 12 reps
  75.0 kg × 12 reps

SUNDAY, JANUARY 7
  80.0 kg × 5 reps
```

### Interactions

**Tap on a Set:**
- Opens edit modal/sheet for that specific set
- Modal shows: Weight input field, Reps input field
- User can modify weight and/or reps
- Save button commits changes
- Cancel button dismisses without saving

**Delete Set:**
- Swipe or long-press option to delete individual set
- Confirm deletion dialog
- If all sets for a day are deleted, remove the date section from display

**Edit Set (Modal):**
- Modal title: "Edit Set"
- Fields: Weight (kg), Reps
- Buttons: [Cancel] [Save]
- When user taps Save, the set is updated immediately in history and SwiftData
- Modal dismisses and History tab refreshes to show updated data

---

## Navigation & Context

### From Routine Template
- User taps an exercise in the routine detail view
- Exercise Detail View opens
- Track tab shows last session data
- User can review history but cannot log (or can log, but it's not tied to today's workout)
- **Decision needed:** Should Track tab be disabled/hidden when viewing from routine context? Or allow logging anytime?

### From Daily Workout View
- User taps an exercise in their daily workout
- Exercise Detail View opens
- Track tab is active and editable
- User adjusts values during workout
- At end of day, values are saved to history with today's date

### From Exercise Library
- User taps an exercise in settings/library
- Exercise Detail View opens
- Track tab shows last session data
- History is fully visible and editable
- User can manually log or edit past data anytime

---

## Data Persistence

### At End of Day
When the date changes or the app is backgrounded:
1. Query the current date
2. Check if there's a `WorkoutSet` entry for today for this exercise
3. If no entry exists, create one with the current Track tab values
4. If entry exists, update it with Track tab values
5. Write to SwiftData

### Editing History
When user edits a set in History tab:
1. Update the specific `WorkoutSet` record
2. Save immediately to SwiftData
3. Refresh History tab display

### Deleting History
When user deletes a set:
1. Remove the `WorkoutSet` from SwiftData
2. Refresh History tab display

---

## UI/UX Standards

**Colors & Styling:**
- Follow existing app design system (blue gradient backgrounds, white cards, etc.)
- Input fields use standard iOS styling (RoundedBorderTextFieldStyle or custom)
- Buttons: Primary action (green/accent) for "Save" in edit modals

**Spacing:**
- Consistent 16-20px padding between sections
- 12px spacing between form fields
- 8px spacing between set rows

**Typography:**
- Exercise name: Large title, bold
- Section headers: Subheadline, bold
- Set data: Body text, regular
- Date headers: Caption, uppercase

**Empty States:**
- If no history exists: "No history yet. Complete a workout to see your progress."
- If exercise has never been done: Show in Current Metrics section

---

## Engineering Considerations

### State Management
- Exercise Detail View needs to track:
  - Current exercise data (from passed context)
  - Track tab values (sets, reps, weight)
  - History list (fetched from SwiftData)
  - Edit mode state (which set is being edited, if any)

- Use `@State` for Track tab inputs
- Use `@Query` for History tab data (auto-updates on SwiftData changes)

### Performance
- History list should be lazy-loaded or paginated if exercise has 100+ sessions
- Track tab should not re-query history on every value change (only on load)

### Error Handling
- If SwiftData save fails at end of day, show alert but don't lose user input
- If history fetch fails, show empty state with retry option
