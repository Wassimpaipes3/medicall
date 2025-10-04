# 🎨 Patient Waiting Screen - Visual Guide

## Before vs After

### BEFORE (Missing Expiration Handling)
```
┌────────────────────────────────┐
│  Waiting for Provider          │
├────────────────────────────────┤
│                                │
│   🏥 Provider Card             │
│                                │
│   ⏳ Waiting animation         │
│   "Waiting for provider..."    │
│                                │
│   Status: pending              │
│                                │
│                                │
│                                │
│  [Cancel Request]              │ ← Only action
└────────────────────────────────┘

❌ Problem: If request expires:
   - Patient keeps waiting forever
   - No notification
   - Must manually cancel and restart
```

### AFTER (With Expiration Handling) ✅
```
┌────────────────────────────────┐
│  Waiting for Provider          │
├────────────────────────────────┤
│                                │
│   🏥 Provider Card             │
│                                │
│   ⏳ Waiting animation         │
│   "Waiting for provider..."    │
│                                │
│   Status: pending              │
│                                │
│  ↓ After 10 minutes ↓          │
│                                │
├────────────────────────────────┤
│  ⏰ Request Expired            │ ← Auto-detects!
│                                │
│  Your request has expired.     │
│  Please try again with         │
│  another provider.             │
│                                │
│  [Cancel]  [Try Again] ←       │ ← Clear actions
└────────────────────────────────┘

✅ Solution:
   - Automatic detection
   - Clear messaging
   - One-click retry
   - Preserves search context
```

---

## Dialog Design (Material 3)

### Expired Dialog
```
╔══════════════════════════════════╗
║                                  ║
║  ⏰  Request Expired             ║  ← Red icon (#E53935)
║                                  ║
║  Your request has expired.       ║  ← Clear message
║  Please try again with another   ║
║  provider.                       ║
║                                  ║
║                                  ║
║        [Cancel]  [Try Again]     ║  ← Actions
║                   ^^^^^^^        ║     ↑
║                   Blue (#1976D2) ║     Primary action
╚══════════════════════════════════╝
```

### Design Specs
- **Shape:** Rounded corners (16-20px)
- **Icon:** `Icons.access_time_filled` (28px)
- **Icon Color:** Red `#E53935`
- **Title Font:** 20px, Bold (700)
- **Body Font:** 15px, Regular (400)
- **Buttons:**
  - Cancel: Gray text, transparent background
  - Try Again: White text, blue background `#1976D2`
- **Spacing:** 12-24px padding
- **Behavior:** Non-dismissible (must choose action)

---

## State Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     PATIENT CREATES REQUEST             │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
            ┌─────────────────────┐
            │  Waiting Screen     │ ← StreamBuilder listening
            │  (Real-time)        │
            └──────────┬──────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
     ACCEPTED      EXPIRED      CANCELLED
          │            │            │
          │            │            │
          ▼            ▼            ▼
   ┌─────────┐  ┌──────────┐  ┌──────────┐
   │ Navigate│  │ Show     │  │ Delete   │
   │ to      │  │ Dialog   │  │ Request  │
   │ Tracking│  │ ⏰      │  │          │
   └─────────┘  └────┬─────┘  └────┬─────┘
                     │             │
                     ▼             │
               ┌──────────┐        │
               │ Try Again│◄───────┘
               │   or     │
               │ Cancel   │
               └────┬─────┘
                    │
                    ▼
              ┌──────────┐
              │ Navigate │
              │ to       │
              │ Provider │
              │ Select   │
              └──────────┘
```

---

## Technical Flow

### 1. Document Listening
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('provider_requests')
      .doc(requestId)
      .snapshots(),
)
```

### 2. Expiration Detection
```dart
// Check 1: Document deleted
if (!snapshot.data!.exists) {
  → Show Dialog
}

// Check 2: Timestamp expired
if (expireAt < DateTime.now()) {
  → Show Dialog
}
```

### 3. Dialog Action
```dart
"Try Again" → Navigator.pushReplacement(
  SelectProviderScreen(
    service: previousService,
    specialty: previousSpecialty,
    // ... restore search params
  )
)

"Cancel" → Navigator.pop() // Just close dialog
```

---

## User Experience Scenarios

### Scenario 1: Quick Acceptance ✅
```
0:00  → Patient creates request
0:30  → Provider sees request
1:00  → Provider accepts
1:01  → Patient auto-redirected to tracking
```
**Result:** Normal flow, no expiration involved

---

### Scenario 2: Slow Response (Expired) ⏰
```
0:00  → Patient creates request
5:00  → Still waiting...
10:00 → Request expires (TTL deletes document)
10:01 → StreamBuilder detects missing document
10:02 → "⏰ Request Expired" dialog appears
10:05 → Patient clicks "Try Again"
10:06 → Back at provider selection with same search
```
**Result:** Clear expiration handling, easy retry

---

### Scenario 3: Manual Cancellation ❌
```
0:00  → Patient creates request
2:00  → Patient changes mind
2:01  → Clicks "Cancel Request"
2:02  → Confirms cancellation
2:03  → Document deleted
2:04  → Back at provider selection
```
**Result:** Patient has control, smooth navigation

---

### Scenario 4: Multiple Expiration Events 🛡️
```
10:00 → Request expires
10:01 → Dialog shows (flag: _hasShownExpiredDialog = true)
10:05 → StreamBuilder emits another event
10:06 → Dialog does NOT show again (flag prevents it)
```
**Result:** No spam, single dialog only

---

## Color Palette

```css
/* Primary Colors */
--primary-blue:    #1976D2  /* Try Again button, status badge */
--error-red:       #E53935  /* Expired icon, urgent actions */
--success-green:   #43A047  /* Accepted state */

/* Text Colors */
--text-primary:    #263238  /* Titles, important text */
--text-secondary:  #546E7A  /* Body text, descriptions */
--text-disabled:   #9E9E9E  /* Disabled states */

/* Backgrounds */
--surface:         #FFFFFF  /* Cards, dialogs */
--background:      #FAFAFA  /* Screen background */

/* Accents */
--divider:         #E0E0E0  /* Lines, borders */
--shadow:          rgba(0,0,0,0.06)  /* Subtle shadows */
```

---

## Animation & Timing

### Normal Waiting State
- **Pulse Animation:** 1.5s loop
- **Scale:** 0.95 → 1.05
- **Easing:** `Curves.easeInOut`

### Expired State Transition
- **Fade In:** 300ms
- **Icon Scale:** 0 → 1 (spring animation)
- **Dialog:** Slide up from bottom (200ms)

### Navigation
- **Page Transition:** `pushReplacement` (no back stack)
- **Duration:** 300ms default

---

## Accessibility

### Screen Reader Support
```
"Alert: Your request has expired. 
 Button: Try again, redirects to provider selection.
 Button: Cancel, closes dialog."
```

### Touch Targets
- Minimum 48x48 dp for all buttons
- Clear visual feedback on press
- High contrast for visibility

### Error Handling
- Non-blocking error states
- Clear recovery paths
- Preserve user context

---

## Summary

**Visual Changes:**
✅ Red clock icon for expiration  
✅ Clear dialog messaging  
✅ Prominent action buttons  
✅ Material 3 design language  

**Functional Changes:**
✅ Real-time expiration detection  
✅ Automatic dialog trigger  
✅ Context-preserving navigation  
✅ Duplicate prevention  

**User Benefits:**
✅ No confusion when requests expire  
✅ Easy retry without re-entering details  
✅ Clear feedback at every step  
✅ Professional, polished experience  

---

The patient waiting screen now provides a complete, production-ready expiration handling experience! 🎉
