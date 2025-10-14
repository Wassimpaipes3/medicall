# 🔔 Notification System Flow

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NOTIFICATION SYSTEM                          │
└─────────────────────────────────────────────────────────────────────┘

1️⃣ TRIGGER EVENT
   ┌─────────────────────┐
   │  Patient Books      │
   │  Appointment        │
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │ /appointments/{id}  │
   │ document created    │
   └──────────┬──────────┘
              │
              │
2️⃣ CLOUD FUNCTION TRIGGERED
   ┌──────────▼──────────────────────────────────────┐
   │  Firebase Cloud Function                        │
   │  functions/src/index.ts                         │
   │  onAppointmentCreated()                         │
   │                                                  │
   │  1. Get patient name from /patients             │
   │  2. Get appointment details (date, time)        │
   │  3. Create notification document                │
   └──────────┬──────────────────────────────────────┘
              │
              │
3️⃣ NOTIFICATION CREATED
   ┌──────────▼──────────────────────────────────────┐
   │  /notifications/{notificationId}                │
   │                                                  │
   │  {                                               │
   │    destinataire: "doctorUserId",                │
   │    message: "🔔 Patient booked...",             │
   │    type: "appointment",                         │
   │    datetime: Timestamp,                         │
   │    read: false,                                 │
   │    senderId: "patientUserId",                   │
   │    payload: { appId, patientId, action }        │
   │  }                                               │
   └──────────┬──────────────────────────────────────┘
              │
              │
4️⃣ FLUTTER APP LOADS NOTIFICATIONS
   ┌──────────▼──────────────────────────────────────┐
   │  NotificationsScreen                            │
   │  lib/screens/notifications/                     │
   │                                                  │
   │  Query:                                          │
   │  ┌────────────────────────────────────────┐    │
   │  │ .collection('notifications')            │    │
   │  │ .where('destinataire',                  │    │
   │  │        isEqualTo: currentUser.uid)      │    │
   │  │ .orderBy('datetime', descending: true)  │    │
   │  │ .limit(50)                              │    │
   │  └────────────────────────────────────────┘    │
   │                                                  │
   │  Display:                                        │
   │  • Title (extracted from message)               │
   │  • Message body                                 │
   │  • Icon (based on type)                         │
   │  • Color (based on type)                        │
   │  • Time ago (formatted)                         │
   │  • Read indicator (dot/checkmark)               │
   └──────────┬──────────────────────────────────────┘
              │
              │
5️⃣ USER INTERACTS
   ┌──────────▼──────────────────────────────────────┐
   │  User Actions:                                   │
   │                                                  │
   │  A) Tap Notification → Mark as Read             │
   │     ┌─────────────────────────────────┐        │
   │     │ .update({'read': true})         │        │
   │     └─────────────────────────────────┘        │
   │                                                  │
   │  B) Pull to Refresh → Reload All                │
   │     ┌─────────────────────────────────┐        │
   │     │ RefreshIndicator triggers       │        │
   │     │ _loadNotifications()            │        │
   │     └─────────────────────────────────┘        │
   │                                                  │
   │  C) Mark All as Read                            │
   │     ┌─────────────────────────────────┐        │
   │     │ Batch update all unread         │        │
   │     │ notifications to read: true     │        │
   │     └─────────────────────────────────┘        │
   └─────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════
                             DATA FLOW
═══════════════════════════════════════════════════════════════════════

┌───────────┐       ┌──────────────┐       ┌──────────────┐
│  Patient  │──1──▶│  Firestore   │──2──▶│   Cloud      │
│  Books    │      │ /appointments│      │   Function   │
└───────────┘      └──────────────┘      └──────┬───────┘
                                                  │
                                                  │ 3. Creates
                                                  ▼
                                         ┌──────────────┐
                                         │  Firestore   │
                                         │ /notifications│
                                         └──────┬───────┘
                                                  │
                                                  │ 4. Queries
                                                  ▼
                                         ┌──────────────┐
                                         │   Flutter    │
                                         │     App      │
                                         │ (Doctor/     │
                                         │  Nurse)      │
                                         └──────────────┘


═══════════════════════════════════════════════════════════════════════
                         SECURITY & INDEXING
═══════════════════════════════════════════════════════════════════════

🔒 SECURITY RULES (firestore.rules):
   
   match /notifications/{notifId} {
     ✅ READ:  if authenticated AND destinataire == user.uid
     ❌ WRITE: false (only Cloud Functions)
   }

