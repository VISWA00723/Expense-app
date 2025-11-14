# Expense Tracker - Complete Redesign Guide

## 🎯 Overview

This is a completely redesigned Expense Tracker MVP with:
- ✅ **Authentication System** - Login/Signup with email
- ✅ **Salary Management** - Track monthly salary and remaining balance
- ✅ **Dynamic Categories** - 100+ predefined categories based on lifestyle
- ✅ **Custom Categories** - Users can add their own categories
- ✅ **Multi-user Support** - Each user has isolated data
- ✅ **Material 3 Design** - Modern, polished UI
- ✅ **Salary Tracking** - Visual breakdown of spent vs remaining

---

## 📱 New Features

### 1. Authentication Flow
- **Login Screen** - Sign in with email and password
- **Signup Screen** - Create account with name, email, password, and lifestyle selection
- **Profile Setup** - Set monthly salary and auto-populate categories based on lifestyle

### 2. Lifestyle-Based Categories
Categories automatically adjust based on user profile:

- **Bachelor** (45 categories)
  - Food & Dining, Groceries, Rent, Utilities, Internet, Mobile Phone
  - Transportation, Fuel, Gym, Entertainment, Movies, Gaming
  - Streaming Services, Books, Clothing, Shoes, Personal Care, etc.

- **Married** (55 categories)
  - All bachelor categories +
  - Spouse Expenses, Anniversary, Date Night, Wedding Related
  - Joint Savings, Household Items, Kitchen Appliances, etc.

- **Family** (75 categories)
  - All married categories +
  - Kids Expenses, School Fees, School Supplies, Toys
  - Kids Clothing, Daycare, Tuition, Sports, Music Classes
  - Doctor, Vaccination, Family Outing, Family Vacation, etc.

### 3. Dashboard Enhancements
- **Salary Card** - Shows monthly salary with gradient background
- **Spent vs Remaining** - Visual breakdown with color coding
- **Pie Chart** - Spending by category visualization
- **Recent Expenses** - Quick view of latest transactions
- **Logout** - User account management

### 4. Add Expense Improvements
- **Category Selection** - Beautiful filter chips with emojis
- **Date Picker** - Easy date selection
- **Form Validation** - Comprehensive error checking
- **Loading States** - Visual feedback during save

---

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  name TEXT NOT NULL,
  lifestyle TEXT NOT NULL, -- 'bachelor', 'married', 'family'
  monthly_salary REAL NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Incomes Table
```sql
CREATE TABLE incomes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  source TEXT NOT NULL,
  date TEXT NOT NULL, -- yyyy-mm-dd
  created_at TEXT NOT NULL
);
```

### Expense Categories Table
```sql
CREATE TABLE expense_categories (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  is_custom BOOLEAN DEFAULT FALSE,
  created_at TEXT NOT NULL
);
```

### Expenses Table
```sql
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category_id INTEGER NOT NULL,
  notes TEXT,
  date TEXT NOT NULL, -- yyyy-mm-dd
  created_at TEXT NOT NULL
);
```

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter 3.13+ installed
- Android SDK/Emulator or iOS setup
- Dart 3.0+

### Step 1: Install Dependencies
```bash
cd d:\exp\expense_app_new
flutter pub get
```

### Step 2: Generate Database Code
```bash
flutter pub run build_runner build
```

### Step 3: Run the App
```bash
flutter run
```

---

## 🔄 User Flow

### First Time User
1. **Signup Screen**
   - Enter name, email, password
   - Select lifestyle (Bachelor/Married/Family)
   - Confirm password

2. **Profile Setup Screen**
   - Enter monthly salary
   - Review auto-populated categories
   - Tap "Get Started"

3. **Dashboard**
   - See salary overview
   - View spending by category
   - Add first expense

### Returning User
1. **Login Screen**
   - Enter email and password
   - Tap "Sign In"

