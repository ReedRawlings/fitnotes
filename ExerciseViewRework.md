# Engineering Tasks: Component Library & Workout View Alignment

## Phase 1: Build Component Library

### Task 1.1 - Create Components Directory
**Owner:** Engineering Lead
**Effort:** 30 min
**Dependencies:** None

Create folder structure:
```
FitNotes/
└── Components/
    ├── Components.swift (export file)
    ├── BaseCardView.swift
    ├── CardListView.swift
    ├── CardRowView.swift
    ├── SectionHeaderView.swift
    ├── EmptyStateView.swift
    ├── ProgressIndicatorView.swift
    ├── WorkoutHeaderCardView.swift
    ├── PrimaryActionButton.swift
    └── SecondaryActionButton.swift
```

### Task 1.2 - Implement BaseCardView
**Owner:** Engineer (Senior)
**Effort:** 45 min
**Dependencies:** Task 1.1

- Create reusable container component
- Implement white card styling (24pt corners, shadow)
- Test with preview on different content types
- Reference: Component Registry, "BaseCardView" section

### Task 1.3 - Implement CardListView
**Owner:** Engineer (Senior)
**Effort:** 1 hour
**Dependencies:** Task 1.2

- Create generic list container using BaseCardView
- Implement scrolling with LazyVStack
- Apply spacing system (12pt between items, 20pt padding)
- Test with sample data
- Verify performance with 50+ items
- Reference: Component Registry, "CardListView" section

### Task 1.4 - Implement CardRowView
**Owner:** Engineer (Mid)
**Effort:** 45 min
**Dependencies:** Task 1.2

- Create reusable row component
- Support title, subtitle, trailing content
- Apply subtle shadow (2pt radius)
- Make trailing content flexible for checkmarks, icons, etc.
- Reference: Component Registry, "CardRowView" section

### Task 1.5 - Implement SectionHeaderView
**Owner:** Engineer (Mid)
**Effort:** 30 min
**Dependencies:** None

- Create section header with optional action button
- Implement "Add" button styling
- Test with and without action
- Reference: Component Registry, "SectionHeaderView" section

### Task 1.6 - Implement EmptyStateView
**Owner:** Engineer (Mid)
**Effort:** 45 min
**Dependencies:** Task 1.5

- Create standardized empty state component
- Support icon, title, subtitle, optional action
- Center content vertically
- Make icon/title/subtitle configurable
- Reference: Component Registry, "EmptyStateView" section

### Task 1.7 - Implement ProgressIndicatorView
**Owner:** Engineer (Junior)
**Effort:** 30 min
**Dependencies:** None

- Create progress display (X/Y format)
- Show count + label in VStack
- Apply typography system
- Reference: Component Registry, "ProgressIndicatorView" section

### Task 1.8 - Implement WorkoutHeaderCardView
**Owner:** Engineer (Mid)
**Effort:** 1 hour
**Dependencies:** Task 1.2, Task 1.7

- Create workout header combining name, time, progress
- Use BaseCardView as container
- Integrate ProgressIndicatorView
- Add LinearProgressView for completion progress
- Reference: Component Registry, "WorkoutHeaderCardView" section

### Task 1.9 - Create Components Export File
**Owner:** Engineer (Junior)
**Effort:** 30 min
**Dependencies:** All 1.2-1.8

- Create Components.swift that exports all components
- Enable single import statement
- Add documentation comments
- Reference: Component Registry, "File Structure" section

---

## Phase 2: Apply Components to Workout View

### Task 2.1 - Replace Workout Header Container
**Owner:** Engineer (Senior)
**Effort:** 1.5 hours
**Dependencies:** Task 1.8

**File:** `FitNotes/DailyRoutineView.swift` - WorkoutView component

**Changes:**
- Remove gray system container around "Pull Day" / "Started time" / "0/3 exercises"
- Replace with WorkoutHeaderCardView
- Verify progress bar renders correctly
- Remove imports of systemGray6 styling

**Testing:**
- Verify header displays with active workout
- Check progress updates when exercises marked complete
- Confirm styling matches other cards

---

### Task 2.2 - Replace Exercise List with CardListView
**Owner:** Engineer (Senior)
**Effort:** 2 hours
**Dependencies:** Task 1.3, Task 1.4

**File:** `FitNotes/DailyRoutineView.swift` - WorkoutDetailView component

**Changes:**
- Remove SwiftUI `List` component showing exercises
- Replace with CardListView
- Extract exercise rows into CardRowView components
- Remove `.listStyle(PlainListStyle())`
- Move list into ScrollView wrapper if not already

**Specific Changes:**
- Before: `List { ForEach(sortedExercises) { ... } }.listStyle(...)`
- After: `CardListView(sortedExercises) { workoutExercise in ExerciseCardRow(...) }`

**Testing:**
- Verify exercises render as cards
- Check spacing between items (should be 12pt)
- Test checkmark interactions still work
- Verify delete buttons still functional

---

### Task 2.3 - Update Exercise Row Styling
**Owner:** Engineer (Mid)
**Effort:** 1.5 hours
**Dependencies:** Task 1.4

**File:** `FitNotes/DailyRoutineView.swift` - ActiveWorkoutExerciseRowView component

**Changes:**
- Convert to use CardRowView component
- Exercise name/sets/reps goes in title + subtitle
- Checkmark and delete buttons go in trailingContent
- Remove systemGray6 background (CardRowView handles it)
- Preserve all functionality (completion toggle, delete)

