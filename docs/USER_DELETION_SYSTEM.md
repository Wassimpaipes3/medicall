# User Deletion System Documentation

## Overview

This documentation covers the complete user deletion system implemented for the MediCall healthcare application. The system provides three different deletion scenarios with automatic cleanup of all related data across Firebase Authentication and Firestore collections.

## Architecture

### 1. Flutter Client-Side Deletion
**File**: `lib/services/auth_service.dart`
- Method: `deleteUserAccount({String? password})`
- Handles user-initiated account deletion from the app

### 2. Firebase Auth Deletion Trigger
**File**: `functions/src/index.ts`
- Function: `onAuthUserDeleted`
- Triggers when Firebase Auth user is deleted (e.g., from Firebase Console)

### 3. Firestore Document Deletion Trigger
**File**: `functions/src/index.ts`
- Function: `onUserDocumentDeleted`
- Triggers when user document is manually deleted from Firestore Console

## Data Cleanup Scope

### Collections Affected
1. **users/{uid}** - Main user profile
2. **patients/{uid}** - Patient medical information
3. **professionals/{uid}** - Healthcare professional details
4. **appointments/** - User's appointments (as patient or professional)
5. **avis/** - User's reviews and ratings
6. **disponibilites/** - Professional's availability slots
7. **notifications/** - User's notifications

### Firebase Authentication
- Complete user account removal from Firebase Auth
- Invalidates all user sessions and tokens

## Implementation Details

### Client-Side Deletion (`AuthService.deleteUserAccount`)

```dart
// Basic usage
final result = await authService.deleteUserAccount();

// With password confirmation (recommended for security)
final result = await authService.deleteUserAccount(password: userPassword);
```

**Process Flow:**
1. **Validation**: Check if user is authenticated
2. **Re-authentication**: Verify password (if provided)
3. **Firestore Cleanup**: Delete all user-related documents
4. **Auth Deletion**: Remove Firebase Authentication account

**Security Features:**
- Password re-authentication for sensitive operations
- Graceful error handling for partial failures
- Comprehensive logging for debugging

**Response Format:**
```dart
{
  'success': true|false,
  'message': 'User-friendly message',
  'error': 'error-code', // Only present if success is false
}
```

### Cloud Functions

#### Auth Deletion Trigger (`onAuthUserDeleted`)
```typescript
// Automatically triggered when Firebase Auth user is deleted
export const onAuthUserDeleted = functions.auth.user().onDelete(...)
```

**Triggers when:**
- Admin deletes user from Firebase Console
- User is deleted via Admin SDK
- Third-party deletion tools are used

#### Document Deletion Trigger (`onUserDocumentDeleted`)
```typescript
// Automatically triggered when user document is deleted
export const onUserDocumentDeleted = functions.firestore.document("users/{userId}").onDelete(...)
```

**Triggers when:**
- Admin deletes user document from Firestore Console
- Batch operations remove user documents
- Direct database manipulation occurs

## User Interface

### Delete Account Screen
**File**: `lib/screens/settings/delete_account_screen.dart`

**Features:**
- ⚠️ Clear warning messages
- 📋 List of data that will be deleted
- 🔐 Password confirmation field
- ✅ Confirmation checkbox
- 🚫 Multiple confirmation dialogs

### Settings Integration
**File**: `lib/screens/settings/settings_screen.dart`

**Features:**
- 🔴 Danger zone section
- 🎨 Visual warning indicators
- 📱 Easy navigation to deletion screen

## Usage Examples

### 1. User Self-Deletion (Recommended Flow)

```dart
// In your UI component
Future<void> _handleDeleteAccount() async {
  // Get password from user
  final password = await _showPasswordDialog();
  
  if (password != null) {
    // Show loading
    setState(() => _isLoading = true);
    
    // Delete account
    final result = await _authService.deleteUserAccount(password: password);
    
    if (result['success']) {
      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
    
    setState(() => _isLoading = false);
  }
}
```

### 2. Admin Panel Integration

```dart
// For admin operations (requires appropriate permissions)
Future<void> deleteUserAsAdmin(String uid) async {
  try {
    // Delete via Admin SDK (will trigger Cloud Function)
    await FirebaseAuth.instance.currentUser?.delete();
    
    // Or delete Firestore document directly (will trigger cleanup)
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    
    print('User deleted successfully');
  } catch (e) {
    print('Error deleting user: $e');
  }
}
```

## Error Handling

### Common Error Codes

| Code | Description | User Message |
|------|-------------|--------------|
| `no-user` | No authenticated user | "Aucun utilisateur connecté trouvé" |
| `wrong-password` | Invalid password | "Mot de passe incorrect" |
| `requires-recent-login` | Re-authentication required | "Veuillez vous reconnecter avant de supprimer" |
| `network-request-failed` | Network connectivity issues | "Vérifiez votre connexion internet" |
| `user-not-found` | User doesn't exist | "Utilisateur introuvable" |

### Error Recovery Strategies

1. **Partial Firestore Cleanup Failure:**
   - Continue with Auth deletion
   - Log detailed error information
   - Cloud Functions will handle remaining cleanup

2. **Network Connectivity Issues:**
   - Retry mechanism for critical operations
   - Graceful degradation of non-essential features
   - Clear user communication about retry options

3. **Re-authentication Required:**
   - Redirect to login screen
   - Preserve deletion intent for post-login completion
   - Clear security messaging about why re-auth is needed

## Security Considerations

### Data Protection
- **Password Verification**: Required for user-initiated deletions
- **Session Invalidation**: All user sessions terminated immediately
- **Audit Logging**: Comprehensive logs for compliance and debugging

### Privacy Compliance
- **GDPR Right to be Forgotten**: Complete data erasure
- **HIPAA Compliance**: Secure deletion of medical information
- **Data Retention**: No backup copies remain after deletion

### Access Control
- **User Self-Service**: Users can only delete their own accounts
- **Admin Oversight**: Admin deletions trigger same cleanup process
- **Function Security**: Cloud Functions use Firebase Admin SDK with proper IAM

## Testing

### Unit Tests
**File**: `test/services/auth_service_deletion_test.dart`

Run tests:
```bash
flutter test test/services/auth_service_deletion_test.dart
```

### Integration Tests

1. **User Flow Testing:**
   - Complete signup → deletion flow
   - Verify all data is removed
   - Check auth state after deletion

2. **Cloud Function Testing:**
   - Test Auth deletion trigger
   - Test Firestore deletion trigger
   - Verify cleanup completion

### Manual Testing Checklist

- [ ] User can access deletion screen from settings
- [ ] Password confirmation works correctly
- [ ] All confirmation dialogs appear
- [ ] Deletion completes successfully
- [ ] User is redirected to login screen
- [ ] All Firestore documents are removed
- [ ] Firebase Auth account is deleted
- [ ] Related appointments are cleaned up
- [ ] Notifications are removed
- [ ] Professional availability slots deleted (if applicable)

## Deployment

### Cloud Functions Deployment
```bash
cd functions
firebase deploy --only functions
```

### Required Firebase APIs
- Cloud Functions API
- Firestore API
- Firebase Authentication API
- Cloud Build API (for functions deployment)

### Environment Setup
1. Ensure Firebase project is initialized
2. Enable required APIs in Google Cloud Console
3. Configure proper IAM roles for Cloud Functions
4. Test in development environment before production

## Monitoring and Maintenance

### Logging and Monitoring
- **Cloud Function Logs**: Available in Firebase Console
- **Error Tracking**: Integrated with Firebase Crashlytics
- **Performance Monitoring**: Track deletion completion times

### Regular Maintenance Tasks
1. **Log Review**: Weekly review of deletion logs
2. **Performance Monitoring**: Track function execution times
3. **Error Analysis**: Investigate and resolve recurring issues
4. **Security Audits**: Regular review of access patterns

### Troubleshooting Guide

**Problem**: Deletion takes too long
**Solution**: Check Firestore query performance, consider pagination for large datasets

**Problem**: Partial cleanup occurs
**Solution**: Review Cloud Function logs, implement retry mechanism for failed operations

**Problem**: User remains in Firebase Auth after deletion
**Solution**: Verify Cloud Function permissions, check Admin SDK configuration

## Future Enhancements

### Potential Improvements
1. **Batch Deletion**: Support for deleting multiple users
2. **Soft Delete**: Temporary deactivation before permanent deletion
3. **Data Export**: Allow users to export their data before deletion
4. **Deletion Scheduling**: Schedule deletions for specific times
5. **Audit Trail**: Enhanced logging for compliance requirements

### Scalability Considerations
- **Large Dataset Handling**: Implement pagination for users with extensive data
- **Rate Limiting**: Prevent abuse of deletion endpoints
- **Background Processing**: Move heavy cleanup operations to background jobs