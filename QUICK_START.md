# 🚀 Quick Start Guide

Get the Expense Tracker app running in 5 minutes.

## Prerequisites
- Flutter SDK installed
- Node.js 16+ installed
- OpenRouter API key (free at https://openrouter.ai)

---

## Step 1: Backend Setup (2 minutes)

```bash
cd backend
npm install
```

Create `.env` file:
```
OPENROUTER_API_KEY=your_key_here
PORT=3000
```

Start backend:
```bash
npm start
```

✅ You should see: `🚀 Expense Tracker Backend running on http://localhost:3000`

---

## Step 2: Flutter Setup (2 minutes)

```bash
cd expense_tracker
flutter pub get
flutter pub run build_runner build
```

---

## Step 3: Run App (1 minute)

```bash
flutter run
```

Choose your device:
- Android emulator
- iOS simulator
- Physical device

---

## Step 4: Test It

1. **Add Expense**
   - Click FAB button (+)
   - Fill in details
   - Click Save

2. **View Dashboard**
   - See total spending
   - See category breakdown
   - See recent expenses

3. **Ask AI**
   - Go to AI tab
   - Type: "How much did I spend?"
   - See AI response

---

## Troubleshooting

### Backend won't start
```bash
# Check if port 3000 is in use
lsof -i :3000

# Kill process if needed
kill -9 <PID>

# Restart
npm start
```

### Flutter build fails
```bash
flutter clean
flutter pub get
flutter pub run build_runner build
flutter run
```

### AI not responding
- Check backend is running
- Verify OpenRouter API key in `.env`
- Check internet connection

---

## Next Steps

- Read [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed setup
- Read [TESTING_GUIDE.md](./TESTING_GUIDE.md) for testing
- Read [API_TESTING.md](./API_TESTING.md) for API details

---

## Project Structure

```
expense_tracker/          # Flutter app
├── lib/
│   ├── main.dart
│   ├── database/
│   ├── models/
│   ├── services/
│   ├── providers/
│   └── screens/
└── pubspec.yaml

backend/                  # Node.js backend
├── server.js
├── package.json
└── .env
```

---

## Features

✅ Add/Edit/Delete expenses
✅ Local SQLite database
✅ Category breakdown charts
✅ AI-powered financial insights
✅ Filter by month/category
✅ Clean Material 3 UI

---

## Support

- Backend issues? Check `npm start` output
- Flutter issues? Check `flutter run -v` output
- API issues? See [API_TESTING.md](./API_TESTING.md)

---

**Happy tracking! 💰**
