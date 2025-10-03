// One-time script to clean up existing provider_requests
// Run this with: node cleanup_expired_requests.js

const admin = require('firebase-admin');
const serviceAccount = require('./functions/service-account-key.json'); // You'll need to download this

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupAllProviderRequests() {
    console.log('🧹 Starting cleanup of all provider_requests...');

    try {
        const snapshot = await db.collection('provider_requests').get();

        if (snapshot.empty) {
            console.log('✅ No provider_requests found - collection is already clean!');
            return;
        }

        console.log(`📊 Found ${snapshot.size} provider_requests documents`);

        // Delete in batches of 500 (Firestore limit)
        const batchSize = 500;
        let deleted = 0;

        for (let i = 0; i < snapshot.docs.length; i += batchSize) {
            const batch = db.batch();
            const batchDocs = snapshot.docs.slice(i, i + batchSize);

            batchDocs.forEach(doc => {
                batch.delete(doc.ref);
            });

            await batch.commit();
            deleted += batchDocs.length;
            console.log(`✅ Deleted ${deleted}/${snapshot.size} documents...`);
        }

        console.log(`🎉 Cleanup complete! Deleted ${deleted} documents`);
    } catch (error) {
        console.error('❌ Error during cleanup:', error);
    }

    process.exit(0);
}

cleanupAllProviderRequests();