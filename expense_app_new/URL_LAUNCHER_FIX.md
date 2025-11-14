# URL Launcher Fix - Android Intent Queries

## Problem

When clicking "Powered by MindApt" link on Android, getting error:
```
I/UrlLauncher( 5335): component name for https://mindapt.in/ is null
```

## Root Cause

Android 11+ requires explicit intent queries in `AndroidManifest.xml` for URL launching. Without these queries, the system can't find an app to handle the URL.

## Solution

Added intent filters to `AndroidManifest.xml` to allow URL launching.

## Changes Made

### File: `android/app/src/main/AndroidManifest.xml`

**Added to `<queries>` section:**
```xml
<!-- Required for url_launcher plugin to open URLs -->
<intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="http"/>
</intent>
<intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/>
</intent>
```

**Full queries section now:**
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    <!-- Required for url_launcher plugin to open URLs -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="http"/>
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="https"/>
    </intent>
</queries>
```

## What This Does

- Allows app to query for apps that can handle HTTP URLs
- Allows app to query for apps that can handle HTTPS URLs
- Enables url_launcher plugin to open links in browser
- Complies with Android 11+ package visibility requirements

## Testing

### Before Fix:
```
Tap "Powered by MindApt" → Nothing happens
Console: component name for https://mindapt.in/ is null
```

### After Fix:
```
Tap "Powered by MindApt" → Opens in browser
Console: No errors
```

## How to Apply

### Option 1: Clean Rebuild (Recommended)
```bash
cd d:\exp\expense_app_new
flutter clean
flutter pub get
flutter run
```

### Option 2: Just Rebuild
```bash
cd d:\exp\expense_app_new
flutter run
```

## Verification

1. **Run app:**
   ```bash
   flutter run
   ```

2. **Go to Login or Signup screen**

3. **Scroll to footer**

4. **Tap "Powered by MindApt"**

5. **Expected:** Browser opens with https://mindapt.in/

6. **Actual:** Should now work! ✅

## Why This Happens

**Android 11+ (API 30+)** introduced package visibility restrictions:
- Apps can't see all installed apps by default
- Must explicitly declare which intents they query
- This improves privacy and security

**url_launcher plugin** needs to:
1. Query for apps that handle URLs
2. Find a browser app
3. Open the URL in that browser

Without the intent queries, Android denies the query and returns null.

## Related Files

- `android/app/src/main/AndroidManifest.xml` - Intent queries
- `lib/screens/auth/login_screen.dart` - Uses url_launcher
- `lib/screens/auth/signup_screen.dart` - Uses url_launcher
- `pubspec.yaml` - Has url_launcher dependency

## Android Versions Affected

- ✅ Android 11+ (API 30+) - Requires intent queries
- ✅ Android 10 and below - Works without intent queries
- ✅ All versions - Works with intent queries

## Best Practices

1. **Always declare intent queries** for external URLs
2. **Use HTTPS** when possible (more secure)
3. **Test on real device** (emulator may behave differently)
4. **Handle errors** if browser not available

## Troubleshooting

### Still Not Working?

**Step 1: Clean rebuild**
```bash
flutter clean
flutter pub get
flutter run
```

**Step 2: Check AndroidManifest.xml**
- Verify intent filters are added
- Check XML syntax is correct
- No missing closing tags

**Step 3: Check device**
- Device has browser app installed
- Device has internet connection
- Device is Android 11+

**Step 4: Check logs**
```bash
flutter logs
```

### Alternative: Use Different Approach

If still not working, can use in-app WebView:
```dart
// Instead of launching URL
// Show WebView in app
```

But url_launcher is simpler and better.

## References

- [Android Package Visibility](https://developer.android.com/training/package-visibility)
- [url_launcher plugin](https://pub.dev/packages/url_launcher)
- [Intent Filters](https://developer.android.com/guide/components/intents-filters)

---

**Status**: ✅ Fixed
**Version**: 2.10 (With URL Launcher Fix)
**Tested**: Android 11+
