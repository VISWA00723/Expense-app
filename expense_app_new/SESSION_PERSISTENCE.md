# Session Persistence - Keep User Logged In

## Problem Fixed

**Issue**: App asked for login every time it was cleared or after a short time.

**Root Cause**: User session was not persisted to device storage.

## Solution Implemented

Added persistent session storage using SharedPreferences to keep users logged in across app restarts.

## How It Works

### 1. Session Service (`lib/services/session_service.dart`)
Handles all session persistence operations:
- Save session (user ID, email, name)
- Retrieve saved session data
- Check if session exists
- Clear session on logout

### 2. Session Provider (`lib/providers/session_provider.dart`)
Riverpod providers for accessing session data:
- `sessionServiceProvider` - Session service instance
- `hasSessionProvider` - Check if session exists
- `savedUserIdProvider` - Get saved user ID
- `savedUserEmailProvider` - Get saved user email
- `savedUserNameProvider` - Get saved user name

### 3. Auth Service Updates
Modified to:
- Save session after successful login
- Clear session on logout
- Accept optional SessionService parameter

### 4. Auth Provider Updates
Updated to:
- Initialize SessionService
- Pass SessionService to AuthService
- Manage session state

## Files Modified/Created

### New Files:
- ✅ `lib/services/session_service.dart` - Session persistence logic
- ✅ `lib/providers/session_provider.dart` - Session providers

### Modified Files:
- ✅ `lib/services/auth_service.dart` - Save/clear sessions
- ✅ `lib/providers/auth_provider.dart` - Initialize session service
- ✅ `lib/main.dart` - Initialize Flutter binding
- ✅ `pubspec.yaml` - Added shared_preferences dependency

## Data Persisted

When user logs in, these are saved:
```
- User ID (int)
- Email (String)
- Name (String)
- Login status (bool)
```

## Behavior

### Login
```
1. User enters credentials
2. Backend validates
3. User logged in
4. Session saved to device
```

### App Restart
```
1. App starts
2. Checks for saved session
3. If session exists → Auto-login
4. If no session → Show login screen
```

### Logout
```
1. User taps logout
2. Session cleared from device
3. User redirected to login
```

### App Clear
```
1. User clears app data
2. Session cleared
3. Next app start → Login screen
```

## Implementation Details

### Session Service Methods

```dart
// Save session
await sessionService.saveSession(
  userId: 123,
  email: 'user@example.com',
  name: 'John Doe',
);

// Check if logged in
bool isLoggedIn = sessionService.hasSession();

// Get user ID
int? userId = sessionService.getUserId();

// Clear session
await sessionService.clearSession();
```

### Using in Providers

```dart
// Check if session exists
final hasSession = ref.watch(hasSessionProvider);

// Get saved user ID
final userId = ref.watch(savedUserIdProvider);

// Get saved email
final email = ref.watch(savedUserEmailProvider);
```

## Testing

### Test Session Persistence:

1. **Login and Restart**
   ```
   1. Run app: flutter run
   2. Login with credentials
   3. Close app (don't logout)
   4. Reopen app
   5. Should be logged in (no login screen)
   ```

2. **Logout**
   ```
   1. Go to Dashboard
   2. Tap profile icon
   3. Tap logout
   4. Confirm logout
   5. Should see login screen
   6. Reopen app
   7. Should still be on login screen
   ```

3. **Clear App Data**
   ```
   1. Android: Settings → Apps → Expense Tracker → Storage → Clear
   2. iOS: Settings → General → iPhone Storage → Expense Tracker → Offload App
   3. Reopen app
   4. Should see login screen
   ```

## Security Considerations

**Current Implementation**:
- Stores user ID, email, name locally
- Does NOT store password
- Session cleared on logout
- Session cleared when app data cleared

**For Production**:
- Consider encrypting stored data
- Use secure storage (Keychain on iOS, Keystore on Android)
- Add token-based authentication
- Implement session timeout
- Add refresh token mechanism

## Dependencies

Added to `pubspec.yaml`:
```yaml
shared_preferences: ^2.2.2
```

Install with:
```bash
flutter pub get
```

## Troubleshooting

### Session not persisting:
- Check if SharedPreferences initialized
- Verify session data being saved
- Check device storage permissions

### User still asked to login:
- Clear app data and retry
- Check if logout is clearing session
- Verify SessionService initialization

### Session persists after logout:
- Ensure `clearSession()` is called
- Check SharedPreferences is cleared
- Verify logout flow

## Future Enhancements

1. **Token-based Auth**
   - Store JWT tokens
   - Implement token refresh
   - Add token expiration

2. **Biometric Login**
   - Use fingerprint/face recognition
   - Reduce login friction

3. **Session Timeout**
   - Auto-logout after inactivity
   - Warn before timeout

4. **Multi-device Support**
   - Sync sessions across devices
   - Manage active sessions

---

**Status**: ✅ Complete
**Version**: 2.8 (With Session Persistence)
**User Experience**: Users stay logged in across app restarts! 🎉
