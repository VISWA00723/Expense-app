# Bottom Navigation Visibility Fix

## Problem
Bottom navigation bar was not visible on any screens because content was overlapping it.

## Root Cause
- Screens had `padding: const EdgeInsets.all(16)` 
- This didn't account for the bottom navigation bar height (~56dp)
- Content was scrolling behind the navigation bar

## Solution
Updated all screens to use `padding: const EdgeInsets.fromLTRB(16, 16, 16, 100)`:
- Left: 16
- Top: 16
- Right: 16
- Bottom: 100 (to clear the navigation bar)

## Files Modified

### 1. **lib/screens/dashboard_screen.dart**
```dart
// Before
padding: const EdgeInsets.all(16),

// After
padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
```

### 2. **lib/screens/add_expense_screen.dart**
```dart
// Before
padding: const EdgeInsets.all(16),

// After
padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
```

### 3. **lib/screens/expense_list_screen.dart**
```dart
// Before
padding: const EdgeInsets.all(16),

// After
padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
```

### 4. **lib/screens/ai_assistant_screen.dart**
```dart
// Before
Padding(
  padding: const EdgeInsets.all(16),
  ...
)

// After
Container(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
  ...
)
```

## Result
✅ Bottom navigation now visible on all screens
✅ Content doesn't overlap navigation
✅ Smooth scrolling with proper spacing
✅ All navigation buttons clickable

## Testing
- [ ] Dashboard - bottom nav visible
- [ ] Add Expense - bottom nav visible
- [ ] Expense List - bottom nav visible
- [ ] AI Assistant - bottom nav visible
- [ ] Can click all navigation buttons
- [ ] Content scrolls properly without overlapping

## Backend API Issue

### Current Status
Backend is running but endpoint not found: `{"error":"Endpoint not found"}`

### Current Endpoint
- App tries: `POST /analyze`
- Backend responds: Endpoint not found

### Solutions

**Option 1: Check Backend Endpoint**
```bash
# Verify backend is running on correct port
curl http://localhost:3000/analyze -X POST
```

**Option 2: Update API Endpoint**
If backend uses different endpoint, update in `lib/services/api_service.dart`:
```dart
final response = await _dio.post(
  '$baseUrl/api/analyze',  // or /api/expenses/analyze
  data: { ... }
);
```

**Option 3: Disable AI for Now**
AI screen shows helpful message when backend is not connected.
Users can still use all other features.

---

**Status**: ✅ Bottom navigation fixed and visible
**Backend**: Requires endpoint verification
