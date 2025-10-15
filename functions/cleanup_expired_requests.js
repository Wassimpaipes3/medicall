/**
 * Cloud Function to automatically cleanup expired appointment requests
 * 
 * This function runs every 5 minutes and deletes appointment_requests
 * that are older than 10 minutes and still have status 'pending'
 * 
 * Deploy with:
 * firebase deploy --only functions:cleanupExpiredAppointmentRequests
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled function that runs every 5 minutes
 * Deletes appointment_requests older than 10 minutes with status 'pending'
 */
exports.cleanupExpiredAppointmentRequests = functions.pubsub
    .schedule('every 5 minutes')
    .onRun(async(context) => {
        try {
            console.log('🧹 Starting cleanup of expired appointment requests...');

            // Calculate cutoff time (10 minutes ago)
            const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
            const cutoffTimestamp = admin.firestore.Timestamp.fromDate(tenMinutesAgo);

            console.log(`   Cutoff time: ${tenMinutesAgo.toISOString()}`);

            // Query for expired pending requests
            const expiredRequests = await db
                .collection('appointment_requests')
                .where('status', '==', 'pending')
                .where('createdAt', '<', cutoffTimestamp)
                .get();

            if (expiredRequests.empty) {
                console.log('   ✅ No expired requests found');
                return null;
            }

            console.log(`   📦 Found ${expiredRequests.size} expired requests to delete`);

            // Delete in batches (max 500 per batch)
            const batchSize = 500;
            let deletedCount = 0;

            for (let i = 0; i < expiredRequests.docs.length; i += batchSize) {
                const batch = db.batch();
                const batchDocs = expiredRequests.docs.slice(i, i + batchSize);

                batchDocs.forEach(doc => {
                    console.log(`   🗑️  Deleting request: ${doc.id}`);
                    batch.delete(doc.ref);
                });

                await batch.commit();
                deletedCount += batchDocs.length;
            }

            console.log(`   ✅ Successfully deleted ${deletedCount} expired appointment requests`);
            return null;

        } catch (error) {
            console.error('❌ Error cleaning up expired requests:', error);
            throw error;
        }
    });

/**
 * Alternative: HTTP-triggered function for manual cleanup
 * Call with: POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/manualCleanupExpiredRequests
 */
exports.manualCleanupExpiredRequests = functions.https.onRequest(async(req, res) => {
    try {
        console.log('🧹 Manual cleanup triggered...');

        const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);
        const cutoffTimestamp = admin.firestore.Timestamp.fromDate(tenMinutesAgo);

        const expiredRequests = await db
            .collection('appointment_requests')
            .where('status', '==', 'pending')
            .where('createdAt', '<', cutoffTimestamp)
            .get();

        if (expiredRequests.empty) {
            res.status(200).json({
                success: true,
                message: 'No expired requests found',
                deletedCount: 0
            });
            return;
        }

        const batch = db.batch();
        expiredRequests.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        await batch.commit();

        res.status(200).json({
            success: true,
            message: `Deleted ${expiredRequests.size} expired requests`,
            deletedCount: expiredRequests.size
        });

    } catch (error) {
        console.error('❌ Error in manual cleanup:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * Trigger function when a new appointment request is created
 * Automatically schedule deletion after 10 minutes if still pending
 */
exports.scheduleRequestExpiration = functions.firestore
    .document('appointment_requests/{requestId}')
    .onCreate(async(snap, context) => {
        try {
            const requestId = context.params.requestId;
            const requestData = snap.data();

            console.log(`📝 New appointment request created: ${requestId}`);

            // Schedule deletion after 10 minutes
            const expirationTime = new Date(Date.now() + 10 * 60 * 1000);

            await db.collection('scheduled_deletions').add({
                requestId: requestId,
                expirationTime: admin.firestore.Timestamp.fromDate(expirationTime),
                status: 'pending',
                patientId: requestData.idpat,
                providerId: requestData.idpro,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            console.log(`   ⏰ Scheduled deletion for ${requestId} at ${expirationTime.toISOString()}`);
            return null;

        } catch (error) {
            console.error('❌ Error scheduling request expiration:', error);
            return null;
        }
    });

/**
 * Clean up scheduled deletions when request is accepted/rejected
 */
exports.cancelScheduledDeletion = functions.firestore
    .document('appointment_requests/{requestId}')
    .onDelete(async(snap, context) => {
        try {
            const requestId = context.params.requestId;

            // Find and delete the scheduled deletion
            const scheduledDeletions = await db
                .collection('scheduled_deletions')
                .where('requestId', '==', requestId)
                .get();

            if (!scheduledDeletions.empty) {
                const batch = db.batch();
                scheduledDeletions.docs.forEach(doc => {
                    batch.delete(doc.ref);
                });
                await batch.commit();

                console.log(`✅ Cancelled scheduled deletion for request: ${requestId}`);
            }

            return null;

        } catch (error) {
            console.error('❌ Error cancelling scheduled deletion:', error);
            return null;
        }
    });