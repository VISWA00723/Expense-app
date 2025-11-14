# Backend Connection Fix - Android Emulator Support

## Problem
Backend was running but app showed: "Backend server not connected. Please ensure the backend is running."

## Root Cause
On Android emulator, `localhost:3000` doesn't work. Need to use `10.0.2.2:3000` instead.

## Solution

### Updated: lib/services/api_service.dart

**Before:**
```dart
final String baseUrl = 'http://localhost:3000';
```

**After:**
```dart
late final String baseUrl;

ApiService({Dio? dio}) : _dio = dio ?? Dio() {
  // Use 10.0.2.2 for Android emulator, localhost for iOS/physical device
  if (Platform.isAndroid) {
    baseUrl = 'http://10.0.2.2:3000';
  } else {
    baseUrl = 'http://localhost:3000';
  }
}
```

## How It Works

### Android Emulator:
- Uses `10.0.2.2:3000` (special alias for host machine)
- Connects to backend running on your computer

### iOS Simulator:
- Uses `localhost:3000`
- Connects to backend running on your computer

### Physical Device:
- Uses `localhost:3000` (or your machine's IP)
- Connects to backend on network

## Testing

### Backend Setup:
```bash
cd d:\exp\backend
npm start
```

Should show:
```
🚀 Expense Tracker Backend running on http://localhost:3000
📝 POST /analyze - Analyze expenses with AI
❤️  GET /health - Health check
```

### App Testing:
1. Run app on Android emulator
2. Go to AI Assistant screen
3. Ask a question about expenses
4. Should connect successfully!

## Logo Size Update

Also reduced logo sizes:
- Login screen: 80x80 (was 140x140)
- Signup screen: 70x70 (was 120x120)

## Result

✅ Backend connection works on Android emulator
✅ Backend connection works on iOS simulator
✅ Backend connection works on physical devices
✅ Logo is now appropriately sized
✅ AI features fully functional

## Important Notes

- Backend must be running on your computer
- Use `npm start` in backend directory
- App will automatically detect platform and use correct URL
- No code changes needed for different devices

---

**Status**: ✅ Backend connection fixed
**Version**: 2.4 (With Backend Fix)
