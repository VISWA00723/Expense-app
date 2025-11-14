# 💰 Expense Tracker MVP

A modern Flutter mobile app for tracking expenses with AI-powered financial insights.

## ✨ Features

✅ **Local Expense Tracking**
- Add, edit, delete expenses
- Categorize spending (Food, Transport, Entertainment, etc.)
- Filter by month and category
- Local SQLite database (no cloud sync)

✅ **Dashboard**
- Current month's total spending
- Category breakdown pie chart
- Recent expenses at a glance

✅ **AI Assistant**
- Ask questions about your spending
- Get instant financial insights
- Powered by OpenRouter (GPT-4o-mini)

✅ **Clean UI**
- Material 3 design
- Mobile-first interface
- Smooth navigation
- Light theme

## 🏗️ Architecture

```
┌─────────────────┐
│   Flutter App   │
│  (iOS/Android)  │
└────────┬────────┘
         │ HTTP (Dio)
         ▼
┌─────────────────┐
│  Node.js Backend│
│   (Express)     │
└────────┬────────┘
         │ API Call
         ▼
┌─────────────────┐
│  OpenRouter API │
│  (GPT-4o-mini)  │
└─────────────────┘

Local Storage:
┌─────────────────┐
│  SQLite (Drift) │
│   Expenses DB   │
└─────────────────┘
```

## 📱 Screens

1. **Dashboard** - Overview of spending
2. **Add Expense** - Create new expense
3. **Expense List** - View and filter expenses
4. **AI Assistant** - Chat with AI about finances

## 🚀 Quick Start

### Backend
```bash
cd backend
npm install
# Create .env with OPENROUTER_API_KEY
npm start
```

### Flutter App
```bash
cd expense_tracker
flutter pub get
flutter pub run build_runner build
flutter run
```

See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed instructions.

## 📦 Tech Stack

**Frontend:**
- Flutter 3.x
- Riverpod (state management)
- Drift (SQLite ORM)
- Dio (HTTP client)
- fl_chart (charts)
- GoRouter (navigation)

**Backend:**
- Node.js
- Express.js
- OpenRouter API
- CORS enabled

**Database:**
- SQLite with Drift

## 🔐 Security

- No authentication required
- No cloud storage
- API key stored in backend `.env`
- CORS configured for local development

## 📊 Database Schema

```sql
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  notes TEXT,
  date TEXT NOT NULL,
  createdAt TEXT NOT NULL
);
```

## 🧪 Testing

### Backend Test
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend?",
    "expenses": [{"title": "Coffee", "amount": 150, "category": "Food", "date": "2025-01-10"}]
  }'
```

### Flutter Test
1. Add 5-10 expenses with different categories
2. Check dashboard displays correct totals
3. Verify filters work in expense list
4. Ask AI assistant a question
5. Verify response appears in chat

## 📝 API Endpoints

### POST /analyze
Analyze expenses with AI

**Request:**
```json
{
  "question": "string",
  "expenses": [
    {
      "title": "string",
      "amount": "number",
      "category": "string",
      "date": "yyyy-mm-dd",
      "notes": "string (optional)"
    }
  ]
}
```

**Response:**
```json
{
  "answer": "string",
  "summary": {
    "breakdown": { "category": amount },
    "totalExpenses": number,
    "expenseCount": number
  }
}
```

### GET /health
Server health check

## 🎯 What's NOT Included

❌ Web app
❌ Cloud storage
❌ User authentication
❌ Data syncing
❌ Ads or analytics
❌ Supabase

## 📄 License

MIT

## 🤝 Support

For setup help, see [SETUP_GUIDE.md](./SETUP_GUIDE.md)

---

**Built with ❤️ for expense tracking**
