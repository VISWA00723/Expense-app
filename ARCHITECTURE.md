# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     EXPENSE TRACKER MVP                         │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    MOBILE LAYER (Flutter)                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              UI LAYER (Material 3)                      │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │  Dashboard   │  │ Add Expense  │  │ Expense List │  │   │
│  │  │   Screen     │  │   Screen     │  │   Screen     │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │   │
│  │  ┌──────────────┐                                       │   │
│  │  │ AI Assistant │                                       │   │
│  │  │   Screen     │                                       │   │
│  │  └──────────────┘                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ▲                                     │
│                           │                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         STATE MANAGEMENT LAYER (Riverpod)              │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  ┌──────────────────┐      ┌──────────────────┐        │   │
│  │  │ Database         │      │ API              │        │   │
│  │  │ Providers        │      │ Providers        │        │   │
│  │  │                  │      │                  │        │   │
│  │  │ • allExpenses    │      │ • analyzeExpense │        │   │
│  │  │ • recentExpense  │      │   Provider       │        │   │
│  │  │ • monthTotal     │      │                  │        │   │
│  │  │ • categoryBreak  │      │                  │        │   │
│  │  └──────────────────┘      └──────────────────┘        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ▲                                     │
│                           │                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         SERVICE LAYER                                  │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  ┌──────────────────┐      ┌──────────────────┐        │   │
│  │  │ Database Service │      │ API Service      │        │   │
│  │  │ (Drift)          │      │ (Dio)            │        │   │
│  │  │                  │      │                  │        │   │
│  │  │ • CRUD ops       │      │ • POST /analyze  │        │   │
│  │  │ • Queries        │      │ • Error handling │        │   │
│  │  │ • Transactions   │      │                  │        │   │
│  │  └──────────────────┘      └──────────────────┘        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ▲                                     │
│                           │                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         DATA LAYER (SQLite + Drift)                    │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │  Expenses Table                                  │  │   │
│  │  │  ┌────┬───────┬────────┬──────────┬───────────┐ │  │   │
│  │  │  │ id │ title │ amount │ category │    date   │ │  │   │
│  │  │  ├────┼───────┼────────┼──────────┼───────────┤ │  │   │
│  │  │  │ 1  │Coffee │  150   │   Food   │ 2025-01-10│ │  │   │
│  │  │  │ 2  │ Lunch │  450   │   Food   │ 2025-01-10│ │  │   │
│  │  │  │ 3  │ Uber  │  200   │Transport │ 2025-01-10│ │  │   │
│  │  │  └────┴───────┴────────┴──────────┴───────────┘ │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  │  Local SQLite Database (app_database.db)              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP (Dio)
                              │ POST /analyze
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                    BACKEND LAYER (Node.js)                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         Express.js Server (Port 3000)                   │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │                                                         │   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │  Routes                                          │  │   │
│  │  │  • GET  /health                                 │  │   │
│  │  │  • POST /analyze                                │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  │                      ▲                                  │   │
│  │                      │                                  │   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │  Middleware                                      │  │   │
│  │  │  • CORS                                          │  │   │
│  │  │  • JSON Parser                                   │  │   │
│  │  │  • Error Handler                                 │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  │                      ▲                                  │   │
│  │                      │                                  │   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │  Business Logic                                  │  │   │
│  │  │  • Request Validation                            │  │   │
│  │  │  • Prompt Engineering                            │  │   │
│  │  │  • Response Formatting                           │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  │                      ▲                                  │   │
│  │                      │                                  │   │
│  │  ┌──────────────────────────────────────────────────┐  │   │
│  │  │  API Integration (Axios)                         │  │   │
│  │  │  • OpenRouter API Client                         │  │   │
│  │  │  • Error Handling                                │  │   │
│  │  │  • Response Parsing                              │  │   │
│  │  └──────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              │ HTTPS                            │
│                              │ POST /chat/completions           │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Environment Configuration (.env)                       │   │
│  │  • OPENROUTER_API_KEY                                  │   │
│  │  • PORT                                                │   │
│  │  • NODE_ENV                                            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                    AI LAYER (OpenRouter)                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  OpenRouter API                                         │   │
│  │  https://openrouter.ai/api/v1/chat/completions         │   │
│  │                                                         │   │
│  │  Model: gpt-4o-mini                                    │   │
│  │  • Financial Analysis                                  │   │
│  │  • Spending Insights                                   │   │
│  │  • Category Breakdown                                  │   │
│  │  • Trend Analysis                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### 1. Add Expense Flow

