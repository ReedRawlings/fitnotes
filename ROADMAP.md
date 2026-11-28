# Progressive Lift (FitNotes repo): Roadmap

_Last reviewed 2026-11-26, at commit `0f7fc90` (build 1.0 (19)). Facts come from the repo. Nothing was built or run for this review._

## Status

The app is feature-complete for a free v1. It has App Store Connect listing copy, an icon, privacy manifests, hosted support and privacy pages, and 6.9"/6.3" screenshots, and build 17 was bumped "for TestFlight upload". Whether it was uploaded is unknown; confirm with the owner. The big risk is iCloud sync via CloudKit (schema V3 plus a deduplicator), which landed this morning in build 19. It hasn't been proven on two real devices, and its CloudKit schema hasn't been deployed to Production. A Supabase secret key also sits in the public repo's history and must be revoked.

**Ship-readiness: ~80%.** The code and assets are largely done. What's left is mostly verification and console work.

## Blockers to first App Store release

- [ ] **Revoke the leaked Supabase secret key.** It sits in public GitHub history (commits `fb7b1a6`/`21346dd`). Rotate or delete it in the Supabase dashboard, or delete the project, since the app no longer uses Supabase. This is an owner action. Rewriting history is optional; revoking the key is not.
- [ ] **Test CloudKit sync on real hardware.** Install build 19 from TestFlight on 2 devices with the same Apple Account. Check first-launch dedup of the exercise library, same-day workouts, and edits and deletes on both sides. Check a device that's signed out of iCloud. Also upgrade over a TestFlight 17 or 18 install (if one exists) to exercise the V2 to V3 migration on a real store.
- [ ] **Deploy the CloudKit schema to Production** in the CloudKit Console for `iCloud.Future-Selves.FitNotes`. Do this after a dev build has created every record type, and before the App Store build is reviewed. Without it, production sync fails silently.
- [x] **Fix copy that contradicts iCloud sync** (done 2026-11-27 in the working tree, not committed; see `appstore/release-checklist.md`):
  - `appstore/listing.md` promo text: "Your workouts stay on your iPhone"
  - Review notes: "fully offline… there is no server"
  - The `offline` keyword
  - `docs/index.html` FAQ: "Does deleting the app delete my workouts? Yes." Synced copies stay in iCloud.
  - Reconcile `appstore/privacy.html` (has a mailto) with `docs/privacy.html`
- [x] **Recheck screenshots against build 19** (2026-11-27: still match the build; two retakes and two new shots recommended in `appstore/release-checklist.md`). If any copy changed, retake them. Today's 6 shots (home, insights, workout, track, history, plates) don't match the order planned in `listing.md`, which leads with logging, progression/PR and the Live Activity. Decide which order to use.
- [ ] **App Store Connect setup (owner):**
  - Create the app record with bundle `Future-Selves.FitNotes`
  - Privacy label: "Data Not Collected". This holds because iCloud private-DB data isn't collected by the developer.
  - Age rating questionnaire, aiming for 4+
  - Copyright name
  - EU DSA trader status, or exclude EU storefronts
  - Confirm that the name "Progressive Lift: Gym Log" is available
- [x] **Confirm GitHub Pages is live** (both 200 on 2026-11-27; the support FAQ fix goes live on push) at https://reedrawlings.github.io/fitnotes/ and `/privacy.html`. These are the support and privacy URLs.
- [ ] **Do a final upload with build ≥ 20** through fastlane. `fastlane/` added 2026-11-27 (`fastlane check`, `fastlane upload`), not yet run.

Already done (verified in the repo):
- 1024×1024 app icon with no alpha channel
- `PrivacyInfo.xcprivacy` for the app (UserDefaults CA92.1) and the widget
- Encryption flag set
- In-app privacy policy, support link and CSV export
- Store-recovery path instead of deleting the store
- Review prompt that waits for 3+ workouts

There's no paywall, so no subscription disclosure is needed. Crash risk is low: the only `fatalError` comes after store recovery has already failed.

## Next version (1.1, small and shippable)

1. **iCloud sync toggle and status row** in Settings → Preferences. `CloudSync.enabledKey` exists, but no UI sets it. Show "Syncing with iCloud" or "iCloud unavailable".
2. **Missed-day handling** for scheduled routines. A `TODO` is at `ContentView.swift:948`: offer to shift the schedule when days are missed.
3. **Insights PRs for reps-only exercises.** Today Insights PR lists are weight-only.
4. **CSV import**, to pair with the existing export (moving data from other loggers).
5. **Split `ContentView.swift`** (~2,700 lines) into per-screen files. No behavior change. This makes future work cheaper.

## Backlog

- Use `BodyMetric` in the UI (the model exists; check how much of it is surfaced)
- HealthKit: write workouts and active energy. This would add privacy-manifest, label and review work.
- Apple Watch set logging. Home-screen widget showing the next scheduled routine.
- iPad and landscape support
- Replace the template UI tests with a smoke test of onboarding plus logging a set
- Light mode
- Clean up tracked `.DS_Store` and `xcuserdata` files. Delete about 70 stale `claude/*` and `cursor/*` remote branches.
- Remove or refresh stale docs: `agents.md`, `ONBOARDING-SCREENS-SPEC.md`, and the empty `Readme.md` and `DesignSYSTEM.md`
- Monetization: none planned. Any future paid tier is unknown and needs the owner to confirm.

## Store listing / ASO notes

- The full draft is in `appstore/listing.md`:
  - Name: "Progressive Lift: Gym Log" (25 characters)
  - Subtitle: "Private Workout & PR Tracker" (28)
  - Keywords: 99 characters, no repeats of words in the name or subtitle
- Swap the `offline` keyword now that sync exists. Candidates already listed: `training`, `planner`, `hypertrophy`, `program`, `barbell`.
- "Free, no account, no ads, no subscriptions" is the strongest differentiator. Keep it in the first line.
- Add "Syncs with iCloud" to the description's privacy section and the promo text.
- Category: Health & Fitness primary, Sports secondary (optional)
- Screenshots: 6.9" (1320×2868) and 6.3" (1206×2622) sets exist, but the captions in `listing.md` aren't overlaid yet. Confirm whether the owner wants framed or captioned versions.

## Risks (App Review and launch)

- **Health and medical claims:** low. The copy is about strength tracking. Keep everything in line with the studio rules: no "prevents injury" or recovery-medical framing. The "Muscle recovery heatmap" should read as training-load info, not medical advice.
- **HealthKit:** not used, so there are no HealthKit wording requirements. If it's added later, it needs usage strings and must not use the data for ads.
- **Subscriptions (3.1.2):** not applicable, since there's no IAP. `listing.md` says "no subscriptions"; keep that true.
- **Privacy accuracy (5.1.1):** the listing, support page and review notes still say "offline" or "stays on your iPhone" while the build syncs to iCloud. This is the most likely mismatch a reviewer could flag. Fix it before submitting.
- **Guideline 4.2 (minimum functionality) and 4.3 (spam):** low. The app is substantial. Keep "FitNotes" out of the store name; whether that name conflicts is unverified.
- **Third-party names and quotes:** onboarding once quoted Greg Doucette (Dec 2025). No such string exists in the current code; re-check before submitting if onboarding copy changes.
- **CloudKit data integrity:** the deduplicator deletes records it thinks are duplicates. A bug here could lose user data across all devices. This is the highest product risk, so test it before release.
- **Security:** the leaked Supabase secret key is in a public repo. This is a reputational and data risk until it's revoked, though it isn't an App Review issue.
