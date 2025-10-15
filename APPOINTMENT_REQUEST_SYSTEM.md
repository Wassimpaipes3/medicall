# 📅 Appointment Request System Documentation

## Overview

This system implements a complete appointment scheduling workflow using two Firestore collections:
1. **`appointment_requests`** - Temporary collection for pending booking requests
2. **`appointments`** - Main collection for accepted/confirmed appointments

---

## 🔄 Data Flow

```
┌─────────────┐
│   Patient   │
└──────┬──────┘
       │ 1. Creates booking request
       ▼
┌──────────────────────────┐
│  appointment_requests    │ ← Temporary (pending status)
│  Status: "pending"       │
└──────────┬───────────────┘
           │
           │ 2. Provider sees in dashboard
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────┐  ┌──────────┐
│ Accept  │  │  Reject  │
└────┬────┘  └────┬─────┘
     │            │
     │            │ 3a. Delete request
     │            └─────► ❌ Removed
     │
     │ 3b. Copy to appointments
     ▼
┌──────────────────────────┐
│     appointments         │ ← Permanent (accepted status)
│  Status: "accepted"      │
└──────────────────────────┘
     │
     │ 4. Shows in "Upcoming Appointments"
     ▼
┌──────────────────────────┐
│  Provider Dashboard      │
└──────────────────────────┘
```

---

## 📊 Collection Schemas

### `appointment_requests` Collection

**Purpose**: Temporary storage for pending booking requests

| Field | Type | Description |
|-------|------|-------------|
| `idpat` | String | Patient ID |
| `patientName` | String | Patient's full name |
| `patientPhone` | String | Patient's phone number |
| `idpro` | String | Provider ID |
| `service` | String | Service type (e.g., "Home Visit", "Consultation") |
| `prix` | Number | Service price |
| `serviceFee` | Number | Platform service fee |
| `paymentMethod` | String | Payment method ("cash", "card", etc.) |
| `type` | String | Appointment type ("instant" or "scheduled") |
| `appointmentDate` | Timestamp | Scheduled date for appointment |
| `appointmentTime` | String | Time slot (e.g., "14:30") |
| `patientLocation` | Map | Patient's location coordinates |
| `providerLocation` | Map | Provider's location coordinates |
| `patientAddress` | String | Patient's address text |
| `notes` | String | Additional notes from patient |
| `status` | String | "pending" (always pending in this collection) |
| `etat` | String | "en_attente" (French status) |
| `createdAt` | Timestamp | Request creation time |
| `updatedAt` | Timestamp | Last update time |

**Lifecycle**: 
- Created when patient books
- Deleted after 10 minutes if not accepted/rejected
- Deleted immediately when rejected
- Deleted when accepted (data copied to `appointments`)

---

### `appointments` Collection

**Purpose**: Main storage for accepted/confirmed appointments

| Field | Type | Description |
|-------|------|-------------|
| `idpat` | String | Patient ID |
| `patientName` | String | Patient's full name |
| `patientPhone` | String | Patient's phone number |
| `idpro` | String | Provider ID |
| `service` | String | Service type |
| `prix` | Number | Service price |
| `serviceFee` | Number | Platform service fee |
| `paymentMethod` | String | Payment method |
| `type` | String | Appointment type |
| `appointmentDate` | Timestamp | Scheduled date |
| `appointmentTime` | String | Time slot |
| `patientLocation` | Map | Patient's location |
| `providerLocation` | Map | Provider's location |
| `patientAddress` | String | Patient's address |
| `notes` | String | Notes |
| `status` | String | "accepted", "confirmed", "completed", etc. |
| `etat` | String | "accepté", "confirmé", "terminé", etc. |
| `createdAt` | Timestamp | Original request creation time |
| `acceptedAt` | Timestamp | When provider accepted |
| `updatedAt` | Timestamp | Last update time |

**Lifecycle**:
- Created when provider accepts a request
- Updated as appointment progresses through states
- Kept permanently for history/analytics

---

## 🛠️ Implementation

### 1. Service Class: `AppointmentRequestService`

Located in: `lib/services/appointment_request_service.dart`

#### Key Methods:

**Create Request (Patient Side)**
```dart
AppointmentRequestService.createAppointmentRequest(
  providerId: 'provider_123',
  patientId: 'patient_456',
  patientName: 'John Doe',
  patientPhone: '+212600000000',
  service: 'Home Visit',
  prix: 200.0,
  serviceFee: 20.0,
  paymentMethod: 'cash',
  type: 'scheduled',
  appointmentDate: DateTime(2025, 10, 17, 14, 30),
  appointmentTime: '14:30',
  patientAddress: '123 Main St',
  notes: 'Please bring medical equipment',
);
```

**Get Pending Requests (Provider Side)**
```dart
// One-time fetch
List<AppointmentRequest> requests = 
  await AppointmentRequestService.getProviderPendingRequests(providerId);

// Real-time stream
Stream<List<AppointmentRequest>> stream = 
  AppointmentRequestService.getProviderPendingRequestsStream(providerId);
```

**Accept Request**
```dart
bool success = await AppointmentRequestService.acceptAppointmentRequest(requestId);
// Copies to 'appointments' collection and deletes from 'appointment_requests'
```

**Reject Request**
```dart
bool success = await AppointmentRequestService.rejectAppointmentRequest(requestId);
// Deletes from 'appointment_requests' collection
```

**Get Upcoming Appointments**
```dart
// One-time fetch
List<UpcomingAppointment> appointments = 
  await AppointmentRequestService.getProviderUpcomingAppointments(providerId);

// Real-time stream
Stream<List<UpcomingAppointment>> stream = 
  AppointmentRequestService.getProviderUpcomingAppointmentsStream(providerId);
```

**Manual Cleanup**
```dart
int deletedCount = await AppointmentRequestService.cleanupOldPendingRequests();
// Deletes requests older than 10 minutes
```

---

### 2. Cloud Functions

Located in: `functions/cleanup_expired_requests.js`

#### Functions:

**1. Scheduled Cleanup (Runs every 5 minutes)**
```javascript
cleanupExpiredAppointmentRequests
```
- Automatically runs every 5 minutes
- Deletes requests older than 10 minutes with status 'pending'
- No manual trigger needed

**2. Manual Cleanup (HTTP Trigger)**
```bash
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/manualCleanupExpiredRequests
```
- Manually trigger cleanup via HTTP request
- Useful for testing or immediate cleanup

**3. Auto-Schedule Deletion (onCreate Trigger)**
```javascript
scheduleRequestExpiration
```
- Triggers when new request is created
- Schedules deletion in `scheduled_deletions` collection
- Automatically cancelled if request is accepted/rejected

**4. Cancel Scheduled Deletion (onDelete Trigger)**
```javascript
cancelScheduledDeletion
```
- Triggers when request is deleted/accepted
- Cleans up scheduled deletion records

---

## 🚀 Deployment

### Deploy Cloud Functions

1. **Initialize Firebase Functions** (if not already done)
```bash
cd functions
npm install
```

2. **Deploy all functions**
```bash
firebase deploy --only functions
```

3. **Deploy specific function**
```bash
firebase deploy --only functions:cleanupExpiredAppointmentRequests
```

4. **Verify deployment**
```bash
firebase functions:log
```

---

## 🔐 Firestore Security Rules

