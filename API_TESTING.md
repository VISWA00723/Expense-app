# API Testing Guide

## Backend Health Check

### Test 1: Health Endpoint
```bash
curl http://localhost:3000/health
```

**Expected Response:**
```json
{
  "status": "OK"
}
```

---

## Analyze Endpoint Tests

### Test 2: Basic Question
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend on food?",
    "expenses": [
      {
        "title": "Coffee",
        "amount": 150,
        "category": "Food",
        "date": "2025-01-10",
        "notes": "Morning coffee"
      },
      {
        "title": "Lunch",
        "amount": 450,
        "category": "Food",
        "date": "2025-01-10",
        "notes": "Restaurant"
      }
    ]
  }'
```

**Expected Response:**
```json
{
  "answer": "Based on your expenses, you spent ₹600 on Food.",
  "summary": {
    "breakdown": {
      "Food": 600
    },
    "totalExpenses": 600,
    "expenseCount": 2
  }
}
```

---

### Test 3: Multiple Categories
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is my spending breakdown by category?",
    "expenses": [
      {
        "title": "Coffee",
        "amount": 150,
        "category": "Food",
        "date": "2025-01-10"
      },
      {
        "title": "Uber",
        "amount": 200,
        "category": "Transport",
        "date": "2025-01-10"
      },
      {
        "title": "Movie",
        "amount": 300,
        "category": "Entertainment",
        "date": "2025-01-10"
      },
      {
        "title": "Shirt",
        "amount": 1500,
        "category": "Shopping",
        "date": "2025-01-10"
      }
    ]
  }'
```

**Expected Response:**
```json
{
  "answer": "Your spending breakdown is: Food ₹150, Transport ₹200, Entertainment ₹300, Shopping ₹1500. Total: ₹2150",
  "summary": {
    "breakdown": {
      "Food": 150,
      "Transport": 200,
      "Entertainment": 300,
      "Shopping": 1500
    },
    "totalExpenses": 2150,
    "expenseCount": 4
  }
}
```

---

### Test 4: Highest Spending Category
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Which category did I spend the most on?",
    "expenses": [
      {
        "title": "Coffee",
        "amount": 150,
        "category": "Food",
        "date": "2025-01-10"
      },
      {
        "title": "Lunch",
        "amount": 300,
        "category": "Food",
        "date": "2025-01-10"
      },
      {
        "title": "Dinner",
        "amount": 400,
        "category": "Food",
        "date": "2025-01-11"
      },
      {
        "title": "Uber",
        "amount": 200,
        "category": "Transport",
        "date": "2025-01-10"
      },
      {
        "title": "Movie",
        "amount": 300,
        "category": "Entertainment",
        "date": "2025-01-10"
      }
    ]
  }'
```

**Expected Response:**
```json
{
  "answer": "Your highest spending category is Food with ₹850, which is 56.7% of your total spending.",
  "summary": {
    "breakdown": {
      "Food": 850,
      "Transport": 200,
      "Entertainment": 300
    },
    "totalExpenses": 1350,
    "expenseCount": 5
  }
}
```

---

### Test 5: Empty Expenses (Edge Case)
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend?",
    "expenses": []
  }'
```

**Expected Response:**
```json
{
  "answer": "You have no expenses recorded yet.",
  "summary": {
    "breakdown": {},
    "totalExpenses": 0,
    "expenseCount": 0
  }
}
```

---

### Test 6: Invalid Request (Missing Question)
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "expenses": []
  }'
```

**Expected Response:**
```json
{
  "error": "Invalid request. Required: question (string), expenses (array)"
}
```

---

### Test 7: Invalid Request (Missing Expenses)
```bash
curl -X POST http://localhost:3000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend?"
  }'
```

**Expected Response:**
```json
{
  "error": "Invalid request. Required: question (string), expenses (array)"
}
```

---

## Using Postman

### Import Collection

1. Open Postman
2. Create new collection: "Expense Tracker"
3. Add requests:

#### Request 1: Health Check
- **Method:** GET
- **URL:** `http://localhost:3000/health`

#### Request 2: Analyze Expenses
- **Method:** POST
- **URL:** `http://localhost:3000/analyze`
- **Headers:** `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "question": "How much did I spend on food?",
  "expenses": [
    {
      "title": "Coffee",
      "amount": 150,
      "category": "Food",
      "date": "2025-01-10"
    }
  ]
}
```

---

## Using Python

