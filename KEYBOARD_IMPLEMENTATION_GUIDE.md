# Custom Keyboard Implementation Guide

## Problem Statement

The FitNotes app has a custom numeric keyboard (`CustomNumericKeyboard.swift`) that should be the ONLY keyboard shown in TrackTabView. However, when users tap on TextField inputs (weight, reps, RPE/RIR), the iOS system keyboard also appears, creating a dual keyboard issue.

## What Was Tried (And Why It Failed)

### Attempt 1: NoKeyboardTextField with empty inputView
**Commit**: cd8782e
**Approach**: Created a UIViewRepresentable wrapper that set `textField.inputView = UIView()`
**Why it failed**: The empty UIView didn't properly suppress the keyboard. UITextField still triggered system keyboard or the field never properly became first responder.

### Attempt 2: Fixed AutoLayout constraints
**Commit**: 0eb645c
**Approach**: Changed to `UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))` with explicit constraints
**Why it failed**: Fixed AutoLayout warnings but didn't solve the core dual-keyboard problem.

### Attempt 3: Block parent gesture handlers
**Commit**: 9c42177
**Approach**: Added empty `.onTapGesture {}` handlers to prevent parent ScrollView from intercepting taps
**Why it failed**: This was a workaround for gesture priority but didn't address keyboard suppression.

### Root Cause
The UIKit approach (UIViewRepresentable with inputView) is complex and has timing issues:
- `becomeFirstResponder()` timing is critical (must be in window hierarchy)
- Custom inputView must be a UIView (can't use SwiftUI views directly without UIHostingController)
- SwiftUI/UIKit bridging introduces complexity and edge cases

## Recommended Solution: Pure SwiftUI Approach

Replace TextField components with **custom tappable views** that trigger the existing CustomNumericKeyboard overlay via state changes. This avoids UITextField entirely, preventing the iOS keyboard from ever appearing.

### Why This Works

1. **No TextField = No System Keyboard**: iOS only shows the system keyboard when a text input view (UITextField/UITextView) becomes first responder
2. **Existing overlay already works**: CustomNumericKeyboard appears correctly as a ZStack overlay
3. **State-based focus**: `focusedInput` state already controls which keyboard is shown
4. **Simpler code**: Pure SwiftUI without UIKit bridging

## Implementation Steps

### Step 1: Create NumericInputField Component

Create a new file `FitNotes/NumericInputField.swift`:

```swift
import SwiftUI

/// A tappable view that looks like a TextField but doesn't trigger the system keyboard
/// Instead, it updates focus state to show a custom keyboard
struct NumericInputField: View {
    @Binding var text: String
    let placeholder: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Text(text.isEmpty ? placeholder : text)
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(text.isEmpty ? .white.opacity(0.3) : .textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isActive ? Color.accentSuccess : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}
```

### Step 2: Update SetRowView in TrackTabView.swift

Replace each TextField with NumericInputField. Here's the pattern for weight input:

**Before:**
```swift
TextField(
    "0",
    text: Binding<String>(
        get: { formatWeight(weight) },
        set: { newText in
            let cleaned = newText.replacingOccurrences(of: ",", with: ".")
            if cleaned.isEmpty {
                weight = nil
            } else if let val = Double(cleaned) {
                weight = val
            }
        }
    )
)
.keyboardType(.decimalPad)
.font(.dataFont)
.foregroundColor(.textPrimary)
.multilineTextAlignment(.center)
.frame(maxWidth: .infinity)
.padding(.vertical, 10)
.background(Color.white.opacity(0.04))
.cornerRadius(10)
.focused(focusedInput, equals: TrackTabView.InputFocus.weight(set.id))
.accessibilityLabel("Weight input")
```

**After:**
```swift
NumericInputField(
    text: .constant(formatWeight(weight)),
    placeholder: "0",
    isActive: focusedInput == TrackTabView.InputFocus.weight(set.id),
    onTap: {
        focusedInput = TrackTabView.InputFocus.weight(set.id)
    }
)
.accessibilityLabel("Weight input")
.accessibilityHint("Double tap to enter weight")
```

### Step 3: Apply to All Input Fields

Update all three input types in SetRowView:
1. **Weight input** (line ~481-504)
2. **Reps input** (line ~514-537)
3. **RPE/RIR input** (line ~548-572)

Use the same pattern for each, just change:
- The `InputFocus` enum case
- The binding value display
- The accessibility labels

### Step 4: Test Custom Keyboard Integration

The existing keyboard logic should work without changes:
- `bindingForFocusedInput()` already handles text binding ✅
- `incrementForFocusedInput()` already provides increment values ✅
- Keyboard overlay shows when `focusedInput != nil` ✅
- Keyboard dismisses when tapping outside (line 98-100) ✅

### Step 5: Remove Keyboard-Related Code

Clean up code that's no longer needed:

1. **Remove** `.scrollDismissesKeyboard(.never)` (line 96) - not needed
2. **Remove** toolbar keyboard group (lines 115-119) - not needed
3. **Remove** `.ignoresSafeArea(.keyboard)` (line 114) - optional, won't hurt to keep

## Testing Checklist

After implementation, verify:

- [ ] Tapping weight input shows ONLY custom keyboard (no iOS keyboard)
- [ ] Tapping reps input shows ONLY custom keyboard
- [ ] Tapping RPE/RIR input shows ONLY custom keyboard
- [ ] Active input field has green border
- [ ] Increment/decrement buttons work correctly
- [ ] Number pad inputs work correctly
- [ ] Delete button works correctly
- [ ] Dismiss button (chevron down) closes keyboard
- [ ] Tapping outside inputs dismisses keyboard
- [ ] Values persist correctly when keyboard closes
- [ ] No AutoLayout warnings in console
- [ ] No keyboard-related crashes

## Additional Notes

### Why Not Use .disabled(true) on TextField?
Some might suggest disabling TextField to prevent keyboard. Don't do this because:
- Disabled fields look grayed out
- Accessibility is compromised
- Still shows cursor on tap
- Hacky solution that doesn't address root cause

### Why Not Use UIViewRepresentable?
The UIKit approach requires:
- Complex coordinator pattern
- Timing `becomeFirstResponder()` correctly
- Wrapping SwiftUI keyboard in UIHostingController for inputView
- Handling window lifecycle
- More code, more bugs, harder to maintain

### Accessibility Considerations
NumericInputField includes:
- `.contentShape(Rectangle())` for full tap area
- Accessibility labels for screen readers
- Accessibility hints to explain interaction
- Visual focus indicator (green border)

## File Locations

- Custom keyboard: `/home/user/fitnotes/FitNotes/CustomNumericKeyboard.swift`
- Main view: `/home/user/fitnotes/FitNotes/TrackTabView.swift`
- New component: `/home/user/fitnotes/FitNotes/NumericInputField.swift` (to be created)

## Current Branch

Branch: `claude/rollback-keyboard-fixes-01Wz64txxL4aNQwk5xdo2UED`
Current commit: `de1e08a` (working state with custom keyboard overlay)

## Success Criteria

Implementation is complete when:
1. Only the custom keyboard appears (never the iOS keyboard)
2. All input fields work correctly with the custom keyboard
3. No console warnings or errors
4. Code is simpler and more maintainable than before
5. All tests pass

Good luck! 🚀