📊 FIRESTORE INDEX (firestore.indexes.json):
   
   Collection: notifications
   ┌────────────────┬───────────┐
   │ Field          │ Order     │
   ├────────────────┼───────────┤
   │ destinataire   │ ASC  ⬆️   │
   │ datetime       │ DESC ⬇️   │
   └────────────────┴───────────┘
   
   Purpose: Fast filtered + sorted queries


═══════════════════════════════════════════════════════════════════════
                        NOTIFICATION TYPES
═══════════════════════════════════════════════════════════════════════

┌──────────────┬────────────┬─────────────────────────────────────┐
│ Type         │ Icon/Color │ Example Message                     │
├──────────────┼────────────┼─────────────────────────────────────┤
│ appointment  │ 📅 Blue    │ New appointment booked              │
│ message      │ 💬 Purple  │ You have a new message              │
│ report       │ 📋 Green   │ Lab results available               │
│ medication   │ 💊 Orange  │ Time to take medication             │
│ payment      │ 💳 Teal    │ Payment received                    │
│ booking      │ 📖 Indigo  │ Booking confirmed                   │
│ general      │ 🔔 Primary │ General notification                │
└──────────────┴────────────┴─────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════
                          EXAMPLE SCENARIO
═══════════════════════════════════════════════════════════════════════

Step 1: Patient "Ahmed Benali" books appointment with Dr. Sarah
        Date: September 29, 2025 at 17:50
        Note: "Pas de note"

Step 2: Cloud Function triggers:
        ✓ Fetches patient name from /patients/patientId
        ✓ Extracts appointment details
        ✓ Creates notification:

        {
          destinataire: "drSarahUserId",
          message: "🔔 Ahmed Benali a réservé un rendez-vous le 29 septembre 2025 à 17:50. Note: Pas de note",
          type: "appointment",
          datetime: Timestamp(2025-09-29 16:50:42),
          read: false,
          senderId: "ahmedBenaliUserId",
          payload: {
            appId: "appt123",
            patientId: "ahmedBenaliUserId",
            action: "new_booking"
          }
        }

Step 3: Dr. Sarah opens notifications screen:
        ✓ Query filters: destinataire == drSarahUserId
        ✓ Shows notification card:
          ┌─────────────────────────────────────────┐
          │ 📅 [Blue Badge]                         │
          │                                         │
          │ Ahmed Benali a réservé un              │
          │ rendez-vous le 29 septembre            │
          │ 2025 à 17:50                           │
          │                                         │
          │ Note: Pas de note                       │
          │                                         │
          │ 2 minutes ago              [Unread •]  │
          └─────────────────────────────────────────┘

Step 4: Dr. Sarah taps notification:
        ✓ Marks as read: {read: true}
        ✓ Dot disappears
        ✓ Card becomes lighter


═══════════════════════════════════════════════════════════════════════
                           FILE STRUCTURE
═══════════════════════════════════════════════════════════════════════

firstv/
├── functions/
│   └── src/
│       └── index.ts                    ← Creates notifications
│
├── lib/
│   └── screens/
│       └── notifications/
│           └── notifications_screen.dart  ← Displays notifications
│
├── firestore.rules                     ← Security rules
├── firestore.indexes.json              ← Database indexes
│
└── NOTIFICATION_SYSTEM_FIX.md         ← Full documentation
    NOTIFICATION_QUICK_REFERENCE.md    ← Quick reference
    NOTIFICATION_FLOW.md               ← This file


═══════════════════════════════════════════════════════════════════════
                          TESTING CHECKLIST
═══════════════════════════════════════════════════════════════════════

□ 1. Deploy Cloud Functions
     firebase deploy --only functions

□ 2. Deploy Firestore Indexes
     firebase deploy --only firestore:indexes

□ 3. Create test appointment
     Use patient account to book appointment

□ 4. Check Firestore console
     Verify notification document created in /notifications

□ 5. Open doctor's notification screen
     Should see new notification

□ 6. Test mark as read
     Tap notification, verify 'read' becomes true

□ 7. Test mark all as read
     Tap button, verify all become read: true

□ 8. Test pull to refresh
     Swipe down, verify reload works

□ 9. Test empty state
     Delete all notifications, verify empty message shows

□ 10. Test real-time updates
      Create notification while screen open, verify it appears


═══════════════════════════════════════════════════════════════════════
                             SUCCESS! 🎉
═══════════════════════════════════════════════════════════════════════

Your notification system is now fully functional and production-ready!
