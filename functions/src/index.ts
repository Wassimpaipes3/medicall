// functions/src/index.ts
import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

/**
 * 1. When a new user is created in /users → auto-create their profile
 *    - If patient → create in /patients/{uid}
 *    - If doctor/nurse → create in /professionnels/{uid}
 */
export const onUserCreated = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const uid = context.params.userId;

    // DISABLED: Patient documents are now created directly in the auth service
    // if (userData.role === "patient") {
    //   await db.collection("patients").doc(uid).set({
    //     userId: uid,
    //     allergies: "Aucune",
    //     antecedents: "Aucun",
    //     dossiers_medicaux: "",
    //     groupe_sanguin: "Non renseigné",
    //     notifications_non_lues: 0,
    //   });
    //   console.log(`✅ Patient profile created for ${uid}`);
    // } else
    if (userData.role === "doctor" || userData.role === "nurse") {
      await db.collection("professionnels").doc(uid).set({
        userId: uid,
        nom: userData.nom,
        email: userData.email,
        role: userData.role,
        specialite: userData.specialite || "Non spécifiée",
        profession: userData.profession || "medecin",
        bio: "",
        consultationsCount: 0,
        photoProfile: userData.photoProfile || "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Professional profile created for ${uid}`);
    }
  });

/**
 * 2. When a Firebase Auth user is deleted → clean up their Firestore data
 *    This handles cases where user is deleted from Firebase Console or other external means
 */
export const onAuthUserDeleted = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const userEmail = user.email || "unknown";

  console.log(`🗑️ Auth user deleted: ${uid} (${userEmail}), starting Firestore cleanup...`);

  try {
    // Helper function to safely delete a document
    const safeDeleteDoc = async (collection: string, docId: string): Promise<void> => {
      try {
        const docRef = db.collection(collection).doc(docId);
        const doc = await docRef.get();
        if (doc.exists) {
          await docRef.delete();
          console.log(`✅ Deleted ${collection}/${docId}`);
        } else {
          console.log(`ℹ️ Document ${collection}/${docId} doesn't exist`);
        }
      } catch (error) {
        console.error(`❌ Error deleting ${collection}/${docId}:`, error);
      }
    };

    // Helper function to delete documents by query
    const deleteByQuery = async (
      collection: string,
      field: string,
      value: string,
      description: string
    ): Promise<void> => {
      try {
        const query = db.collection(collection).where(field, "==", value);
        const snapshot = await query.get();

        if (snapshot.empty) {
          console.log(`ℹ️ No ${description} found for user ${uid}`);
          return;
        }

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        await batch.commit();
        console.log(`✅ Deleted ${snapshot.size} ${description} for user ${uid}`);
      } catch (error) {
        console.error(`❌ Error deleting ${description}:`, error);
      }
    };

    // Delete main profile documents
    await safeDeleteDoc("users", uid);
    await safeDeleteDoc("patients", uid);
    await safeDeleteDoc("professionals", uid);
    await safeDeleteDoc("professionnels", uid); // Legacy collection name

    // Delete related documents
    await deleteByQuery("appointments", "patientId", uid, "appointments as patient");
    await deleteByQuery("appointments", "professionalId", uid, "appointments as professional");
    await deleteByQuery("avis", "userId", uid, "reviews");
    await deleteByQuery("disponibilites", "professionalId", uid, "availability slots");
    await deleteByQuery("notifications", "userId", uid, "notifications");

    console.log(`🎉 Firestore cleanup completed for user ${uid}`);
  } catch (error) {
    console.error(`❌ Error during Firestore cleanup for user ${uid}:`, error);
    // Don't throw - we don't want to prevent Auth deletion if Firestore cleanup fails
  }
});

/**
 * 3. When a user document is manually deleted from Firestore → clean up Auth and related data
 *    This handles cases where admin deletes user from Firestore Console
 */