2. **Dashboard**
   - View all data
   - Add expenses
   - Manage account

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry & routing
├── database/
│   └── database.dart                  # Drift schema & operations
├── models/
│   └── expense_model.dart             # Data models
├── services/
│   ├── auth_service.dart              # Authentication logic
│   └── api_service.dart               # Backend API calls
├── providers/
│   ├── auth_provider.dart             # Auth Riverpod providers
│   └── database_provider.dart         # Database Riverpod providers
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── profile_setup_screen.dart
│   ├── dashboard_screen.dart
│   ├── add_expense_screen.dart
│   ├── expense_list_screen.dart
│   └── ai_assistant_screen.dart
└── data/
    └── categories_data.dart           # Predefined categories
```

---

## 🎨 Material 3 Design Features

- **Color Scheme** - Dynamic color from seed color
- **Typography** - Proper text hierarchy
- **Components** - FilledButton, FilterChip, Card, BottomNavigationBar
- **Spacing** - Consistent 16px/24px/32px rhythm
- **Icons** - Material Icons with outlined variants
- **Rounded Corners** - 12px border radius on inputs

---

## 🔐 Security Notes

⚠️ **Important**: Current implementation stores passwords in plain text for demo purposes.

For production:
- Use bcrypt or similar for password hashing
- Implement JWT tokens
- Use secure storage (flutter_secure_storage)
- Add SSL/TLS for backend communication
- Implement rate limiting

---

## 🧪 Testing Checklist

### Authentication
- [ ] Signup with new email
- [ ] Signup with existing email (should fail)
- [ ] Login with correct credentials
- [ ] Login with wrong password (should fail)
- [ ] Logout and return to login

### Profile Setup
- [ ] Enter salary and continue
- [ ] Categories populate based on lifestyle
- [ ] Can proceed to dashboard

### Dashboard
- [ ] Salary card displays correctly
- [ ] Spent amount updates
- [ ] Remaining balance calculated correctly
- [ ] Pie chart shows spending by category
- [ ] Recent expenses list displays

### Add Expense
- [ ] Can select category from chips
- [ ] Date picker works
- [ ] Form validation works
- [ ] Expense saves successfully
- [ ] Dashboard updates after adding expense

### Navigation
- [ ] Bottom navigation works
- [ ] All screens accessible
- [ ] Logout redirects to login

---

## 📊 Category Breakdown

### Bachelor Categories (45)
Food & Dining, Groceries, Rent, Utilities, Internet, Mobile Phone, Transportation, Fuel, Gym, Entertainment, Movies, Gaming, Streaming Services, Books, Clothing, Shoes, Personal Care, Haircut, Medical, Pharmacy, Insurance, Subscriptions, Coffee, Alcohol, Hobbies, Photography, Travel, Hotel, Vacation, Gifts, Electronics, Gadgets, Software, Education, Courses, Tuition, Pets, Pet Food, Pet Care, Home Maintenance, Furniture, Decoration, Cleaning, Laundry, Miscellaneous

### Additional Married Categories (10)
Spouse Expenses, Anniversary, Date Night, Wedding Related, Joint Savings, Household Items, Kitchen Appliances, Bedroom, Living Room, Bathroom

### Additional Family Categories (20)
Kids Expenses, School Fees, School Supplies, Toys, Kids Clothing, Kids Food, Daycare, Tuition (Kids), Sports (Kids), Music Classes, Doctor (Kids), Vaccination, Family Outing, Family Vacation, Elderly Care, Parents Support, Maid/Help, Babysitter, Family Gifts, Birthday Party

---

## 🐛 Troubleshooting

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Database Issues
- Delete app data: `flutter run --no-fast-start`
- Rebuild database: `flutter pub run build_runner build`

### Authentication Issues
- Check email format
- Ensure password is at least 6 characters
- Verify user exists in database

---

## 📝 Future Enhancements

- [ ] Income tracking and management
- [ ] Budget alerts and notifications
- [ ] Expense reports and analytics
- [ ] Data export (CSV/PDF)
- [ ] Dark mode support
- [ ] Multi-language support
- [ ] Biometric authentication
- [ ] Cloud backup
- [ ] Recurring expenses
- [ ] Receipt image capture

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the database schema
3. Check Riverpod provider setup
4. Verify authentication flow

---

**Status**: ✅ Ready for Testing & Development
**Last Updated**: 2024
**Version**: 2.0 (Redesigned)
