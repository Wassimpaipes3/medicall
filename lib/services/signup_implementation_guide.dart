/*
=== COMPREHENSIVE PATIENT SIGNUP IMPLEMENTATION ===

This implementation creates TWO Firestore documents when a patient signs up:

1. 📝 users/{uid} - Basic user profile information
2. 🏥 patients/{uid} - Medical-specific patient data

=== EXAMPLE DATA STRUCTURES ===

1. users/0Nqm985CZCdBrnEyY5QCjOELTak1:
{
  "uid": "0Nqm985CZCdBrnEyY5QCjOELTak1",
  "email": "patient@example.com", 
  "name": "Benmessaoud",
  "prenom": "Wassim",
  "fullName": "Wassim Benmessaoud",
  "telephone": "+213123456789",
  "role": "patient",
  "adresse": "123 Rue Constantine, Algérie",
  "dateNaissance": "1990-05-15",
  "genre": "Homme",
  "photoProfilePath": "/path/to/profile/photo.jpg",
  "isActive": true,
  "lastLoginAt": "2025-09-21T22:45:00Z"
}

2. patients/0Nqm985CZCdBrnEyY5QCjOELTak1:
{
  "userId": "0Nqm985CZCdBrnEyY5QCjOELTak1",
  "allergies": "Aucune",
  "antecedents": "Aucun", 
  "dossiers_medicaux": "",
  "groupe_sanguin": "Non renseigné",
  "notifications_non_lues": 0
}

=== SUBCOLLECTIONS CREATED ===

patients/{uid}/appointments/ - Future patient appointments
patients/{uid}/consultations/ - Medical consultation history  
patients/{uid}/prescriptions/ - Prescription history

=== USAGE EXAMPLE ===

```dart
final authService = AuthService();
final result = await authService.signUpPatient(
  email: "patient@example.com",
  password: "securePassword123",
  name: "Benmessaoud", 
  prenom: "Wassim",
  telephone: "+213123456789",
  adresse: "123 Rue Constantine",
  dateNaissance: "1990-05-15",
  genre: "Homme",
  photoProfilePath: "/path/to/photo.jpg",
);

if (result['success']) {
  // Navigate to patient home
  Navigator.pushReplacementNamed(context, '/patient-navigation');
} else {
  // Show error message
  print(result['message']);
}
```

=== ERROR HANDLING ===

The function handles all Firebase Auth errors with French messages:
- email-already-in-use: "Cette adresse email est déjà utilisée..."
- weak-password: "Le mot de passe est trop faible..."
- invalid-email: "Format d'email invalide..."
- network-request-failed: "Erreur de connexion..."

=== VALIDATION ===

Before calling Firebase, the function validates:
✓ Required fields (name, prenom, email, phone)
✓ Email format
✓ Password strength (min 6 chars)
✓ Password confirmation match
✓ Phone format
✓ Terms acceptance

=== NAVIGATION FLOW ===

1. User fills signup form
2. Form validation
3. Firebase Auth account creation
4. users/{uid} document creation
5. patients/{uid} document creation
6. Medical subcollections creation
7. Success message display
8. Navigate to /patientHome

This ensures complete separation of user profile data and medical data
while maintaining referential integrity through the uid field.
*/