export const onUserDocumentDeleted = functions.firestore
  .document("users/{userId}")
  .onDelete(async (snap, context) => {
    const uid = context.params.userId;
    const userData = snap.data();
    const userEmail = userData?.email || "unknown";

    console.log(`🗑️ User document deleted: ${uid} (${userEmail}), starting comprehensive cleanup...`);

    try {
      // Helper function to safely delete a document
      const safeDeleteDoc = async (collection: string, docId: string): Promise<void> => {
        try {
          const docRef = db.collection(collection).doc(docId);
          const doc = await docRef.get();
          if (doc.exists) {
            await docRef.delete();
            console.log(`✅ Deleted ${collection}/${docId}`);
          }
        } catch (error) {
          console.error(`❌ Error deleting ${collection}/${docId}:`, error);
        }
      };

      // Helper function to delete documents by query
      const deleteByQuery = async (
        collection: string,
        field: string,
        value: string,
        description: string
      ): Promise<void> => {
        try {
          const query = db.collection(collection).where(field, "==", value);
          const snapshot = await query.get();

          if (snapshot.empty) {
            console.log(`ℹ️ No ${description} found for user ${uid}`);
            return;
          }

          const batch = db.batch();
          snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });

          await batch.commit();
          console.log(`✅ Deleted ${snapshot.size} ${description} for user ${uid}`);
        } catch (error) {
          console.error(`❌ Error deleting ${description}:`, error);
        }
      };

      // Step 1: Delete Firebase Auth user (if exists)
      try {
        console.log(`🔑 Attempting to delete Firebase Auth user: ${uid}`);
        await admin.auth().deleteUser(uid);
        console.log(`✅ Firebase Auth user ${uid} deleted successfully`);
      } catch (authError: unknown) {
        const error = authError as {code?: string};
        if (error.code === "auth/user-not-found") {
          console.log(`ℹ️ Firebase Auth user ${uid} doesn't exist (already deleted)`);
        } else {
          console.error(`❌ Error deleting Firebase Auth user ${uid}:`, authError);
        }
      }

      // Step 2: Delete profile documents
      await safeDeleteDoc("patients", uid);
      await safeDeleteDoc("professionals", uid);
      await safeDeleteDoc("professionnels", uid); // Legacy collection name

      // Step 3: Delete related documents
      await deleteByQuery("appointments", "patientId", uid, "appointments as patient");
      await deleteByQuery("appointments", "professionalId", uid, "appointments as professional");
      await deleteByQuery("avis", "userId", uid, "reviews");
      await deleteByQuery("disponibilites", "professionalId", uid, "availability slots");
      await deleteByQuery("notifications", "userId", uid, "notifications");

      console.log(`🎉 Comprehensive cleanup completed for user ${uid}`);
    } catch (error) {
      console.error(`❌ Error during comprehensive cleanup for user ${uid}:`, error);
    }
  });

/**
 * 4. When an appointment is booked → notify the doctor
 */
export const onAppointmentCreated = functions.firestore
  .document("appointments/{appId}")
  .onCreate(async (snap, context) => {
    const appointment = snap.data();

    const patientId = appointment.idpat;
    const doctorId = appointment.idpro;
    const date = appointment.date;
    const heure = appointment.heure;
    // const note = appointment.note || 'Pas de note';

    // Get patient name
    const patientDoc = await db.collection("patients").doc(patientId).get();
    const patientName = patientDoc.exists ?
      patientDoc.data()?.nom || "Un patient" :
      "Un patient";

    // Notify doctor
    await db.collection("notifications").add({
      destinataire: doctorId,
      message: `🔔 ${patientName} a réservé un rendez-vous le ${date} à ${heure}. Note: ${appointment.note || "Pas de note"}`,
      type: "appointment",
      datetime: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      senderId: patientId,
      payload: {
        appId: context.params.appId,
        patientId: patientId,
        action: "new_booking",
      },
    });


    console.log(`📩 Notification sent to doctor ${doctorId}`);
  });

/**
 * 3. When a review is added → only allow if there was a confirmed appointment
 */
