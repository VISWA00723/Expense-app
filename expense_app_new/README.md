# 💰 Expense Tracker - Redesigned v2.0

A beautiful, feature-rich Flutter expense tracking app with authentication, salary management, and 100+ intelligent categories.

## ✨ Features

### 🔐 Authentication
- Email/password signup and login
- Secure user accounts
- Profile setup with salary and lifestyle selection
- Multi-user support with data isolation

### 💵 Salary Management
- Set monthly salary during profile setup
- Track spent vs remaining balance
- Visual breakdown with color coding
- Real-time calculations

### 📂 100+ Smart Categories
Categories automatically adjust based on lifestyle:
- **Bachelor** (45 categories) - Basic living expenses
- **Married** (55 categories) - Couple-specific expenses  
- **Family** (75 categories) - Family and kids expenses
- All with emoji icons for quick recognition

### 📊 Dashboard
- Gradient salary card showing spent/remaining
- Pie chart for spending by category
- Recent expenses list
- Quick navigation to all features

### ➕ Add Expenses
- Beautiful category selection with filter chips
- Date picker with visual feedback
- Form validation and error handling
- Loading states and success feedback

### 🎨 Material 3 Design
- Modern color scheme
- Smooth animations
- Responsive layout
- Consistent spacing and typography

### 🌍 Multi-Currency Support
- Support for major global currencies:
  - INR (₹), USD ($), EUR (€), GBP (£)
  - AUD (A$), CAD (C$), JPY (¥), CNY (¥)
- Dynamic currency formatting in exports (PDF/CSV)
- Intelligent receipt scanning for multiple currencies

## 🚀 Quick Start

### Prerequisites
- Flutter 3.13+
- Dart 3.0+
- Android SDK or iOS setup

### Installation

```bash
# 1. Clone or navigate to project
cd d:\exp\expense_app_new

# 2. Install dependencies
flutter pub get

# 3. Generate database code
flutter pub run build_runner build

# 4. Run the app
flutter run
```

## 📱 First Time Setup

1. **Sign Up**
   - Enter name, email, password
   - Select lifestyle (Bachelor/Married/Family)
   - Confirm password

2. **Set Salary**
   - Enter monthly salary
   - Review auto-populated categories
   - Tap "Get Started"

3. **Add Expenses**
   - Tap "+ Add" button
   - Select category, enter amount
   - Pick date and add notes
   - Tap "Add Expense"

4. **View Dashboard**
   - See salary overview
   - Check spending by category
   - View recent expenses

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry & routing
├── database/
│   └── database.dart                  # Drift schema (4 tables)
├── models/
│   └── expense_model.dart             # Data models
├── services/
│   ├── auth_service.dart              # Authentication
│   └── api_service.dart               # API calls
├── providers/
│   ├── auth_provider.dart             # Auth state
│   └── database_provider.dart         # DB state
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
    └── categories_data.dart           # 100+ categories
```

## 🗄️ Database Schema

### Users
- id, email, password, name, lifestyle, monthlySalary, createdAt, updatedAt

### Incomes
- id, userId, amount, source, date, createdAt

### ExpenseCategories
- id, userId, name, icon, isCustom, createdAt

### Expenses
- id, userId, title, amount, categoryId, notes, date, createdAt

## 🎯 Navigation

```
Login/Signup
    ↓
Profile Setup (Salary)
    ↓
Dashboard ←→ Add Expense
    ↓
Expense List
    ↓
AI Assistant
```

## 🧪 Test Account

- **Email**: test@example.com
- **Password**: password123
- **Name**: Test User
- **Lifestyle**: Bachelor
- **Salary**: 50000

## 📊 Category Examples

### Bachelor Categories
Food & Dining, Groceries, Rent, Utilities, Internet, Mobile Phone, Transportation, Fuel, Gym, Entertainment, Movies, Gaming, Streaming Services, Books, Clothing, Shoes, Personal Care, Medical, Pharmacy, Insurance, Travel, Hotel, Gifts, Electronics, Education, Pets, Home Maintenance, Furniture, Cleaning, Miscellaneous...

### Additional Married Categories
Spouse Expenses, Anniversary, Date Night, Wedding Related, Joint Savings, Household Items, Kitchen Appliances, Bedroom, Living Room, Bathroom

### Additional Family Categories
Kids Expenses, School Fees, School Supplies, Toys, Kids Clothing, Daycare, Tuition, Sports, Music Classes, Doctor, Vaccination, Family Outing, Family Vacation, Elderly Care, Parents Support, Babysitter, Family Gifts, Birthday Party

## 🔐 Security Notes

⚠️ **Current Implementation**: Demo version with plain text passwords

**For Production**:
- Use bcrypt for password hashing
- Implement JWT tokens
- Use flutter_secure_storage
- Add SSL/TLS encryption
- Implement rate limiting
- Add input validation

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

### Auth Issues
- Check email format
- Ensure password is 6+ characters
- Verify user exists in database

## 📚 Documentation

- **QUICK_START.md** - 5-minute setup guide
- **REDESIGN_GUIDE.md** - Complete feature documentation
- **IMPLEMENTATION_SUMMARY.md** - Technical overview

## 🔄 What's New vs Original

| Feature | Original | Redesigned |
|---------|----------|-----------|
| Authentication | ❌ | ✅ |
| Multi-user | ❌ | ✅ |
| Salary Tracking | ❌ | ✅ |
| 100+ Categories | ❌ | ✅ |
| Lifestyle-based | ❌ | ✅ |
| Material 3 | ⚠️ | ✅ |
| Better UI | ⚠️ | ✅ |

## 🚀 Future Enhancements

- [ ] Income tracking UI
- [ ] Budget alerts
- [ ] Expense reports
- [ ] Data export (CSV/PDF)
- [ ] Dark mode
- [ ] Multi-language support
- [ ] Biometric authentication
- [ ] Cloud backup
- [ ] Recurring expenses
- [ ] Receipt image capture

## 📦 Dependencies

```yaml
flutter_riverpod: ^2.6.1      # State management
drift: ^2.29.0                # SQLite ORM
go_router: ^12.1.3            # Navigation
fl_chart: ^0.65.0             # Charts
intl: ^0.19.0                 # Internationalization
dio: ^5.4.0                   # HTTP client
image_picker: ^1.0.7          # Image selection
permission_handler: ^11.4.0   # Permissions
```

## 💡 Architecture

- **State Management**: Riverpod (FutureProvider, StateProvider)
- **Database**: Drift (SQLite ORM)
- **Navigation**: GoRouter (declarative routing)
- **UI Framework**: Flutter Material 3
- **Code Generation**: build_runner for Drift

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the documentation files
3. Check the database schema
4. Verify authentication flow

## 📄 License

This project is provided as-is for educational and development purposes.

## ✅ Status

**Version**: 2.0 (Redesigned)
**Status**: Ready for Testing & Deployment
**Last Updated**: 2024

---

**Happy Expense Tracking!** 💰✨