```
User Input
    │
    ▼
┌─────────────────────┐
│  Add Expense Form   │
│  • Title            │
│  • Amount           │
│  • Category         │
│  • Date             │
│  • Notes            │
└─────────────────────┘
    │
    ▼ (Validation)
┌─────────────────────┐
│  Form Validation    │
│  • Required fields  │
│  • Valid amount     │
└─────────────────────┘
    │
    ▼ (Save)
┌─────────────────────┐
│  Database Service   │
│  insertExpense()    │
└─────────────────────┘
    │
    ▼ (Store)
┌─────────────────────┐
│  SQLite Database    │
│  Expenses Table     │
└─────────────────────┘
    │
    ▼ (Refresh)
┌─────────────────────┐
│  Riverpod Providers │
│  • allExpenses      │
│  • recentExpenses   │
│  • monthTotal       │
│  • categoryBreak    │
└─────────────────────┘
    │
    ▼ (Update)
┌─────────────────────┐
│  UI Screens         │
│  • Dashboard        │
│  • Expense List     │
└─────────────────────┘
```

### 2. AI Analysis Flow

```
User Question
    │
    ▼
┌─────────────────────┐
│  AI Assistant       │
│  Chat Interface     │
└─────────────────────┘
    │
    ▼ (Load Data)
┌─────────────────────┐
│  Database Service   │
│  getLastExpenses(300)
└─────────────────────┘
    │
    ▼ (Fetch)
┌─────────────────────┐
│  SQLite Database    │
│  Query Expenses     │
└─────────────────────┘
    │
    ▼ (Format)
┌─────────────────────┐
│  API Service        │
│  Prepare Request    │
│  {                  │
│    question: "...", │
│    expenses: [...]  │
│  }                  │
└─────────────────────┘
    │
    ▼ (Send)
┌─────────────────────┐
│  Backend Server     │
│  POST /analyze      │
└─────────────────────┘
    │
    ▼ (Process)
┌─────────────────────┐
│  Business Logic     │
│  • Validate input   │
│  • Build prompt     │
│  • Format data      │
└─────────────────────┘
    │
    ▼ (Call)
┌─────────────────────┐
│  OpenRouter API     │
│  GPT-4o-mini        │
│  Chat Completion    │
└─────────────────────┘
    │
    ▼ (Response)
┌─────────────────────┐
│  Backend Response   │
│  {                  │
│    answer: "...",   │
│    summary: {...}   │
│  }                  │
└─────────────────────┘
    │
    ▼ (Display)
┌─────────────────────┐
│  Chat Bubble        │
│  Show AI Response   │
└─────────────────────┘
```

### 3. Filter Expenses Flow

```
User Selects Filter
    │
    ├─ Filter by Month
    │   │
    │   ▼
    │  ┌──────────────────┐
    │  │ Select Month     │
    │  │ (Dropdown)       │
    │  └──────────────────┘
    │   │
    │   ▼
    │  ┌──────────────────┐
    │  │ Database Query   │
    │  │ getByMonth(month)│
    │  └──────────────────┘
    │
    ├─ Filter by Category
    │   │
    │   ▼
    │  ┌──────────────────┐
    │  │ Select Category  │
    │  │ (Dropdown)       │
    │  └──────────────────┘
    │   │
    │   ▼
    │  ┌──────────────────┐
    │  │ Database Query   │
    │  │ getByCategory()  │
    │  └──────────────────┘
    │
    ▼
┌──────────────────────┐
│ Riverpod Provider    │
│ Filtered Results     │
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│ Expense List Screen  │
│ Display Filtered     │
│ Expenses             │
└──────────────────────┘
```