export const onReviewCreated = functions.firestore
  .document("avis/{avisId}")
  .onCreate(async (snap) => {
    const review = snap.data();
    const patientId = review.idpat;
    const proId = review.idpro;

    // Check for a valid appointment between them (confirmed OR completed)
    const querySnapshot = await db.collection("appointments")
      .where("idpat", "==", patientId)
      .where("idpro", "==", proId)
      .where("status", "in", ["confirmed", "completed", "arrived"]) // Allow reviews for completed appointments
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      // ❌ No valid appointment → delete the review
      await snap.ref.delete();
      console.warn(`❌ Review deleted: No valid appointment between ${patientId} and ${proId}`);
      return;
    }

    console.log(`✅ Review allowed for professional ${proId}`);

    // 🌟 AUTO-UPDATE PROVIDER RATING
    try {
      // Get all reviews for this provider
      const allReviewsSnapshot = await db.collection("avis")
        .where("idpro", "==", proId)
        .get();

      if (!allReviewsSnapshot.empty) {
        let totalRating = 0;
        let count = 0;

        allReviewsSnapshot.forEach((doc) => {
          const reviewData = doc.data();
          if (reviewData.note && typeof reviewData.note === "number") {
            totalRating += reviewData.note;
            count++;
          }
        });

        const averageRating = count > 0 ? totalRating / count : 0;

        // Update provider's rating and review count
        await db.collection("professionals").doc(proId).update({
          rating: parseFloat(averageRating.toFixed(2)),
          reviewsCount: count,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Updated provider ${proId}: rating=${averageRating.toFixed(2)}, reviews=${count}`);
      }
    } catch (error) {
      console.error(`❌ Error updating provider rating: ${error}`);
    }
  });

/**
 * 4. Clean up expired provider requests (backup for Firestore TTL)
 *    Runs every 5 minutes to delete documents with expireAt < now
 */
export const cleanupExpiredRequests = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    try {
      // Find all requests where expireAt is in the past
      const expiredSnapshot = await db.collection("provider_requests")
        .where("expireAt", "<=", now)
        .get();

      if (expiredSnapshot.empty) {
        console.log("🧹 No expired provider requests to clean up");
        return;
      }

      // Delete expired requests in batch
      const batch = db.batch();
      expiredSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`✅ Deleted ${expiredSnapshot.size} expired provider requests`);
    } catch (error) {
      console.error("❌ Error cleaning up expired requests:", error);
    }
  });

/**
 * 4b. ONE-TIME MIGRATION: Add expireAt to existing provider_requests
 *     This is a manual trigger function to add expireAt field to documents
 *     that were created before we implemented auto-deletion.
 *
 *     Call this once to fix old documents:
 *     https://REGION-PROJECT_ID.cloudfunctions.net/migrateProviderRequestsExpireAt
 */
export const migrateProviderRequestsExpireAt = functions.https.onRequest(async (req, res) => {
  try {
    console.log("🔧 Starting expireAt migration...");

    const snapshot = await db.collection("provider_requests").get();

    if (snapshot.empty) {
      console.log("📭 No documents found");
      res.json({success: true, updated: 0, message: "No documents to migrate"});
      return;
    }

    console.log(`📊 Found ${snapshot.size} documents`);

    let updatedCount = 0;
    let skippedCount = 0;
    const batch = db.batch();

    snapshot.docs.forEach((doc) => {
      const data = doc.data();

      // Skip if already has expireAt
      if (data.expireAt) {
        skippedCount++;
        return;
      }

      // Add expireAt: 1 minute from now (old docs will be deleted quickly)
      const expireAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 1 * 60 * 1000) // 1 minute
      );

      batch.update(doc.ref, {
        expireAt: expireAt,
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      updatedCount++;
      console.log(`✏️ Adding expireAt to ${doc.id}`);
    });

    if (updatedCount > 0) {
      await batch.commit();
      console.log(`✅ Migration complete! Updated ${updatedCount} documents`);
    }

    res.json({
      success: true,
      updated: updatedCount,
      skipped: skippedCount,
      total: snapshot.size,
      message: `Migration complete: ${updatedCount} updated, ${skippedCount} skipped`,
    });
  } catch (error) {
    console.error("❌ Migration failed:", error);
    res.status(500).json({success: false, error: String(error)});
  }
});

/**
 * 5. Send reminder 1 hour before appointment
 *    Runs every 15 minutes to catch upcoming visits
 */
export const sendAppointmentReminder = functions.pubsub
  .schedule("every 15 minutes")
  .onRun(async () => {
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000); // +1 hour

    const dateString = formatDate(oneHourFromNow);
    const timeString = formatTime(oneHourFromNow);

    const querySnapshot = await db.collection("appointments")
      .where("date", "==", dateString)
      .where("heure", "==", timeString)
      .where("etat", "==", "confirmed")
      .get();

    if (querySnapshot.empty) {
      console.log("📭 No upcoming appointments to remind");
      return;
    }

    querySnapshot.forEach(async (doc) => {
      const apt = doc.data();
      const patientId = apt.idpat;
      const doctorId = apt.idpro;

      // 🔔 Notify Patient
      await db.collection("notifications").add({
        destinataire: patientId,
        message: `⏰ Rappel : Vous avez un rendez-vous aujourd'hui à ${timeString}. Ne soyez pas en retard !`,
        type: "reminder",
        datetime: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        senderId: doctorId,
      });

      // 🔔 Notify Doctor
      await db.collection("notifications").add({
        destinataire: doctorId,
        message: `⏰ Rappel : Vous avez une consultation prévue à ${timeString}.`,
        type: "reminder",
        datetime: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        senderId: patientId,
      });
    });

    console.log(`✅ Sent ${querySnapshot.size} reminders`);
  });

