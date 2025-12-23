# FitNotes Onboarding Screens Specification

## Overview

The onboarding flow is 14 screens divided into three phases: Education (screens 1-5), Personalization (screens 6-8), and Setup & Conversion (screens 9-14). The flow builds understanding of progressive overload, collects user preferences, then guides them through their first setup.

---

## Phase 1: Education (Screens 1-5)

These screens establish the value of progressive overload before asking anything from the user. Screens 5-7 from the original spec (research points and expert quotes) have been combined into a single scrolling research page.

### Screen 1: Welcome

**Purpose:** Warm introduction centered on the user's journey

**Content Direction:**
- Headline: Welcome to FitNotes
- Body copy should position the user as the protagonist starting their fitness journey
- Tone: Encouraging, personal, not corporate
- Avoid feature lists—this is emotional, not functional

**SF Symbol:** `figure.walk` or `heart.fill`

---

### Screen 2: Progressive Overload Introduction

**Purpose:** Explain what progressive overload is

**Content Direction:**
- Simple definition of progressive overload (gradually increasing demands on muscles)
- Keep it approachable—no jargon
- One clear concept per screen

**SF Symbol:** `arrow.up.right` or `chart.line.uptrend.xyaxis`

---

### Screen 3: Benefits of Progressive Overload

**Purpose:** What the user gains by following this approach

**Content Direction:**
- Concrete benefits: strength gains, muscle growth, measurable progress
- Frame as outcomes, not features
- Keep to 3 benefits maximum

**SF Symbol:** `trophy.fill` or `star.fill`

---

### Screen 4: Long-Term Vision (6-12 Months)

**Purpose:** Paint a picture of future results

**Content Direction:**
- Describe realistic transformations over 6-12 months
- Use specific but achievable examples (not "get shredded" but "lift 50% more than today")
- Help them visualize their future self

**SF Symbol:** `calendar` or `clock.arrow.circlepath`

---

### Screen 5: Science-Backed Benefit

**Purpose:** One major research-backed benefit

**Content Direction:**
- Single compelling statistic or research finding about progressive overload
- Source it (study name or institution)
- Make it memorable and shareable

**SF Symbol:** `brain.head.profile` or `chart.bar.doc.horizontal`

---

### Screen 6: Expert Quote

**Purpose:** Social proof from authority figure

**Content Direction:**
- Quote from a respected coach, trainer, or fitness influencer about progressive overload
- Include name and credential/title
- Keep quote concise (2-3 sentences max)

**Design Note:** Consider different visual treatment—quote marks, different typography weight

**SF Symbol:** `quote.bubble.fill` or `person.fill.checkmark`

---

### Screen 7: Final Research Point

**Purpose:** One more piece of evidence to cement the concept

**Content Direction:**
- Additional research finding focused on progressive lifting
- Different angle from Screen 5 (e.g., if Screen 5 was about strength, this could be about injury prevention or longevity)
- Reinforce that this approach is proven

**SF Symbol:** `doc.text.magnifyingglass` or `checkmark.seal.fill`

---

## Phase 2: Personalization (Screens 6-8)

These screens collect user information to customize the experience.

### Screen 6: Experience Level

**Purpose:** Understand where the user is starting

**Input Type:** Single-select from 4 options

**Options:**
- Brand New (never lifted weights)
- Beginner (some experience, inconsistent)
- Intermediate (regular lifting, 6+ months)
- Advanced (years of consistent training)

**Data Usage:** Determines Screen 12 content (routines vs. settings guidance)

**SF Symbol:** `figure.strengthtraining.traditional`

---

### Screen 7: Settings (Unit & Rest Timer)

**Purpose:** Set user's preferred defaults

**Input Type:** Segmented control for unit, picker for rest timer

**Options:**
- Weight Unit: kg / lbs
- Default Rest Timer: 0:30 - 5:00 (default 1:30)

**SF Symbol:** `gearshape.2.fill`

---

### Screen 8: Primary Lifts

**Purpose:** Which lifts they're focused on

**Input Type:** Multi-select checklist

**Options:** Common compound lifts (bench press, squat, deadlift, overhead press, barbell row, etc.) plus option to add custom

**Data Usage:**
- Screen 9 will use one of their selections for the walkthrough
- Informs default routine suggestions

**SF Symbol:** `dumbbell.fill`

---

## Phase 3: Setup & Conversion (Screens 9-14)

These screens teach app usage and convert to paying users.

### Screen 9: Guided Setup Walkthrough

**Purpose:** Hands-on tutorial using one of their selected lifts from Screen 8

**Interaction:** Interactive—user must complete setup

**Flow:**
1. Take one lift from their Screen 8 selections
2. Walk through ALL available settings for that exercise in detail
3. Have them set up a progressive overload target (this step is mandatory)
4. Other settings are optional but shown

**Design Note:** This is a longer screen—may need sub-steps or an inline tutorial format rather than static card

