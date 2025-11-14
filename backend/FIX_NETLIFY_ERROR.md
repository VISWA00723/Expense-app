# Fix: Netlify Function Module Error

## Problem
```
Runtime.ImportModuleError: Error: Cannot find module '/var/task/node_modules/axios/dist/node/axios.cjs'
```

## Root Cause
- Dependencies not being installed on Netlify
- node_modules not included in build
- Build command not correct

## Solution Applied

### 1. Updated `package.json`
- Changed axios to `^1.7.2` (stable version)
- Updated dotenv to `^16.4.5`
- Updated serverless-http to `^3.2.0`
- Added build script: `npm ci`

### 2. Updated `netlify.toml`
```toml
[build]
  command = "npm ci"           # Use npm ci instead of npm install
  functions = "functions"
  publish = "."

[functions]
  node_bundler = "esbuild"     # Use esbuild bundler
  included_files = ["node_modules/**"]  # Include node_modules
```

### 3. Created `.gitignore`
- Ensures node_modules not committed
- Netlify will install fresh

## Steps to Fix

### 1. Update Files Locally
```bash
cd d:\exp\backend
```

Files already updated:
- ✅ `package.json` - Updated dependencies
- ✅ `netlify.toml` - Fixed build config
- ✅ `.gitignore` - Created

### 2. Push Changes to GitHub
```bash
git add .
git commit -m "Fix: Update dependencies and Netlify config"
git push origin main
```

### 3. Redeploy on Netlify
1. Go to Netlify dashboard
2. Select your site
3. Click "Deploys" tab
4. Click "Trigger deploy" → "Deploy site"
5. Wait for build to complete

### 4. Check Logs
1. Go to "Functions" tab
2. Click on "server"
3. Check recent invocations
4. Should see successful responses

## Verification

### Test health endpoint:
```bash
curl https://expense-tacker-backend.netlify.app/health
```

Should return:
```json
{"status":"OK"}
```

### Test analyze endpoint:
```bash
curl -X POST https://expense-tacker-backend.netlify.app/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend?",
    "expenses": [
      {"title": "Lunch", "amount": 500, "category": "Food", "date": "2024-01-01"}
    ]
  }'
```

## Why This Works

1. **npm ci** - Installs exact versions from package-lock.json
2. **esbuild** - Properly bundles Node.js modules
3. **included_files** - Ensures node_modules available at runtime
4. **Stable versions** - Tested versions that work with Netlify

## If Still Not Working

### Option 1: Clear Netlify Cache
1. Netlify dashboard → Site settings
2. Build & deploy → Cache
3. Click "Clear cache and redeploy"

### Option 2: Check Environment Variables
1. Site settings → Build & deploy → Environment
2. Verify `OPENROUTER_API_KEY` is set
3. Redeploy

### Option 3: Use Node.js 18+
1. Site settings → Build & deploy → Environment
2. Add variable: `AWS_LAMBDA_LOG_LEVEL` = `debug`
3. Redeploy and check logs

## Alternative: Use Fetch Instead of Axios

If axios continues to fail, replace with native fetch:

```javascript
// Replace axios.post with:
const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
    'HTTP-Referer': 'https://expense-tacker-backend.netlify.app',
    'X-Title': 'Expense Tracker',
  },
  body: JSON.stringify({
    model: 'gpt-4o-mini',
    messages: [...],
  }),
});
const data = await response.json();
```

---

**Status**: Fixed
**Next step**: Push to GitHub and redeploy
**Expected result**: Backend working on Netlify
