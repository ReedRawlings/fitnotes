# Dynamic Island Debug Logging

## Overview
Comprehensive error logging has been added to help debug the Dynamic Island text rendering issue.

## Logging Categories

### 1. Live Activity Lifecycle (RestTimerManager.swift)
**Subsystem:** `com.fitnotes.app`
**Category:** `LiveActivity`

#### Events Logged:
- 🚀 **Starting Live Activity** - Logs exercise name, set number, and duration
- ✅ **Authorization Check** - Confirms Live Activities are enabled
- ❌ **Authorization Failed** - iOS version check or user permissions disabled
- 📊 **State Data** - Logs all state values being passed (set, endTime, duration, isCompleted)
- ✅ **Activity Created** - Success with activity ID and state
- ❌ **Creation Error** - Detailed error messages if activity fails to create
- 🔄 **Updating to Completed** - When timer finishes
- ✅ **Update Success** - Confirmation of state update
- ❌ **Update Error** - If update fails
- 🛑 **Ending Activity** - When manually ending or auto-dismissing
- 🗑️ **Cleanup** - When clearing activity reference

### 2. Widget Rendering (RestTimerWidget.swift)
**Subsystem:** `com.fitnotes.widget`
**Category:** `DynamicIsland`

#### Events Logged:
- 🔒 **Lock Screen Rendering** - When lock screen view is rendered
- 🏝️ **Dynamic Island Rendering** - Main Dynamic Island configuration
- 📱 **Expanded View** - Center region with timer
- 🔵 **Compact Leading** - Timer icon in collapsed state
- 🟢 **Compact Trailing** - Timer text in collapsed state
- ⚪ **Minimal View** - Minimal icon state
- 🔓 **Lock Screen Body** - Lock screen view body rendering

## How to View Logs

### In Xcode Console:
1. Run the app on a device (Dynamic Island requires physical device with Dynamic Island)
2. Open Console (Window > Devices and Simulators > Select device > Open Console)
3. Filter by:
   - `com.fitnotes.app` - for Live Activity lifecycle
   - `com.fitnotes.widget` - for widget rendering
   - Or search for emoji prefixes like `🚀` or `🏝️`

### Using Console App (macOS):
1. Open Console.app
2. Connect your iPhone
3. Select your device from the sidebar
4. Filter by process: `FitNotes` or `RestTimerWidget`
5. Search for subsystems:
   - `subsystem:com.fitnotes.app category:LiveActivity`
   - `subsystem:com.fitnotes.widget category:DynamicIsland`

### Command Line (if device is connected):
```bash
# Stream logs from device
log stream --device --predicate 'subsystem == "com.fitnotes.app" OR subsystem == "com.fitnotes.widget"'

# Or specific category
log stream --device --predicate 'subsystem == "com.fitnotes.app" AND category == "LiveActivity"'
```

## What to Look For

### If text isn't appearing:

1. **Check Activity Creation**:
   - Look for `🚀 Starting Live Activity`
   - Verify `✅ Live Activity authorization confirmed` appears
   - Check for `✅ Live Activity successfully created`
   - If you see `❌ Failed to create Live Activity`, check the error details

2. **Check State Data**:
   - Look for `📊 Live Activity state` logs
   - Verify setNumber, endTime, and duration are correct
   - Confirm endTime is in the future

3. **Check Rendering**:
   - Look for `🏝️ Rendering Dynamic Island` logs
   - Check if `🟢 Rendering compact trailing view` appears (this has the timer text)
   - Look for `📱 Rendering expanded center region` (expanded timer)
   - Verify the endTime value in rendering logs is correct

4. **Common Issues**:
   - **No rendering logs** = Widget extension isn't being called (target/entitlements issue)
   - **No authorization confirmed** = Live Activities disabled in Settings
   - **Creation error** = Check error message for details (memory, permissions, etc.)
   - **Wrong endTime** = Timer calculation issue
   - **Updates not appearing** = Check `🔄 Updating` logs for errors

## Testing Steps

1. Start a rest timer from the app
2. Check Console for `🚀 Starting Live Activity` log
3. Verify Dynamic Island appears on device
4. Check for `🏝️ Rendering Dynamic Island` logs
5. Expand Dynamic Island - look for `📱 Rendering expanded` logs
6. Wait for timer to complete - check for `🔄 Updating` logs
7. Note any `❌` error logs

## Expected Log Sequence

**Normal Flow:**
```
🚀 Starting Live Activity for 'Bench Press', Set #3, Duration: 90s
✅ Live Activity authorization confirmed
ℹ️ No active Live Activity to end (if first timer)
📊 Live Activity state - Set: 3, EndTime: [date], Duration: 90, IsCompleted: false
✅ Live Activity successfully created with ID: [UUID]
📱 Activity state: active
🏝️ Rendering Dynamic Island - Exercise: 'Bench Press', Set: 3, ...
🔵 Rendering compact leading view with timer icon
🟢 Rendering compact trailing view with timer text: [date]
... (timer runs) ...
🔄 Updating Live Activity to completed state, ID: [UUID]
📊 Updated state - Set: 3, IsCompleted: true
✅ Live Activity updated successfully to completed state
⏱️ Waiting 2 seconds before dismissing Live Activity...
✅ Live Activity ended successfully
🗑️ Cleared current activity reference
```

## Next Steps

After reviewing logs, report findings:
- Are Live Activities being created successfully?
- Are rendering logs appearing?
- What errors are being logged?
- Is the endTime value correct?
- Are update logs appearing when timer completes?