---

## Component Interaction

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APP                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Screens ◄─────────────────────────────────────────────┐   │
│    │                                                   │   │
│    ├─ Dashboard                                        │   │
│    ├─ Add Expense                                      │   │
│    ├─ Expense List                                     │   │
│    └─ AI Assistant                                     │   │
│                                                        │   │
│    │                                                   │   │
│    ▼                                                   │   │
│  Providers (Riverpod) ◄─────────────────────────────┐ │   │
│    │                                                │ │   │
│    ├─ databaseProvider                             │ │   │
│    ├─ allExpensesProvider                          │ │   │
│    ├─ recentExpensesProvider                       │ │   │
│    ├─ currentMonthTotalProvider                    │ │   │
│    ├─ spendingByCategoryProvider                   │ │   │
│    ├─ apiServiceProvider                           │ │   │
│    └─ analyzeExpensesProvider                      │ │   │
│                                                    │ │   │
│    │                                               │ │   │
│    ▼                                               │ │   │
│  Services                                          │ │   │
│    │                                               │ │   │
│    ├─ ApiService (Dio) ──────────────────────────┼─┼──┐ │
│    │   └─ POST /analyze                           │ │  │ │
│    │                                              │ │  │ │
│    └─ Database Service (Drift)                    │ │  │ │
│        └─ SQLite Operations                       │ │  │ │
│                                                   │ │  │ │
│    │                                              │ │  │ │
│    ▼                                              │ │  │ │
│  Data Layer                                       │ │  │ │
│    │                                              │ │  │ │
│    └─ SQLite Database (Local)                    │ │  │ │
│        └─ Expenses Table                         │ │  │ │
│                                                  │ │  │ │
└──────────────────────────────────────────────────┼─┼──┼─┘
                                                   │ │  │
                                                   │ │  │
                    HTTP (Dio)                     │ │  │
                                                   │ │  │
                                                   ▼ ▼  │
                                        ┌──────────────┐│
                                        │ Backend      ││
                                        │ Express      ││
                                        │ Server       ││
                                        └──────────────┘│
                                                       │
                                        HTTPS          │
                                                       │
                                                       ▼
                                        ┌──────────────────┐
                                        │ OpenRouter API   │
                                        │ GPT-4o-mini      │
                                        └──────────────────┘
```

---

## Database Schema

```
┌─────────────────────────────────────────────────────┐
│           EXPENSES TABLE (SQLite)                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Column      │ Type      │ Constraints             │
│  ─────────────────────────────────────────────────  │
│  id          │ INTEGER   │ PRIMARY KEY AUTOINCR    │
│  title       │ TEXT      │ NOT NULL                │
│  amount      │ REAL      │ NOT NULL                │
│  category    │ TEXT      │ NOT NULL                │
│  notes       │ TEXT      │ NULLABLE                │
│  date        │ TEXT      │ NOT NULL (yyyy-mm-dd)   │
│  createdAt   │ TEXT      │ NOT NULL (timestamp)    │
│                                                     │
└─────────────────────────────────────────────────────┘

Indexes (for performance):
  • date (for month queries)
  • category (for category queries)
  • id DESC (for recent queries)
