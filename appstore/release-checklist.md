# Progressive Lift 1.0: what's left before submitting

_Written 2026-11-27 against build 1.0 (19), commit `0f7fc90`. The owner sets the order and dates._

## Done in the working tree (not committed)

- Copy that contradicted iCloud sync: promo text, description privacy lines, App Review notes and the `offline` keyword in `listing.md`; the "no server" answer and the delete-the-app answer in `docs/index.html`. `appstore/privacy.html` is now an exact copy of `docs/privacy.html` (it had a mailto link instead of the support link).
- Listing draft: subtitle and keywords in `listing.md` (see the draft note there).
- fastlane: `fastlane/Appfile`, `fastlane/Fastfile`, `Gemfile`. `fastlane check` tests the API key and compares build numbers; `fastlane upload` archives Release and uploads to TestFlight. The key is read from `~/.wellness-studio/asc.json` at run time; `*.p8` is now in `.gitignore`.
- Support and privacy pages are live (both HTTP 200 on 2026-11-27). The live privacy page already describes iCloud. The live support page still has the old "Yes" answer to "Does deleting the app delete my workouts?" until the repo is pushed.

## Screenshots: verdict

Build 19 changed only Settings → About and the privacy screen, and none of the six shots shows those, so nothing is out of date with the build. They don't follow the order planned in `listing.md`, though, and three planned shots don't exist (progression suggestion, rest-timer Live Activity, routines).

| Shot | Keep? | Why |
|---|---|---|
| 4-track (bench press, sets with checkmarks) | Keep, lead with it | The core "log a set" screen |
| 3-workout (today's list, PR trophy, Vol/E1RM arrows) | Keep | Shows PRs and progress at a glance |
| 2-insights | Retake | Volume trend dives at the end and PRs show a red "↓ -27%". Use a period where the trend climbs |
| 5-history | Retake | The header says "2 sets • 16 reps" while four sets are listed below, because only two were checked. Check all four first |
| 6-plates | Keep | Distinct, useful feature |
| 1-home | Drop or retake | Goals card is the empty state ("Set your first goal") and the routine card is cut off by the tab bar |

Recommended order (first three show in search results):
1. Track: "Log a set in seconds"
2. Progression suggestion, new shot (the Track screen when the app suggests a heavier weight): "Know when to add weight". If it's hard to stage, use 3-workout here
3. Rest timer Live Activity on the Lock Screen, new shot (works in the Simulator): "Rest timer on your Lock Screen"
4. Insights, retaken: "See your strength trend"
5. Workout list with PR, or Routines: "Plan your week once"
6. History or plate calculator

Captions aren't overlaid yet; whether to frame or caption them is the owner's call.

## Owner checklist

### 1. Debug build on your iPhone (creates the CloudKit Development schema)
- [ ] Your iPhone is signed in to iCloud, with iCloud Drive on.
- [ ] Open `FitNotes.xcodeproj`, scheme FitNotes, Debug, run on the phone. (Demo data only seeds in the Simulator, so the phone starts empty.)
- [ ] Use every kind of record: finish onboarding; add a custom exercise; start a workout and log and check sets (with a note, RPE and a superset link); finish it; create and schedule a routine; add a goal; change a preference (units).
- [ ] Wait a minute with the app open, then in the CloudKit Console (Development) check that record types such as `CD_Exercise`, `CD_Workout`, `CD_WorkoutExercise`, `CD_WorkoutSet`, `CD_Routine`, `CD_RoutineExercise`, `CD_FitnessGoal`, `CD_UserPreferences` exist.
- Note: `BodyMetric` is in the schema, but nothing in the app creates one, so its record type won't appear this way. Fields that were empty on every saved record may also be missing. A one-off DEBUG call to the CloudKit schema initializer would create all of them; ask for it before step 2 if you want it.

### 2. Deploy the schema to Production
- [ ] CloudKit Console → container `iCloud.Future-Selves.FitNotes` → Deploy Schema Changes → Production. Without this, TestFlight and App Store builds don't sync, and they don't show an error.

### 3. Sync test (after a new build ≥ 20 is uploaded; builds 17 to 19 predate the deploy and can be reused, but a fresh one is cleaner)
- [ ] Two devices, same Apple Account, install from TestFlight. On the first launch of the second device, the built-in exercise library shows once, not twice.
- [ ] Log a workout on device A: it appears on B. Edit a set on B and delete a set on B: both show on A.
- [ ] Log on both devices on the same day before they sync: you end up with one workout for that day, nothing lost.
- [ ] A device signed out of iCloud: the app works normally and logs workouts (the review notes now say the app works without iCloud; this test proves it).
- [ ] Upgrade over build 17 or 18 with existing workouts: after installing the new build, every workout, routine and PR is still there.

### 4. App Store Connect (only you can fill these in)
- [ ] Approve and enter the name, subtitle, keywords, promo text, description and review notes from `listing.md`.
- [ ] Privacy label: "Data Not Collected" (iCloud private-database data isn't collected by the developer).
- [ ] Age rating questionnaire: all None/No, aiming for 4+.
- [ ] Copyright: `2026 Future Selves` (confirm the name).
- [ ] EU Digital Services Act trader status, or exclude EU storefronts.
- [ ] Support URL and privacy policy URL as in `listing.md`.
- [ ] Screenshots, in the order you choose.
- [ ] Confirm the old Supabase project is deleted (studio `INBOX.md` item 0).

### 5. Upload (once 1 to 3 pass)
- [ ] Install fastlane (`brew install fastlane`, or `bundle install` with a newer Ruby than the system 2.6).
- [ ] Bump `CURRENT_PROJECT_VERSION` to 20 in all eight build configs and commit.
- [ ] `fastlane check`, then `fastlane upload` from `apps/fitnotes`.
