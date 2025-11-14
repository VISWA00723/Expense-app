# Netlify Deployment Checklist

## ✅ Backend Setup Complete

### Files Ready:
- ✅ `netlify.toml` - Netlify configuration
- ✅ `functions/server.js` - Netlify Functions handler
- ✅ `package.json` - Dependencies with serverless-http
- ✅ `.env` - Environment variables (local only)

### Next Steps:

## 1. Push to GitHub

```bash
cd d:\exp\backend
git init
git add .
git commit -m "Backend ready for Netlify deployment"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/expense-tracker-backend.git
git push -u origin main
```

## 2. Deploy on Netlify

### Option A: Netlify Dashboard
1. Go to https://netlify.com
2. Click "New site from Git"
3. Connect GitHub account
4. Select `expense-tracker-backend` repository
5. Build settings:
   - Build command: `npm install`
   - Publish directory: `.`
6. Click "Deploy site"

### Option B: Netlify CLI
```bash
npm install -g netlify-cli
netlify login
netlify deploy --prod
```

## 3. Add Environment Variables

1. Go to Netlify dashboard
2. Select your site
3. Site settings → Build & deploy → Environment
4. Add new variable:
   - Key: `OPENROUTER_API_KEY`
   - Value: Your OpenRouter API key
5. Trigger redeploy

## 4. Test Backend

### Test health endpoint:
```bash
curl https://expense-tacker-backend.netlify.app/health
```

Expected response:
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
      {"title": "Lunch", "amount": 500, "category": "Food", "date": "2024-01-01", "notes": ""}
    ]
  }'
```

## 5. Verify Flutter App

The app is already configured to use:
```
https://expense-tacker-backend.netlify.app
```

### Test in app:
1. Run: `flutter run`
2. Add some expenses
3. Go to AI Assistant tab
4. Ask: "How much did I spend?"
5. Should get AI response from Netlify backend

## Troubleshooting

### Backend not responding:
- Check Netlify deployment logs
- Verify OPENROUTER_API_KEY is set
- Check Functions logs in Netlify dashboard

### CORS errors:
- CORS is enabled in server.js
- Should work automatically

### Timeout errors:
- Netlify free tier: 10 second timeout
- Upgrade to Pro if needed

### 404 errors:
- Verify endpoint: `/analyze` or `/health`
- Check request format

## Monitoring

- Netlify dashboard shows:
  - Deployment status
  - Function invocations
  - Error rates
  - Response times

## Cost

- Netlify free tier: 125,000 function invocations/month
- Plenty for development and testing

---

**Status**: Ready to deploy
**Backend URL**: `https://expense-tacker-backend.netlify.app`
**Estimated deployment time**: 2-3 minutes
