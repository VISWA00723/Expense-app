# Quick Start - Expense Tracker Redesigned

## ⚡ 5-Minute Setup

### 1. Install Dependencies
```bash
cd d:\exp\expense_app_new
flutter pub get
```

### 2. Generate Database
```bash
flutter pub run build_runner build
```

### 3. Run App
```bash
flutter run
```

---

## 🎯 First Time User Flow

### Step 1: Sign Up
1. Tap "Sign Up" on login screen
2. Enter:
   - **Name**: Your full name
   - **Email**: your@email.com
   - **Lifestyle**: Bachelor/Married/Family
   - **Password**: At least 6 characters
3. Tap "Create Account"

### Step 2: Set Salary
1. Enter your **monthly salary** (e.g., 50000)
2. Tap "Continue"
3. Review auto-populated categories
4. Tap "Get Started"

### Step 3: Add First Expense
1. Tap the **+ Add** button
2. Enter expense details:
   - **Title**: "Lunch"
   - **Amount**: "250"
   - **Category**: Select from chips
   - **Date**: Pick date
   - **Notes**: Optional
3. Tap "Add Expense"

### Step 4: View Dashboard
- See your **monthly salary** at top
- View **spent** vs **remaining** balance
- Check **spending by category** pie chart
- See **recent expenses** list

---

## 🔑 Key Features

| Feature | Location |
|---------|----------|
| View Salary | Dashboard card (top) |
| Add Expense | Bottom nav → + Add |
| View All Expenses | Bottom nav → Expenses |
| AI Assistant | Bottom nav → AI |
| Logout | Dashboard → Top right |

---

## 📱 Navigation

```
Login/Signup
    ↓
Profile Setup (Salary)
    ↓
Dashboard ← → Add Expense
    ↓
Expense List
    ↓
AI Assistant
```

---

## 🎨 UI Highlights

✨ **Material 3 Design**
- Modern cards with gradients
- Smooth transitions
- Beautiful color scheme
- Responsive layout

🎯 **Category Selection**
- 100+ predefined categories
- Emoji icons for quick recognition
- Filter chips for easy selection
- Customizable categories

📊 **Dashboard**
- Salary overview card
- Spent vs remaining balance
- Pie chart visualization
- Recent transactions list

---

## 🧪 Test Data

### Test Account
- **Email**: test@example.com
- **Password**: password123
- **Name**: Test User
- **Lifestyle**: Bachelor
- **Salary**: 50000

---

## ⚠️ Important Notes

1. **First Run**: App will create database automatically
2. **Categories**: Auto-populated based on lifestyle
3. **Data**: All stored locally (no cloud sync)
4. **Password**: Currently stored in plain text (demo only)

---

## 🐛 Common Issues

### App won't run
```bash
flutter clean
flutter pub get
flutter pub run build_runner build
flutter run
```

### Categories not showing
- Ensure you completed profile setup
- Check that categories were created in database

### Expenses not saving
- Verify category is selected
- Check amount is valid number
- Ensure user is logged in

---

## 📊 What's New vs Original

| Feature | Original | Redesigned |
|---------|----------|-----------|
| Authentication | ❌ | ✅ |
| Multi-user | ❌ | ✅ |
| Salary Tracking | ❌ | ✅ |
| 100+ Categories | ❌ | ✅ |
| Lifestyle-based | ❌ | ✅ |
| Material 3 | ⚠️ | ✅ |
| Better UI | ⚠️ | ✅ |

---

## 🚀 Next Steps

1. ✅ Run the app
2. ✅ Create account
3. ✅ Set salary
4. ✅ Add expenses
5. ✅ View dashboard
6. ✅ Test all features

---

**Ready to go!** 🎉
