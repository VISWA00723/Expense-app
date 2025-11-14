# AI Not Working on Mobile - Troubleshooting Guide

## Problem

AI works in test environment but fails after installing on mobile device.

## Root Causes

### 1. **Backend Not Deployed** ❌
- Netlify backend not deployed
- Backend URL incorrect
- Backend not running

### 2. **Network Issues** ❌
- Mobile can't reach Netlify
- Firewall blocking requests
- DNS resolution issues

### 3. **CORS Issues** ❌
- CORS not properly configured
- Browser/app blocking cross-origin requests

### 4. **Environment Variables** ❌
- OPENROUTER_API_KEY not set on Netlify
- Missing configuration

### 5. **URL Issues** ❌
- Wrong backend URL in app
- Typo in domain name

## Solutions

### Solution 1: Verify Backend Deployment

**Step 1: Check Netlify Status**
```bash
# Visit in browser
https://expense-tacker-backend.netlify.app/health
```

**Expected Response:**
```json
{"status": "OK"}
```

**If Error:**
- Go to Netlify dashboard
- Check deployment status
- Check build logs
- Redeploy if needed

### Solution 2: Check Environment Variables

**On Netlify Dashboard:**
1. Go to Site Settings
2. Go to Build & Deploy → Environment
3. Verify `OPENROUTER_API_KEY` is set
4. Value should be your OpenRouter API key

**If Missing:**
1. Add new variable
2. Name: `OPENROUTER_API_KEY`
3. Value: Your actual API key
4. Redeploy

### Solution 3: Test Backend Directly

**From Mobile Browser:**
```
1. Open browser on mobile
2. Visit: https://expense-tacker-backend.netlify.app/health
3. Should see: {"status": "OK"}
```

**If Works:**
- Backend is accessible
- Problem is in app code

**If Fails:**
- Backend not deployed
- URL is wrong
- Network issue

### Solution 4: Test with curl (from computer)

```bash
# Test health endpoint
curl https://expense-tacker-backend.netlify.app/health

# Test analyze endpoint
curl -X POST https://expense-tacker-backend.netlify.app/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend?",
    "expenses": [
      {
        "title": "Food",
        "amount": 500,
        "category": "Food",
        "date": "2025-01-01",
        "notes": "Lunch"
      }
    ]
  }'
```

### Solution 5: Check Mobile Network

**On Mobile Device:**
1. Open Settings
2. Check WiFi connection
3. Try switching to mobile data
4. Check if other apps can access internet
5. Try accessing google.com to verify internet

### Solution 6: Update API Service (if needed)

**File:** `lib/services/api_service.dart`

**Current:**
```dart
baseUrl = 'https://expense-tacker-backend.netlify.app';
```

**Verify:**
- No typos in URL
- Correct domain name
- HTTPS (not HTTP)

### Solution 7: Add Debug Logging

**Update API Service:**
```dart
Future<AIResponse> analyzeExpenses({
  required String question,
  required List<ExpenseModel> expenses,
}) async {
  try {
    print('🔍 API Request:');
    print('URL: $baseUrl/analyze');
    print('Question: $question');
    print('Expenses: ${expenses.length}');
    
    final response = await _dio.post(
      '$baseUrl/analyze',
      data: {
        'question': question,
        'expenses': expenses.map((e) => e.toJson()).toList(),
      },
    );

    print('✅ API Response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      return AIResponse.fromJson(response.data);
    } else {
      throw Exception('Failed: ${response.statusCode}');
    }
  } on DioException catch (e) {
    print('❌ API Error: ${e.message}');
    print('Error Type: ${e.type}');
    print('Response: ${e.response?.data}');
    throw Exception('API Error: ${e.message}');
  }
}
```

## Checklist

### Backend Setup
- [ ] Backend deployed to Netlify
- [ ] Deployment successful (no errors)
- [ ] Health endpoint returns OK
- [ ] OPENROUTER_API_KEY set on Netlify
- [ ] API key is valid

### Mobile Testing
- [ ] Mobile has internet connection
- [ ] Can access google.com on mobile
- [ ] Can access backend health endpoint from mobile browser
- [ ] App has internet permission in AndroidManifest.xml

### App Configuration
- [ ] Backend URL correct in api_service.dart
- [ ] No typos in URL
- [ ] Using HTTPS (not HTTP)
- [ ] CORS enabled on backend

### Network
- [ ] Mobile WiFi working
- [ ] Mobile data working
- [ ] No firewall blocking requests
- [ ] DNS resolving correctly

## Common Issues & Fixes

### Issue: "Connection refused"
**Cause:** Backend not running
**Fix:** Deploy backend to Netlify

### Issue: "Failed host lookup"
**Cause:** DNS not resolving
**Fix:** Check URL spelling, try mobile data

### Issue: "Connection timed out"
**Cause:** Backend not responding
**Fix:** Check Netlify deployment, check API key

### Issue: "CORS error"
**Cause:** CORS not configured
**Fix:** Verify cors() middleware in server.js

### Issue: "401 Unauthorized"
**Cause:** Invalid API key
**Fix:** Update OPENROUTER_API_KEY on Netlify

### Issue: "500 Internal Server Error"
**Cause:** Backend error
**Fix:** Check Netlify logs, check API key

## Testing Steps

### Step 1: Test Backend Health
```
Mobile Browser → https://expense-tacker-backend.netlify.app/health
Expected: {"status": "OK"}
```

### Step 2: Test from App
```
1. Open app on mobile
2. Go to AI Assistant
3. Ask a question
4. Check console logs for errors
```

### Step 3: Check Netlify Logs
```
1. Go to Netlify dashboard
2. Go to Functions
3. Check server function logs
4. Look for errors
```

### Step 4: Test with Different Question
```
1. Try simple question: "How much did I spend?"
2. Try general question: "What's a good budget?"
3. Check if any work
```

## If Still Not Working

### Option 1: Use Local Backend (for testing)
```dart
// Uncomment in api_service.dart
if (Platform.isAndroid) {
  baseUrl = 'http://10.0.2.2:3000';
} else {
  baseUrl = 'http://localhost:3000';
}
```

Then run backend locally:
```bash
cd d:\exp\backend
npm install
npm start
```

### Option 2: Check Netlify Deployment
```bash
# Redeploy backend
cd d:\exp\backend
git add .
git commit -m "Redeploy backend"
git push origin main
```

### Option 3: Verify API Key
1. Get OpenRouter API key from https://openrouter.ai/
2. Go to Netlify dashboard
3. Update OPENROUTER_API_KEY
4. Redeploy

## Quick Checklist for Mobile Testing

```
□ Backend deployed to Netlify
□ Health endpoint working
□ OPENROUTER_API_KEY set
□ Mobile has internet
□ App has internet permission
□ Backend URL correct in app
□ No typos in URL
□ Using HTTPS
□ CORS enabled
□ Try different questions
□ Check console logs
□ Check Netlify logs
```

## Support

If still not working:
1. Check console logs in app
2. Check Netlify function logs
3. Test backend URL in browser
4. Verify API key is valid
5. Try local backend for testing

---

**Status**: Troubleshooting Guide
**Last Updated**: Nov 14, 2025