/**
 * 6. Manual cleanup of EXPIRED provider_requests only (safe cleanup)
 *    Call this to clean up old documents without expireAt field
 *    New documents with expireAt will be preserved if not expired yet
 */
export const manualCleanupProviderRequests = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated (optional - remove if you want public access)
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  console.log("🧹 Manual cleanup triggered by user:", context.auth.uid);

  try {
    const now = admin.firestore.Timestamp.now();

    // Get ALL documents
    const allDocs = await db.collection("provider_requests").get();

    if (allDocs.empty) {
      console.log("✅ No provider_requests to clean");
      return {success: true, deleted: 0, message: "Collection already empty"};
    }

    console.log(`📊 Found ${allDocs.size} total documents`);

    // Filter: Delete if (1) no expireAt field OR (2) expireAt is expired
    const docsToDelete: FirebaseFirestore.DocumentSnapshot[] = [];

    allDocs.docs.forEach((doc) => {
      const data = doc.data();
      const expireAt = data.expireAt;

      // Delete if: no expireAt (old document) OR expireAt is in the past
      if (!expireAt || expireAt <= now) {
        docsToDelete.push(doc);
      }
    });

    if (docsToDelete.length === 0) {
      console.log("✅ No expired documents to delete");
      return {
        success: true,
        deleted: 0,
        message: "No expired documents found",
      };
    }

    console.log(`🗑️ Deleting ${docsToDelete.length} expired documents...`);

    // Delete in batches of 500 (Firestore limit)
    const batchSize = 500;
    let deleted = 0;

    for (let i = 0; i < docsToDelete.length; i += batchSize) {
      const batch = db.batch();
      const batchDocs = docsToDelete.slice(i, i + batchSize);

      batchDocs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      deleted += batchDocs.length;
      console.log(`✅ Deleted ${deleted}/${docsToDelete.length} expired documents...`);
    }

    const preserved = allDocs.size - deleted;
    console.log(`🎉 Cleanup complete! Deleted ${deleted}, Preserved ${preserved} active documents`);

    return {
      success: true,
      deleted: deleted,
      preserved: preserved,
      message: `Deleted ${deleted} expired documents, preserved ${preserved} active ones`,
    };
  } catch (error: unknown) {
    console.error("❌ Error during manual cleanup:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    throw new functions.https.HttpsError(
      "internal",
      `Cleanup failed: ${errorMessage}`,
    );
  }
});