**Specific Layout:**
```
Title: Exercise name (e.g., "Bent-over Row")
Subtitle: "1 sets 10 reps 0 kg"
Trailing: Checkmark circle + Delete icon
```

**Testing:**
- Verify row appearance matches Figma mockup
- Test checkmark toggle works
- Test delete functionality
- Verify proper spacing/padding

---

### Task 2.4 - Apply Gradient Background to Workout Screen
**Owner:** Engineer (Junior)
**Effort:** 30 min
**Dependencies:** None

**File:** `FitNotes/DailyRoutineView.swift` - WorkoutView

**Changes:**
- Add blue gradient background matching Home/Settings tabs
- Apply to root VStack or ZStack wrapper
- Ensure gradient extends behind safe area

**Code:**
```swift
ZStack {
    LinearGradient(
        colors: [
            Color.blue.opacity(0.3),
            Color.blue.opacity(0.6)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    .ignoresSafeArea()
    
    // Rest of content
}
```

**Testing:**
- Verify gradient displays behind all content
- Check consistency with Home tab gradient

---

### Task 2.5 - Update Action Buttons
**Owner:** Engineer (Junior)
**Effort:** 45 min
**Dependencies:** Task 1.9 (existing components updated)

**File:** `FitNotes/DailyRoutineView.swift` - WorkoutDetailView component

**Changes:**
- Replace custom button styling with PrimaryActionButton ("Complete Workout")
- Replace custom button styling with SecondaryActionButton ("Pause Workout")
- Verify buttons sit in VStack with proper spacing
- Remove any custom background/shadow code

**Testing:**
- Verify buttons have correct colors/styling
- Test button tap actions work
- Check spacing from list and bottom of screen

---

### Task 2.6 - Update Empty State
**Owner:** Engineer (Junior)
**Effort:** 45 min
**Dependencies:** Task 1.6

**File:** `FitNotes/DailyRoutineView.swift` - WorkoutDetailView component

**Changes:**
- Replace custom empty state with EmptyStateView component
- Configure with appropriate icon/title/subtitle/action
- Remove custom VStack styling

**Testing:**
- Verify empty state displays when no exercises
- Check button action works
- Confirm styling matches other empty states

---

## Phase 3: Code Review & Documentation

### Task 3.1 - Code Review Checklist
**Owner:** Engineering Lead
**Effort:** As needed

Before merging any of Phase 2, verify:
- [ ] No raw List components remain
- [ ] No Form components used for layout
- [ ] All cards use BaseCardView or CardRowView
- [ ] No custom shadows/corners deviate from spec
- [ ] All spacing follows spacing system (20/12/8/4 pattern)
- [ ] Colors use established palette
- [ ] Component imports are clean

### Task 3.2 - Update Developer Documentation
**Owner:** Tech Lead
**Effort:** 1 hour
**Dependencies:** All Phase 1 & 2 complete

- Add Component Registry to project wiki/documentation
- Create PR checklist for future PRs (checklist in 3.1)
- Document import pattern
- Add design token file if not exists

### Task 3.3 - Team Training
**Owner:** Tech Lead
**Effort:** 30 min meeting

- Walk through Component Registry with team
- Show examples of correct vs incorrect usage
- Demonstrate import pattern
- Answer questions

---

## Success Criteria

### Phase 1 Complete When:
- [ ] All 9 components implemented and tested
- [ ] Components.swift export file works
- [ ] Zero warnings/errors on clean build
- [ ] Preview files show all components rendering correctly

### Phase 2 Complete When:
- [ ] Workout view uses only approved components
- [ ] Workout view background matches Home/Settings tabs
- [ ] Exercise list renders as cards (not List)
- [ ] All interactions (toggle, delete) work
- [ ] Buttons styled consistently
- [ ] Empty state uses component
- [ ] Visual comparison to Figma passes design review

### Overall Complete When:
- [ ] All Phase 1 & 2 criteria met
- [ ] Code review checklist passes
- [ ] Team trained on components
- [ ] Zero regressions in existing functionality

---

## Estimation Summary

| Phase | Task | Effort | Owner |
|-------|------|--------|-------|
| 1 | Directory setup | 30 min | Lead |
| 1 | BaseCardView | 45 min | Senior |
| 1 | CardListView | 1 hr | Senior |
| 1 | CardRowView | 45 min | Mid |
| 1 | SectionHeaderView | 30 min | Mid |
| 1 | EmptyStateView | 45 min | Mid |
| 1 | ProgressIndicatorView | 30 min | Junior |
| 1 | WorkoutHeaderCardView | 1 hr | Mid |
| 1 | Export file | 30 min | Junior |
| **Phase 1 Total** | | **6.5 hours** | |
| 2 | Workout header | 1.5 hrs | Senior |
| 2 | Exercise list | 2 hrs | Senior |
| 2 | Exercise rows | 1.5 hrs | Mid |
| 2 | Gradient background | 30 min | Junior |
| 2 | Action buttons | 45 min | Junior |
| 2 | Empty state | 45 min | Junior |
| **Phase 2 Total** | | **7.75 hours** | |
| 3 | Review checklist | Ongoing | Lead |
| 3 | Documentation | 1 hr | Lead |
| 3 | Team training | 30 min | Lead |
| **Phase 3 Total** | | **1.5 hours** | |
| **Grand Total**