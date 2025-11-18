# Rest Timer Live Activity Setup Guide

## Overview
The rest timer Live Activity has been implemented with all the necessary Swift files. You just need to add the Widget Extension target in Xcode to enable it.

## Files Created

### Main App Files
- `FitNotes/RestTimerLiveActivity.swift` - Live Activity attributes and state model
- `FitNotes/RestTimerManager.swift` - Updated with Live Activity lifecycle management
- `FitNotes/ContentView.swift` - Updated with URL handling for skip button
- `FitNotes/TrackTabView.swift` - Updated to pass exercise name to timer
- `FitNotes/Info.plist` - Added URL scheme and Live Activity support
- `FitNotes/FitNotes.entitlements` - Added App Groups capability

### Widget Extension Files
- `RestTimerWidget/RestTimerWidget.swift` - Live Activity UI with Dynamic Island support
- `RestTimerWidget/Info.plist` - Widget extension configuration
- `RestTimerWidget/RestTimerWidget.entitlements` - Widget entitlements with App Groups

## Adding the Widget Extension Target in Xcode

1. **Open the project in Xcode**
   ```bash
   open FitNotes.xcodeproj
   ```

2. **Add the Widget Extension target**
   - Click on the project in the navigator
   - Click the "+" button at the bottom of the targets list
   - Search for "Widget Extension"
   - Click "Next"
   - Product Name: `RestTimerWidget`
   - Team: Your development team
   - **IMPORTANT**: Uncheck "Include Live Activity"** (we already created the files)
   - Click "Finish"
   - When prompted about activating the scheme, click "Activate"

3. **Replace the generated files**
   - Delete the generated files in the `RestTimerWidget` folder (Xcode creates default ones)
   - In Finder, ensure the `RestTimerWidget` folder contains our custom files:
     - `RestTimerWidget.swift`
     - `Info.plist`
     - `RestTimerWidget.entitlements`
   - In Xcode, right-click the `RestTimerWidget` folder and select "Add Files to RestTimerWidget"
   - Select all three files from the `RestTimerWidget` directory

4. **Add RestTimerLiveActivity.swift to both targets**
   - Select `RestTimerLiveActivity.swift` in the Project Navigator
   - In the File Inspector (right panel), under "Target Membership", check BOTH:
     - ✅ FitNotes
     - ✅ RestTimerWidget

5. **Configure App Groups**
   - Select the FitNotes target
   - Go to "Signing & Capabilities"
   - Ensure "App Groups" capability is present (should be auto-added from entitlements)
   - Verify the group is: `group.Future-Selves.FitNotes`
   - Repeat for RestTimerWidget target

6. **Build and Run**
   - Select your iPhone device or simulator (iOS 17.0+)
   - Build and run the app (Cmd+R)

## Testing the Live Activity

1. **Start a workout**
   - Open the app
   - Start or continue a workout
   - Add a set with rest timer enabled

2. **Verify Live Activity appears**
   - After logging a set, the rest timer should start
   - Lock your iPhone or go to the home screen
   - You should see the Live Activity on the lock screen
   - On iPhone 14 Pro and newer, check the Dynamic Island

3. **Test skip functionality**
   - Tap the "Skip" button in the Live Activity
   - The timer should immediately end

4. **Test completion**
   - Let the timer count down to zero
   - Should show "Rest Complete!" for 2 seconds
   - Then auto-dismiss

## Features Implemented

### Lock Screen Display
- Shows "Set [number]"
- Displays countdown timer
- Shows progress circle
- Displays "Rest Complete!" when finished

### Dynamic Island
- **Minimal**: Timer icon
- **Compact**: Timer icon + countdown
- **Expanded**: Set number, timer, skip button

### Interactivity
- Skip button to end timer early
- Uses URL scheme: `fitnotes://skip-timer`

### Auto-Dismiss
- Shows completion state for 2 seconds
- Then automatically dismisses

## Troubleshooting

### Live Activity doesn't appear
- Check Settings > [Your App Name] > Live Activities is enabled
- Ensure you're running iOS 17.0 or later
- Verify both targets have the same App Group configured

### Skip button doesn't work
- Check that the URL scheme is registered in Info.plist
- Verify `onOpenURL` handler is in ContentView.swift

### Build errors
- Make sure `RestTimerLiveActivity.swift` is added to BOTH targets
- Check that all imports are available (ActivityKit, WidgetKit, SwiftUI)
- Clean build folder (Shift+Cmd+K) and rebuild

## Architecture

The implementation follows Apple's best practices:

1. **Shared Model**: `RestTimerLiveActivity.swift` defines the Activity attributes
2. **Widget Extension**: `RestTimerWidget.swift` provides the UI
3. **App Integration**: `RestTimerManager` handles Live Activity lifecycle
4. **URL Handling**: Deep link for skip button interaction

## Next Steps

After setting up the Widget Extension target, you can:
- Customize the Live Activity UI colors/styling
- Add more interactive buttons
- Extend to show exercise name in the expanded view
- Add haptic feedback for skip action
