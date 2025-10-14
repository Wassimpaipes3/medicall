# Analytics Composite Indexes Fix

## Problem
The analytics charts in the provider dashboard were showing errors:
```
[cloud_firestore/failed-precondition] The query requires an index
```

## Root Cause
The analytics service (`provider_analytics_service.dart`) performs complex queries with multiple conditions:

1. **Earnings Analytics Query**:
   - Filter by: `professionnelId` + `etat` (whereIn) + `dateRendezVous` range
   - Order by: `dateRendezVous`

2. **Appointments Analytics Query**:
   - Filter by: `professionnelId` + `dateRendezVous` range
   - Order by: `dateRendezVous`

3. **Ratings Analytics Query**:
   - Filter by: `professionnelId` + `dateCreation` range
   - Order by: `dateCreation`

These compound queries require **composite indexes** to work in Firestore.

## Solution

### Updated `firestore.indexes.json`

Added 3 composite indexes:

```json
{
  "indexes": [
    // 1. Appointments by provider and date (for appointments analytics)
    {
      "collectionGroup": "appointments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "professionnelId", "order": "ASCENDING" },
        { "fieldPath": "dateRendezVous", "order": "ASCENDING" }
      ]
    },
    
    // 2. Appointments by status, provider, and date (for earnings analytics)
    {
      "collectionGroup": "appointments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "etat", "order": "ASCENDING" },
        { "fieldPath": "professionnelId", "order": "ASCENDING" },
        { "fieldPath": "dateRendezVous", "order": "ASCENDING" }
      ]
    },
    
    // 3. Reviews by provider and date (for ratings analytics)
    {
      "collectionGroup": "avis",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "professionnelId", "order": "ASCENDING" },
        { "fieldPath": "dateCreation", "order": "ASCENDING" }
      ]
    }
  ]
}
```

### Deployment

```bash
firebase deploy --only firestore:indexes
```

✅ **Status**: Deployed successfully

## Index Building Time

⚠️ **IMPORTANT**: Composite indexes take time to build!

- Small databases (< 1000 docs): **1-5 minutes**
- Medium databases (1000-10000 docs): **5-30 minutes**
- Large databases (> 10000 docs): **30 minutes to hours**

### Check Index Status

1. Go to Firebase Console: https://console.firebase.google.com/project/nursinghomecare-1807f/firestore/indexes
2. Look for the 3 new indexes:
   - `appointments`: `professionnelId` + `dateRendezVous`
   - `appointments`: `etat` + `professionnelId` + `dateRendezVous`
   - `avis`: `professionnelId` + `dateCreation`
3. Wait until status shows **"Enabled"** (green checkmark)

## Testing After Index Build

Once indexes are enabled:

1. **Hot Restart** the app (not hot reload)
2. Login as provider
3. Navigate to analytics screens:
   - **Dashboard** → Tap on earnings/appointments/ratings charts
   - Check the detailed analytics screens
4. Try switching between time periods (Daily/Weekly/Monthly)

### Expected Behavior

✅ Charts load successfully
✅ No `[cloud_firestore/failed-precondition]` errors
✅ Data displayed for each time period
✅ Smooth switching between Daily/Weekly/Monthly views

## Analytics Features

### 1. Earnings Analytics (`earnings_analytics_screen.dart`)
- Shows revenue over time
- Line chart with earnings per period
- Filters by confirmed/completed appointments
- Sum of `tarif` field

### 2. Appointments Analytics (`appointments_analytics_screen.dart`)
- Shows appointment counts over time
- Stacked bar chart with completed/pending/cancelled
- Categorizes by `etat` field values

### 3. Ratings Analytics (`ratings_analytics_screen.dart`)
- Shows rating distribution (1-5 stars)
- Bar chart showing count per rating
- Filters by time period

## Technical Details

### Query Examples

**Earnings (Daily)**:
```dart
.where('professionnelId', isEqualTo: userId)
.where('etat', whereIn: ['confirmé', 'terminé'])
.where('dateRendezVous', isGreaterThanOrEqualTo: startOfDay)
.where('dateRendezVous', isLessThan: endOfDay)
```

**Appointments (Weekly)**:
```dart
.where('professionnelId', isEqualTo: userId)
.where('dateRendezVous', isGreaterThanOrEqualTo: startOfWeek)
.where('dateRendezVous', isLessThan: endOfWeek)
```

**Ratings (Monthly)**:
```dart
.where('professionnelId', isEqualTo: userId)
.where('dateCreation', isGreaterThanOrEqualTo: thirtyDaysAgo)
```

### Why Indexes Are Needed

Firestore requires an index when you:
1. Use multiple fields in `.where()` clauses
2. Combine `.where()` with `.orderBy()` on different fields
3. Use range queries (>, <, >=, <=) on multiple fields

These queries can't use single-field indexes and need compound indexes to work efficiently.

## Troubleshooting

### Indexes Still Building
- Wait patiently - index building is automatic but takes time
- Check Firebase Console for progress
- Don't try to use analytics until indexes show "Enabled"

### Still Getting Index Errors
1. Verify indexes are deployed: `firebase deploy --only firestore:indexes`
2. Check Firebase Console to confirm indexes exist
3. Ensure index status is "Enabled" not "Building"
4. Try hot restart after indexes are enabled

### Wrong Data Showing
1. Verify appointments have correct fields:
   - `professionnelId` (matches provider uid)
   - `dateRendezVous` (Timestamp)
   - `etat` ('confirmé', 'terminé', etc.)
   - `tarif` (number)

2. Verify reviews have correct fields:
   - `professionnelId` (matches provider uid)
   - `dateCreation` (Timestamp)
   - `note` or `rating` or `etoiles` (1-5)

## Summary

✅ **Fixed**: Added 3 composite indexes for analytics queries
✅ **Deployed**: Indexes are now building in Firebase
⏳ **Waiting**: Indexes need 5-30 minutes to build
📊 **Result**: Analytics charts will work once indexes are enabled

The analytics queries were too complex for automatic indexing. Now they have proper composite indexes and will work smoothly!
