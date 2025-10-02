# 🔥 Deploy Updated Firestore Rules

## What Changed
- ✅ Removed strict validation that required non-empty comments
- ✅ Removed check for patient document existence
- ✅ Fixed delete permission to check `resource.data` instead of `request.resource.data`
- ✅ Comments can now be empty (optional)

## How to Deploy

### Option 1: Firebase Console (Easiest)
1. Go to: https://console.firebase.google.com/
2. Select your project
3. Go to **Firestore Database** → **Rules** tab
4. Copy and paste the content from `firestore.rules`
5. Click **Publish**

### Option 2: Firebase CLI
```bash
firebase deploy --only firestore:rules
```

## Test After Deployment
1. Hot restart your app
2. Complete an appointment as provider
3. Patient should see the rating screen
4. Submit a review (with or without comment)
5. Check if it saves successfully

## Updated Rules for `/avis` Collection
```
match /avis/{id_avis} {
  allow read: if request.auth != null;

  allow create: if request.auth != null
    && request.resource.data.idpat == request.auth.uid
    && request.resource.data.note is int
    && request.resource.data.note >= 1 && request.resource.data.note <= 5
    && request.resource.data.commentaire is string
    && request.resource.data.commentaire.size() < 1000;

  allow delete: if request.auth != null
    && resource.data.idpat == request.auth.uid;
}
```

## What's Now Allowed
✅ Empty comments (commentaire: "")
✅ Comments up to 999 characters
✅ Rating from 1-5 stars
✅ Only the patient who wrote the review can delete it
✅ No need for patient document to exist in `/patients` collection

## Verify Deployment
Run this in Firebase Console → Firestore → Rules tab to verify:
```
service cloud.firestore {
  match /databases/{database}/documents {
    match /avis/{id_avis} {
      // Rules should match the updated version above
    }
  }
}
```