/**
 * 7. When a user deletes their account → clean up related data
 *    Trigger this manually or via Auth onDelete trigger
 */
export const cleanupUserData = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const uid = context.auth.uid;

  const batch = db.batch();

  // Delete from collections
  batch.delete(db.collection("patients").doc(uid));
  batch.delete(db.collection("professionnels").doc(uid));
  batch.delete(db.collection("users").doc(uid));

  // Mark their appointments as cancelled
  const appointmentSnapshot = await db.collection("appointments")
    .where("idpat", "==", uid)
    .get();

  appointmentSnapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {etat: "cancelled", cancelledBy: "system"});
  });

  // Commit all changes
  await batch.commit();
  console.log(`🧹 Cleaned up data for user ${uid}`);

  return {success: true, cleaned: uid};
});

/**
 * 8. Sign up new users (patients only)
 */
export const signUpUser = functions.https.onCall(async (data) => {
  const {email, password, nom, prenom, telephone} = data;

  // Validate input
  if (!email || !password || !nom || !prenom) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email, password, nom and prenom are required",
    );
  }

  try {
    // Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: `${prenom} ${nom}`,
    });

    // Create user document in Firestore
    await db.collection("users").doc(userRecord.uid).set({
      email: email,
      nom: nom,
      prenom: prenom,
      telephone: telephone || "",
      role: "patient", // Only patients can register
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ User ${userRecord.uid} created successfully`);

    return {
      success: true,
      userId: userRecord.uid,
      message: "Patient account created successfully",
    };
  } catch (error: unknown) {
    console.error("❌ Error creating user:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    throw new functions.https.HttpsError(
      "internal",
      `Failed to create user: ${errorMessage}`,
    );
  }
});

/**
 * 9. Sign in users (all roles)
 */
export const signInUser = functions.https.onCall(async (data) => {
  const {email, password} = data;

  if (!email || !password) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email and password are required",
    );
  }

  try {
    // Get user by email
    const userRecord = await admin.auth().getUserByEmail(email);

    // Get user role from Firestore
    const userDoc = await db.collection("users").doc(userRecord.uid).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "User profile not found",
      );
    }

    const userData = userDoc.data();

    // Create custom token for the user
    const customToken = await admin.auth().createCustomToken(userRecord.uid, {
      role: userData?.role,
      email: userData?.email,
    });

    console.log(`✅ User ${userRecord.uid} signed in successfully`);

    return {
      success: true,
      customToken: customToken,
      user: {
        uid: userRecord.uid,
        email: userData?.email,
        role: userData?.role,
        nom: userData?.nom,
        prenom: userData?.prenom,
      },
    };
  } catch (error: unknown) {
    console.error("❌ Error signing in:", error);

    const errorObj = error as {code?: string; message?: string};
    if (errorObj.code === "auth/user-not-found") {
      throw new functions.https.HttpsError(
        "not-found",
        "No user found with this email",
      );
    }

    const errorMessage = errorObj.message || "Unknown error";
    throw new functions.https.HttpsError(
      "internal",
      `Sign in failed: ${errorMessage}`,
    );
  }
});

/**
 * 10. Get user role and profile data
 */
export const getUserRole = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const uid = context.auth.uid;

  try {
    const userDoc = await db.collection("users").doc(uid).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "User profile not found"
      );
    }

    const userData = userDoc.data();

    return {
      success: true,
      user: {
        uid: uid,
        email: userData?.email,
        role: userData?.role,
        nom: userData?.nom,
        prenom: userData?.prenom,
      },
    };
  } catch (error: unknown) {
    console.error("❌ Error getting user role:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    throw new functions.https.HttpsError(
      "internal",
      `Failed to get user data: ${errorMessage}`,
    );
  }
});

// Helper: Format Date as "YYYY-MM-DD"
function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

// Helper: Format Time as "HH:MM"
function formatTime(date: Date): string {
  const hours = String(date.getHours()).padStart(2, "0");
  const mins = String(date.getMinutes()).padStart(2, "0");
  return `${hours}:${mins}`;
}


