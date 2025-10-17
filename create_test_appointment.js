// Quick debug script to check appointment data
// Run in Firebase Console or create a simple test

// Sample appointment request for testing
const testAppointmentRequest = {
    // Test with a known provider ID - check your Firebase Auth users
    idpro: "REPLACE_WITH_REAL_PROVIDER_ID", // Get this from Firebase Auth
    idpat: "REPLACE_WITH_REAL_PATIENT_ID", // Get this from Firebase Auth

    patientName: "John Doe",
    patientPhone: "+1234567890",
    service: "General Consultation",
    prix: 100,
    serviceFee: 0,
    paymentMethod: "Cash",
    type: "scheduled",

    appointmentDate: new Date("2025-10-20"),
    appointmentTime: "14:30",

    patientLocation: null,
    providerLocation: null,
    patientAddress: "123 Test Street",
    notes: "Test appointment",

    status: "pending",
    etat: "en_attente",
    createdAt: new Date(),
    updatedAt: new Date()
};

// To create test data in Firebase console:
// 1. Go to Firestore Database
// 2. Create collection: appointment_requests
// 3. Add document with above data
// 4. Replace the IDs with real user IDs from Authentication tab

console.log("Use this data to create a test appointment request:");
console.log(JSON.stringify(testAppointmentRequest, null, 2));