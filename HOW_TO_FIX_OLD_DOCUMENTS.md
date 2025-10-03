# 🔧 How to Fix Old Documents Without expireAt

## Problem
Documents created **before** we added the `expireAt` field won't be auto-deleted because the cleanup function can't find them.

## Solution: Run the Migration Function

Once deployed, the migration function will:
1. Find all documents in `provider_requests` collection
2. Skip documents that already have `expireAt`
3. Add `expireAt` (set to 1 minute from now) to old documents
4. These documents will be deleted by the next cleanup cycle

## How to Run the Migration

### Option 1: From Firebase Console (Easiest)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **nursinghomecare-1807f**
3. Go to **Functions** section (left menu)
4. Find the function: `migrateProviderRequestsExpireAt`
5. Click on it → Click **"Testing"** tab
6. Click **"Run Test"** button
7. Check the logs to see how many documents were updated

### Option 2: Visit the Function URL Directly
Open this URL in your browser (replace REGION with your region, usually `us-central1`):
```
https://REGION-nursinghomecare-1807f.cloudfunctions.net/migrateProviderRequestsExpireAt
```

Example:
```
https://us-central1-nursinghomecare-1807f.cloudfunctions.net/migrateProviderRequestsExpireAt
```

You should see a response like:
```json
{
  "success": true,
  "updated": 5,
  "skipped": 0,
  "total": 5,
  "message": "Migration complete: 5 updated, 0 skipped"
}
```

### Option 3: Using PowerShell (Command Line)
```powershell
# Replace REGION with your region (usually us-central1)
$url = "https://us-central1-nursinghomecare-1807f.cloudfunctions.net/migrateProviderRequestsExpireAt"
Invoke-WebRequest -Uri $url
```

## What Happens After Migration?

1. **Immediate**: All old documents get `expireAt` = 1 minute from now
2. **Within 5 minutes**: The scheduled cleanup function runs
3. **Result**: Old documents are deleted automatically

## Verify It Worked

### Check Firebase Console
1. Go to **Firestore Database**
2. Open `provider_requests` collection
3. You should see:
   - Documents now have `expireAt` field
   - Within a few minutes, old documents disappear

### Check Function Logs
```powershell
cd functions
firebase functions:log | Select-String "migrateProviderRequestsExpireAt"
```

You should see:
```
migrateProviderRequestsExpireAt: ✏️ Adding expireAt to doc_id_1
migrateProviderRequestsExpireAt: ✏️ Adding expireAt to doc_id_2
migrateProviderRequestsExpireAt: ✅ Migration complete! Updated 5 documents
```

## Important Notes

⚠️ **Safe to run multiple times**: The function checks if `expireAt` already exists and skips those documents

⚠️ **1-minute expiry**: Old documents are set to expire in 1 minute (they'll be deleted quickly)

⚠️ **New documents**: All new provider requests created after the code update will have `expireAt` automatically

## Troubleshooting

### "No documents to migrate"
- This is good! It means all documents already have `expireAt`

### "Permission denied" error
- The function should be public (no auth required)
- Check Firebase Functions permissions

### Documents still not deleted after 10 minutes
1. Check if migration actually ran (check logs)
2. Verify documents have `expireAt` field in Firestore Console
3. Check cleanup function logs: `firebase functions:log | Select-String "cleanupExpiredRequests"`
4. Verify `expireAt` is in the past

## Summary

✅ **Migration function**: Adds `expireAt` to old documents  
✅ **Automatic cleanup**: Runs every 5 minutes  
✅ **New documents**: Automatically include `expireAt` (10 minutes)  
✅ **Safe to use**: Won't affect documents that already have `expireAt`  