**SF Symbol:** `gearshape.fill` or `slider.horizontal.3`

---

### Screen 10: Progress Demonstration

**Purpose:** Show how the app pushes them forward

**Content Direction:**
- Demonstrate the progression tracking visually
- Show how the app will notify/nudge them when it's time to increase weight
- Preview the feeling of hitting goals

**Design Note:** Could use animation or before/after visualization

**SF Symbol:** `arrow.up.forward.circle.fill` or `bell.badge.fill`

---

### Screen 11: Analytics Preview

**Purpose:** Overview of tracking and insights features

**Content Direction:**
- Show example charts/graphs (volume trends, PR tracking, muscle balance)
- Emphasize data-driven progress
- This sells the value of consistent logging

**SF Symbol:** `chart.xyaxis.line` or `waveform.path.ecg`

---

### Screen 12: Experience-Based Guidance

**Purpose:** Tailored next steps based on Screen 6 answer

**Conditional Content:**

**If Brand New or Beginner:**
- Offer curated starter routines
- Present 2-3 beginner-friendly options they can start immediately
- Emphasis on simplicity and getting started

**If Intermediate or Advanced:**
- Direct them to Settings > Routines section
- Mention example routines available there
- Emphasis on customization and flexibility

**SF Symbol:** `list.bullet.rectangle` or `folder.fill`

---

### Screen 13: Email Capture

**Purpose:** Lead generation with value exchange

**Content Direction:**
- Offer a guide on progressive lifting (origins, science, detailed benefits)
- Clear value proposition for signing up
- Email input field
- Skip option must be visible

**Design Note:** Don't make this feel like a gate—keep skip prominent

**SF Symbol:** `envelope.fill` or `book.fill`

---

### Screen 14: Commitment + Paywall

**Purpose:** Emotional commitment moment + monetization

**Two Parts:**

**Part A - Commitment Question:**
- "Are you ready to commit to getting the most fit you've ever been?"
- Yes/Let's Go CTA

**Part B - Paywall:**
- Light paywall format (not aggressive)
- Clear free vs. premium feature comparison
- Free tier should feel usable, premium should feel valuable
- Continue with free option clearly visible

**Design Notes:**
- Don't dark-pattern the free option
- Premium features should align with what was shown in previous screens (analytics, etc.)

**SF Symbol:** `checkmark.circle.fill` (commitment), `crown.fill` (premium)

---

## Technical Implementation Notes

### Data Model

The `OnboardingPage` model supports various screen types:

```swift
struct OnboardingPage {
    let id: UUID
    let type: OnboardingPageType
    let title: String
    let subtitle: String?
    let description: String?
    let systemImage: String
    let options: [OnboardingOption]?  // For select screens
    let isRequired: Bool  // Can this screen be skipped?
    let order: Int
}

enum OnboardingPageType {
    case static           // Screens 1-4, 10, 11
    case research         // Screen 5 (combined research/quotes)
    case singleSelect     // Screen 6
    case settings         // Screen 7
    case multiSelect      // Screen 8
    case interactive      // Screen 9
    case conditional      // Screen 12
    case emailCapture     // Screen 13
    case paywall          // Screen 14
}
```

### State Management

Store collected data in `AppStorage` or a dedicated `OnboardingState` object:

- `experienceLevel`: String (brand_new, beginner, intermediate, advanced)
- `primaryLifts`: [UUID] (exercise IDs)
- `weightUnit`: String (kg, lbs)
- `defaultRestTimer`: Int (seconds)
- `emailCaptured`: Bool
- `selectedPlan`: String (free, premium)
- `hasCompletedOnboarding`: Bool

### Navigation Behavior

- Screens 1-5: Linear flow, swipe or Next button
- Screen 6: Must make selection to proceed
- Screen 7: Settings with defaults, can proceed immediately
- Screen 8: Must select at least one lift
- Screen 9: Must complete required setup step
- Screens 10-11: Linear, informational
- Screen 12: Content changes based on Screen 6 answer
- Screen 13: Allow skip
- Screen 14: Terminal screen—completes onboarding

### Design System Compliance

All screens must follow DESIGN-SYSTEM-V2.md:

- Dark background (`#0A0E14`)
- Coral-orange primary CTA (`#FF6B35` gradient)
- SF Pro Display for titles, SF Pro Text for body
- Primary CTA in bottom third of screen
- 44pt minimum tap targets
- Spring animations for transitions (0.3s standard)

---

## Content Still Needed

Before implementation, copywriting team needs to provide:

1. Welcome screen body copy (Screen 1)
2. Progressive overload definition copy (Screen 2)
3. Benefits list copy (Screen 3)
4. 6-12 month vision copy (Screen 4)
5. Research statistics and expert quotes (Screen 5)
6. Email guide description copy (Screen 13)
7. Commitment question final copy (Screen 14)
8. Free vs. Premium feature list (Screen 14)