```

---

## API Contract

```
┌─────────────────────────────────────────────────────┐
│         POST /analyze                               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  REQUEST:                                           │
│  ┌─────────────────────────────────────────────┐   │
│  │ {                                           │   │
│  │   "question": "string",                     │   │
│  │   "expenses": [                             │   │
│  │     {                                       │   │
│  │       "title": "string",                    │   │
│  │       "amount": number,                     │   │
│  │       "category": "string",                 │   │
│  │       "date": "yyyy-mm-dd",                 │   │
│  │       "notes": "string (optional)"          │   │
│  │     }                                       │   │
│  │   ]                                         │   │
│  │ }                                           │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  RESPONSE (200):                                    │
│  ┌─────────────────────────────────────────────┐   │
│  │ {                                           │   │
│  │   "answer": "string",                       │   │
│  │   "summary": {                              │   │
│  │     "breakdown": {                          │   │
│  │       "category": amount                    │   │
│  │     },                                      │   │
│  │     "totalExpenses": number,                │   │
│  │     "expenseCount": number                  │   │
│  │   }                                         │   │
│  │ }                                           │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ERROR RESPONSE (400/500):                          │
│  ┌─────────────────────────────────────────────┐   │
│  │ {                                           │   │
│  │   "error": "string",                        │   │
│  │   "details": "string (optional)"            │   │
│  │ }                                           │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────┐
│         PRODUCTION DEPLOYMENT                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Mobile Devices                                     │
│  ├─ iOS (App Store)                                │
│  └─ Android (Google Play Store)                    │
│         │                                          │
│         │ HTTPS                                    │
│         ▼                                          │
│  ┌─────────────────────────────────────────────┐  │
│  │  Backend Server (Heroku/Railway/VPS)        │  │
│  │  ├─ Express.js                              │  │
│  │  ├─ Node.js Runtime                         │  │
│  │  └─ Environment Variables                   │  │
│  └─────────────────────────────────────────────┘  │
│         │                                          │
│         │ HTTPS                                    │
│         ▼                                          │
│  ┌─────────────────────────────────────────────┐  │
│  │  OpenRouter API                             │  │
│  │  └─ GPT-4o-mini Model                       │  │
│  └─────────────────────────────────────────────┘  │
│                                                     │
│  Local Storage (On Device):                        │
│  └─ SQLite Database (app_database.db)              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Technology Stack Diagram

```
┌──────────────────────────────────────────────────────┐
│              TECHNOLOGY STACK                        │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Frontend                                            │
│  ├─ Flutter 3.x                                      │
│  ├─ Dart 3.0+                                        │
│  ├─ Riverpod (State Management)                      │
│  ├─ Drift (ORM)                                      │
│  ├─ Dio (HTTP)                                       │
│  ├─ fl_chart (Charts)                                │
│  ├─ GoRouter (Navigation)                            │
│  └─ Material 3 (UI)                                  │
│                                                      │
│  Backend                                             │
│  ├─ Node.js 16+                                      │
│  ├─ Express.js 4.18+                                 │
│  ├─ Axios (HTTP Client)                              │
│  ├─ CORS (Cross-origin)                              │
│  └─ dotenv (Config)                                  │
│                                                      │
│  Database                                            │
│  ├─ SQLite 3                                         │
│  └─ Drift (Code Gen)                                 │
│                                                      │
│  AI/ML                                               │
│  └─ OpenRouter API (GPT-4o-mini)                     │
│                                                      │
│  DevOps                                              │
│  ├─ Git (Version Control)                            │
│  ├─ GitHub Actions (CI/CD)                           │
│  ├─ Heroku/Railway (Hosting)                         │
│  └─ PM2 (Process Manager)                            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## Security Architecture

```
┌──────────────────────────────────────────────────────┐
│           SECURITY LAYERS                            │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Layer 1: Frontend Security                          │
│  ├─ Local storage only (no cloud)                    │
│  ├─ No sensitive data in code                        │
│  └─ HTTPS for API calls                              │
│                                                      │
│  Layer 2: API Security                               │
│  ├─ CORS configured                                  │
│  ├─ Input validation                                 │
│  ├─ Error handling (no info leaks)                   │
│  └─ Rate limiting (optional)                         │
│                                                      │
│  Layer 3: Backend Security                           │
│  ├─ API key in .env (not in code)                    │
│  ├─ Environment-based config                         │
│  ├─ HTTPS only                                       │
│  └─ No database (stateless)                          │
│                                                      │
│  Layer 4: Data Security                              │
│  ├─ Local SQLite (encrypted at rest)                 │
│  ├─ No cloud storage                                 │
│  ├─ No data syncing                                  │
│  └─ User-controlled data                             │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

This architecture ensures:
- ✅ Clean separation of concerns
- ✅ Scalable design
- ✅ Easy to test and maintain
- ✅ Secure by default
- ✅ Performance optimized
- ✅ Future-proof