Add these rules to `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Appointment Requests Collection
    match /appointment_requests/{requestId} {
      // Patients can create their own requests
      allow create: if request.auth != null && 
                      request.resource.data.idpat == request.auth.uid;
      
      // Patients can read their own requests
      allow read: if request.auth != null && 
                    (resource.data.idpat == request.auth.uid || 
                     resource.data.idpro == request.auth.uid);
      
      // Providers can read and delete (reject) their requests
      allow delete: if request.auth != null && 
                      resource.data.idpro == request.auth.uid;
      
      // No updates allowed (use accept/reject instead)
      allow update: if false;
    }
    
    // Appointments Collection
    match /appointments/{appointmentId} {
      // Only providers can create (via accept)
      allow create: if request.auth != null && 
                      request.resource.data.idpro == request.auth.uid;
      
      // Patients and providers can read their appointments
      allow read: if request.auth != null && 
                    (resource.data.idpat == request.auth.uid || 
                     resource.data.idpro == request.auth.uid);
      
      // Providers can update their appointments
      allow update: if request.auth != null && 
                      resource.data.idpro == request.auth.uid;
      
      // No deletion (keep for history)
      allow delete: if false;
    }
    
    // Scheduled Deletions (only Cloud Functions can access)
    match /scheduled_deletions/{deletionId} {
      allow read, write: if false; // Only Cloud Functions
    }
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

---

## 📱 UI Integration

### Provider Dashboard Updates

**Before** (Old system):
- "Today's Schedule" section
- Shows only today's appointments
- Mixed pending/confirmed statuses

**After** (New system):
- "Pending Requests" section (from `appointment_requests`)
- "Upcoming Appointments" section (from `appointments`, future dates)
- Clear separation of pending vs confirmed

### UI Components Needed:

1. **Pending Request Card**
   - Shows patient info, service, date/time, price
   - "Accept" button (green) → calls `acceptAppointmentRequest()`
   - "Reject" button (red) → calls `rejectAppointmentRequest()`
   - Countdown timer showing time remaining before auto-deletion

2. **Upcoming Appointment Card**
   - Shows patient info, service, date/time
   - "View Details" button
   - "Mark Complete" button (for completed appointments)
   - Color-coded by date (today = green, tomorrow = blue, future = gray)

---

## 🧪 Testing Workflow

### Test Scenario:

1. **Patient creates booking request**
   ```dart
   await AppointmentRequestService.createAppointmentRequest(
     providerId: 'test_provider',
     patientId: 'test_patient',
     patientName: 'Test Patient',
     patientPhone: '+212600000000',
     service: 'Home Visit',
     prix: 200.0,
     serviceFee: 20.0,
     paymentMethod: 'cash',
     type: 'scheduled',
     appointmentDate: DateTime(2025, 10, 17, 14, 30),
     appointmentTime: '14:30',
   );
   ```

2. **Check in Firestore Console**
   - Go to `appointment_requests` collection
   - Verify new document with `status: pending`

3. **Provider views dashboard**
   - Should see request in "Pending Requests" section
   - Countdown timer shows time remaining

4. **Provider accepts request**
   ```dart
   await AppointmentRequestService.acceptAppointmentRequest(requestId);
   ```

5. **Verify in Firestore Console**
   - Request deleted from `appointment_requests`
   - New document in `appointments` with `status: accepted`
   - Shows in "Upcoming Appointments" section

6. **Test auto-cleanup (wait 10 minutes)**
   - Create request but don't accept/reject
   - Wait 10 minutes
   - Cloud Function should auto-delete

---

## 📊 Monitoring & Logs

### View Cloud Function Logs

```bash
# All logs
firebase functions:log

# Specific function logs
firebase functions:log --only cleanupExpiredAppointmentRequests

# Real-time logs
firebase functions:log --since 1h --follow
```

### Key Log Messages:

- `🧹 Starting cleanup of expired appointment requests...`
- `📦 Found X expired requests to delete`
- `✅ Successfully deleted X expired appointment requests`
- `📝 New appointment request created: {requestId}`
- `⏰ Scheduled deletion for {requestId} at {time}`

---

## ⚠️ Important Notes

1. **Time Limit**: Requests auto-delete after 10 minutes
2. **No Updates**: Requests cannot be updated, only accepted/rejected
3. **Atomicity**: Accept operation uses batch writes to ensure data consistency
4. **History**: Appointments are never deleted (keep for analytics)
5. **Indexes**: May need composite indexes for complex queries

### Required Firestore Indexes:

```
appointment_requests
  - idpro (Ascending) + status (Ascending) + createdAt (Descending)

appointments
  - idpro (Ascending) + status (Ascending) + appointmentDate (Ascending)
```

Create indexes via Firebase Console or automatically when query fails.

---

## 🎯 Next Steps

1. ✅ Service created (`appointment_request_service.dart`)
2. ✅ Cloud Functions created (`cleanup_expired_requests.js`)
3. ⏳ Update provider dashboard UI
4. ⏳ Update patient booking flow
5. ⏳ Deploy Cloud Functions
6. ⏳ Deploy Firestore Rules
7. ⏳ Test complete workflow

---

## 📞 Support

For issues or questions:
1. Check Firestore Console for data
2. Check Cloud Function logs
3. Verify security rules
4. Test with manual cleanup function

