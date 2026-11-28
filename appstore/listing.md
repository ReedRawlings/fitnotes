# Progressive Lift: App Store Connect listing draft

This is a draft of everything App Store Connect asks for. Copy each field in as written. The character counts were checked against Apple's limits.

## Name, subtitle and keywords (these are indexed for search)

| Field | Value | Length |
|---|---|---|
| **App name** (30 max) | `Progressive Lift: Gym Log` | 25 |
| **Subtitle** (30 max) | `Weight Lifting Workout Tracker` | 30 |
| **Keywords** (100 max) | `strength,overload,1rm,sets,reps,powerlifting,bodybuilding,routine,planner,journal,training,program` | 98 |

_Draft 2026-11-27, not yet approved by the owner, not entered in App Store Connect. The previous version was subtitle `Private Workout & PR Tracker` (28) and keywords `weightlifting,strength,overload,1rm,max,sets,reps,powerlifting,bodybuilding,routine,journal,offline` (99). Why it changed: the subtitle now carries "workout tracker" and "weight lifting", the words Hevy and Strong lead with (`marketing/brand/app-store-naming-research-2026-11-27.md`); `weightlifting` left the keywords because the subtitle covers it; `offline` left because the app now syncs with iCloud; `max` made room for `planner`, `training` and `program`. "Private" and "PR" leave the subtitle; privacy stays in the promo text and the first line of the description._

Rules the keywords follow:
- No word repeats one already in the name or subtitle. Apple indexes those already, so a repeat wastes characters.
- There are no spaces after the commas.
- No competitor names are included, since Apple rejects those.
- Apple combines words across the three fields. So the listing can match searches such as "gym workout log", "weight lifting tracker", "strength training planner", "workout journal" and "progressive overload".
- `lift` (name) and `lifting` (subtitle) are different words to Apple's index as far as is known; it isn't settled whether Apple stems them.

Other words you could swap in later: `max`, `notebook`, `hypertrophy`, `split`, `barbell`, `private`.

## Promotional text (170 max; you can change it anytime without a review; it doesn't affect search)

> Free, no account, no ads. Log every set in seconds, see your next weight, and watch your PRs climb. Your workouts stay on your iPhone and sync through your own iCloud.

(167 characters)

## Description (4,000 max; only the first lines show before "more", so they carry the pitch)

```
Lift more, every week. Progressive Lift is a fast, private gym log that tells you when it's time to add weight. Free, no account, no ads, no subscriptions.

PROGRESSIVE OVERLOAD, BUILT IN
• Set a rep range for each exercise and Progressive Lift suggests your next weight when you've earned it
• Estimated 1RM for every session, so you can see strength trends even on lighter days
• Personal records tracked automatically: new best weights are celebrated as you set them

LOGGING THAT STAYS OUT OF YOUR WAY
• Big tap targets and a custom number pad built for sweaty hands between sets
• Warm-up sets that don't skew your progression
• Rest timer with a Live Activity on the Lock Screen and Dynamic Island
• RPE and RIR tracking, if you train that way
• Pounds or kilograms, set globally or per exercise

ROUTINES AND SCHEDULES
• Build routines once and start them in a tap
• Schedule by weekday or every N days
• Save any workout as a routine, or update a routine from today's session

INSIGHTS THAT ANSWER "AM I GETTING STRONGER?"
• Volume trends, top exercises, and muscle group breakdown
• Muscle recovery heatmap
• Streaks and consistency calendar
• Goals for workouts, volume, or a specific lift
• Your Year in Review

PRIVATE BY DESIGN
• Your data lives on your iPhone and syncs through your own private iCloud, so it's on your other devices too. No account, no sign-in, no tracking
• The developer never sees your workouts: there's no server of ours involved
• Export your full history to CSV at any time, so your data stays yours

A large exercise library is included, and you can add your own.
```

## What's New (version 1.0)

```
The first release of Progressive Lift. Log your sets, follow your progression, and keep your data private.
```

## App information

- **Primary category:** Health & Fitness
- **Secondary category:** Sports (optional)
- **Support URL:** `https://reedrawlings.github.io/fitnotes/` (served from `docs/index.html` by GitHub Pages)
- **Marketing URL:** optional
- **Privacy policy URL:** `https://reedrawlings.github.io/fitnotes/privacy.html` (served from `docs/privacy.html`)
- **Copyright:** `2026 Future Selves` (confirm the name)

## App Privacy (the privacy "nutrition label")

- "Do you or your third-party partners collect data from this app?" → **No**
- The label will read **Data Not Collected**.

## Age rating questionnaire

Answer **None** or **No** to everything:
- violence
- sexual content
- profanity
- drugs
- gambling
- horror
- medical or treatment information
- user-generated content
- messaging/chat
- unrestricted web access
- advertising

This should come out as **4+**. The "medical/wellness" question is about medical treatment advice, and a lifting log doesn't give any.

## Export compliance

The app already sets `ITSAppUsesNonExemptEncryption = NO`, so App Store Connect won't ask about encryption.

## App Review notes

```
Progressive Lift has no account, no login and no server of its own. Workouts are stored on the device and, when the device is signed in to iCloud, synced through the user's private iCloud (CloudKit) database. The developer cannot access that data, and the app works fully without iCloud. To review: complete the short onboarding, then go to the Workout tab, start a routine or add an exercise, and log sets. A rest timer starts after completing a set (local notification + Live Activity). Settings > Preferences contains the CSV export, privacy policy, and support contact.
```

## Screenshots (6.9" iPhone required; the first 3 show in search results)

_2026-11-27: the existing six shots were checked against build 19; verdict and recommended order are in `release-checklist.md`._


1. **Logging a set** (the core screen). Caption: "Log a set in seconds"
2. **Progression suggestion / PR celebration.** Caption: "Know when to add weight"
3. **Rest timer Live Activity** on the Lock Screen or Dynamic Island. Caption: "Rest timer on your Lock Screen"
4. **Insights:** volume chart and top exercises. Caption: "See your strength trend"
5. **Routines and schedule.** Caption: "Plan your week once"
6. **Privacy/export.** Caption: "No account. Your data stays yours."

Use the DEBUG build's seeded demo data so the screens look full. Turn off DEBUG-only UI, if there is any, before taking them.

## EU (Digital Services Act)

You need to declare trader status in App Store Connect. A business selling or promoting in the EU is a "trader" and must publish an address, phone and email. Otherwise, exclude the EU storefronts for now.
