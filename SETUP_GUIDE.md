# Expense Tracker MVP - Setup Guide

## Project Overview

A Flutter mobile expense tracking app with local SQLite storage and AI-powered analysis via OpenRouter API.

**Architecture:**
- **Frontend:** Flutter (iOS + Android)
- **Backend:** Node.js + Express
- **Database:** SQLite (Drift)
- **AI:** OpenRouter (GPT-4o-mini)

---

## Prerequisites

### For Flutter App
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio or Xcode (for emulator/device)
- Minimum iOS 11.0, Android API 21+

### For Backend
- Node.js 16+ and npm
- OpenRouter API key (free tier available)

---

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment

Create `.env` file in the `backend` directory:

```
OPENROUTER_API_KEY=your_openrouter_api_key_here
PORT=3000
NODE_ENV=development
```

**How to get OpenRouter API Key:**
1. Go to https://openrouter.ai
2. Sign up (free)
3. Navigate to API Keys
4. Create a new key
5. Copy and paste into `.env`

### 3. Start Backend Server

```bash
npm start
```

Expected output:
```
🚀 Expense Tracker Backend running on http://localhost:3000
📝 POST /analyze - Analyze expenses with AI
❤️  GET /health - Health check
```

### 4. Test Backend

```bash
# Test health endpoint
curl http://localhost:3000/health

# Test analyze endpoint
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend on food?",
    "expenses": [
      {
        "title": "Coffee",
        "amount": 150,
        "category": "Food",
        "date": "2025-01-10"
      }
    ]
  }'
```

---

## Flutter App Setup

### 1. Navigate to Project

```bash
cd expense_tracker
```

### 2. Get Dependencies

```bash
flutter pub get
```

### 3. Generate Drift Database Code

```bash
flutter pub run build_runner build
```

### 4. Configure Backend URL

Edit `lib/services/api_service.dart` and update the `baseUrl`:

```dart
final String baseUrl = 'http://localhost:3000'; // For emulator/local testing
// For physical device, use your machine's IP:
// final String baseUrl = 'http://192.168.x.x:3000';
```

### 5. Run the App

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

**List available devices:**
```bash
flutter devices
```

---

## App Features

### Dashboard
- Current month's total spending
- Pie chart breakdown by category
- Recent 5 expenses
- FAB to add new expense

### Add Expense
- Title, amount, category, date, notes
- Category dropdown (Food, Transport, Entertainment, Shopping, Bills, Health, Other)
- Date picker

### Expense List
- View all expenses
- Filter by month
- Filter by category
- Delete expenses

### AI Assistant
- Chat interface to ask questions
- Examples:
  - "How much did I spend on food last month?"
  - "What is my highest spending category?"
  - "Show me my spending trends"
- Powered by OpenRouter GPT-4o-mini

---

## API Contract

### POST /analyze

**Request:**
```json
{
  "question": "How much did I spend last month?",
  "expenses": [
    {
      "title": "Coffee",
      "amount": 150,
      "category": "Food",
      "date": "2025-01-10",
      "notes": "Morning coffee"
    }
  ]
}
```

**Response:**
```json
{
  "answer": "You spent ₹150 on Food last month.",
  "summary": {
    "breakdown": {
      "Food": 150
    },
    "totalExpenses": 150,
    "expenseCount": 1
  }
}
```

**Error Response:**
```json
{
  "error": "Invalid request. Required: question (string), expenses (array)"
}
```

---

## Database Schema

### Expenses Table

| Column    | Type      | Description           |
|-----------|-----------|----------------------|
| id        | INTEGER   | Primary key (auto)    |
| title     | TEXT      | Expense title         |
| amount    | REAL      | Amount in rupees      |
| category  | TEXT      | Category name         |
| notes     | TEXT      | Optional notes        |
| date      | TEXT      | ISO format (yyyy-mm-dd) |
| createdAt | TEXT      | Timestamp             |

---

## Testing Checklist

### Backend
- [ ] Health endpoint returns 200
- [ ] Analyze endpoint accepts valid request
- [ ] OpenRouter API key is working
- [ ] CORS is enabled
- [ ] Error handling works

### Flutter App
- [ ] App starts without errors
- [ ] Database initializes
- [ ] Can add expense
- [ ] Dashboard shows data
- [ ] Expense list displays correctly
- [ ] Filters work (month, category)
- [ ] Delete expense works
- [ ] AI assistant sends question and receives response
- [ ] Navigation between screens works

---

## Troubleshooting

### Backend Issues

**"OpenRouter API key not configured"**
- Ensure `.env` file exists in `backend` directory
- Check API key is correct
- Restart server after updating `.env`

**"CORS error"**
- Backend CORS is enabled by default
- Check backend is running on port 3000

**"Connection refused"**
- Ensure backend is running: `npm start`
- Check port 3000 is not in use

### Flutter Issues

**"Failed to connect to backend"**
- Ensure backend is running
- Update `baseUrl` in `api_service.dart` to match your setup
- For physical device, use machine IP instead of localhost

**"Database error"**
- Run: `flutter pub run build_runner build`
- Delete app and reinstall

**"Drift code generation failed"**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build
```

---

## Project Structure

```
expense_tracker/
├── lib/
│   ├── main.dart
│   ├── database/
│   │   └── database.dart
│   ├── models/
│   │   └── expense_model.dart
│   ├── services/
│   │   └── api_service.dart
│   ├── providers/
│   │   ├── database_provider.dart
│   │   └── api_provider.dart
│   └── screens/
│       ├── dashboard_screen.dart
│       ├── add_expense_screen.dart
│       ├── expense_list_screen.dart
│       └── ai_assistant_screen.dart
└── pubspec.yaml

backend/
├── server.js
├── package.json
├── .env
└── .env.example
```

---

## Next Steps (Optional Enhancements)

- [ ] Add receipt image upload
- [ ] Export expenses to CSV
- [ ] Dark mode support
- [ ] Budget alerts
- [ ] Recurring expenses
- [ ] Multi-currency support
- [ ] Cloud sync (Firebase)
- [ ] Offline AI analysis

---

## Support

For issues or questions, check:
1. Backend logs: `npm start` output
2. Flutter logs: `flutter run` output
3. OpenRouter API status: https://openrouter.ai/status