```python
import requests
import json

BASE_URL = "http://localhost:3000"

# Test health
response = requests.get(f"{BASE_URL}/health")
print("Health:", response.json())

# Test analyze
data = {
    "question": "How much did I spend on food?",
    "expenses": [
        {
            "title": "Coffee",
            "amount": 150,
            "category": "Food",
            "date": "2025-01-10"
        },
        {
            "title": "Lunch",
            "amount": 450,
            "category": "Food",
            "date": "2025-01-10"
        }
    ]
}

response = requests.post(f"{BASE_URL}/analyze", json=data)
print("Analysis:", json.dumps(response.json(), indent=2))
```

---

## Using JavaScript/Node.js

```javascript
const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// Test health
axios.get(`${BASE_URL}/health`)
  .then(res => console.log('Health:', res.data))
  .catch(err => console.error('Error:', err.message));

// Test analyze
const data = {
  question: 'How much did I spend on food?',
  expenses: [
    {
      title: 'Coffee',
      amount: 150,
      category: 'Food',
      date: '2025-01-10'
    },
    {
      title: 'Lunch',
      amount: 450,
      category: 'Food',
      date: '2025-01-10'
    }
  ]
};

axios.post(`${BASE_URL}/analyze`, data)
  .then(res => console.log('Analysis:', JSON.stringify(res.data, null, 2)))
  .catch(err => console.error('Error:', err.message));
```

---

## Troubleshooting

### "Connection refused"
- Backend not running
- Check: `npm start` in backend directory

### "Invalid API key"
- Check `.env` file has correct OPENROUTER_API_KEY
- Restart backend after updating `.env`

### "CORS error"
- CORS is enabled in backend
- Check request headers include `Content-Type: application/json`

### "Timeout"
- OpenRouter API might be slow
- Check internet connection
- Verify API key has credits

---

## Sample Test Data

### Minimal
```json
{
  "question": "Total spent?",
  "expenses": [
    {"title": "Coffee", "amount": 100, "category": "Food", "date": "2025-01-10"}
  ]
}
```

### Realistic (1 Month)
```json
{
  "question": "How much did I spend last month?",
  "expenses": [
    {"title": "Coffee", "amount": 150, "category": "Food", "date": "2025-01-05"},
    {"title": "Lunch", "amount": 450, "category": "Food", "date": "2025-01-05"},
    {"title": "Dinner", "amount": 600, "category": "Food", "date": "2025-01-05"},
    {"title": "Uber", "amount": 200, "category": "Transport", "date": "2025-01-06"},
    {"title": "Movie", "amount": 300, "category": "Entertainment", "date": "2025-01-07"},
    {"title": "Shirt", "amount": 1500, "category": "Shopping", "date": "2025-01-08"},
    {"title": "Electricity", "amount": 2000, "category": "Bills", "date": "2025-01-10"},
    {"title": "Doctor", "amount": 500, "category": "Health", "date": "2025-01-12"}
  ]
}
```

### Large Dataset (300 expenses)
Generate programmatically using the test script below.

---

## Automated Testing Script

```bash
#!/bin/bash

# test_api.sh

BASE_URL="http://localhost:3000"

echo "🧪 Testing Expense Tracker API"
echo "================================"

# Test 1: Health
echo -e "\n✅ Test 1: Health Check"
curl -s $BASE_URL/health | jq .

# Test 2: Basic analyze
echo -e "\n✅ Test 2: Basic Analysis"
curl -s -X POST $BASE_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How much did I spend?",
    "expenses": [
      {"title": "Coffee", "amount": 150, "category": "Food", "date": "2025-01-10"}
    ]
  }' | jq .

# Test 3: Multiple categories
echo -e "\n✅ Test 3: Multiple Categories"
curl -s -X POST $BASE_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Show my spending breakdown",
    "expenses": [
      {"title": "Coffee", "amount": 150, "category": "Food", "date": "2025-01-10"},
      {"title": "Uber", "amount": 200, "category": "Transport", "date": "2025-01-10"},
      {"title": "Movie", "amount": 300, "category": "Entertainment", "date": "2025-01-10"}
    ]
  }' | jq .

# Test 4: Invalid request
echo -e "\n✅ Test 4: Invalid Request (should error)"
curl -s -X POST $BASE_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{"question": "test"}' | jq .

echo -e "\n✅ All tests completed!"
```

Save as `test_api.sh`, then run:
```bash
chmod +x test_api.sh
./test_api.sh
```

---

## Performance Testing

### Load Test with Apache Bench
```bash
ab -n 100 -c 10 -p payload.json -T application/json http://localhost:3000/analyze
```

### Load Test with wrk
```bash
wrk -t4 -c100 -d30s --script=post.lua http://localhost:3000/analyze
```

---

## Next Steps

1. ✅ Test all endpoints with curl
2. ✅ Verify OpenRouter API integration
3. ✅ Test with Flutter app
4. ✅ Monitor backend logs
5. ✅ Check response times
