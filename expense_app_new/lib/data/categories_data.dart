// Predefined expense categories based on lifestyle
class CategoryData {
  final String name;
  final String icon;

  CategoryData({required this.name, required this.icon});
}

class PredefinedCategories {
  // Bachelor categories
  static final List<CategoryData> bachelorCategories = [
    CategoryData(name: 'Food & Dining', icon: '🍔'),
    CategoryData(name: 'Groceries', icon: '🛒'),
    CategoryData(name: 'Rent', icon: '🏠'),
    CategoryData(name: 'Utilities', icon: '💡'),
    CategoryData(name: 'Internet', icon: '📡'),
    CategoryData(name: 'Mobile Phone', icon: '📱'),
    CategoryData(name: 'Transportation', icon: '🚗'),
    CategoryData(name: 'Fuel', icon: '⛽'),
    CategoryData(name: 'Gym', icon: '💪'),
    CategoryData(name: 'Entertainment', icon: '🎬'),
    CategoryData(name: 'Movies', icon: '🎥'),
    CategoryData(name: 'Gaming', icon: '🎮'),
    CategoryData(name: 'Streaming Services', icon: '📺'),
    CategoryData(name: 'Books', icon: '📚'),
    CategoryData(name: 'Clothing', icon: '👕'),
    CategoryData(name: 'Shoes', icon: '👟'),
    CategoryData(name: 'Personal Care', icon: '💇'),
    CategoryData(name: 'Haircut', icon: '✂️'),
    CategoryData(name: 'Medical', icon: '⚕️'),
    CategoryData(name: 'Pharmacy', icon: '💊'),
    CategoryData(name: 'Insurance', icon: '🛡️'),
    CategoryData(name: 'Subscriptions', icon: '🔔'),
    CategoryData(name: 'Coffee', icon: '☕'),
    CategoryData(name: 'Alcohol', icon: '🍺'),
    CategoryData(name: 'Hobbies', icon: '🎨'),
    CategoryData(name: 'Photography', icon: '📷'),
    CategoryData(name: 'Travel', icon: '✈️'),
    CategoryData(name: 'Hotel', icon: '🏨'),
    CategoryData(name: 'Vacation', icon: '🏖️'),
    CategoryData(name: 'Gifts', icon: '🎁'),
    CategoryData(name: 'Electronics', icon: '💻'),
    CategoryData(name: 'Gadgets', icon: '⌚'),
    CategoryData(name: 'Software', icon: '💾'),
    CategoryData(name: 'Education', icon: '🎓'),
    CategoryData(name: 'Courses', icon: '📖'),
    CategoryData(name: 'Tuition', icon: '👨‍🏫'),
    CategoryData(name: 'Pets', icon: '🐕'),
    CategoryData(name: 'Pet Food', icon: '🦴'),
    CategoryData(name: 'Pet Care', icon: '🐾'),
    CategoryData(name: 'Home Maintenance', icon: '🔧'),
    CategoryData(name: 'Furniture', icon: '🛋️'),
    CategoryData(name: 'Decoration', icon: '🖼️'),
    CategoryData(name: 'Cleaning', icon: '🧹'),
    CategoryData(name: 'Laundry', icon: '👔'),
    CategoryData(name: 'Miscellaneous', icon: '📦'),
  ];

  // Married categories (includes bachelor + family-related)
  static final List<CategoryData> marriedCategories = [
    ...bachelorCategories,
    CategoryData(name: 'Spouse Expenses', icon: '👰'),
    CategoryData(name: 'Anniversary', icon: '💍'),
    CategoryData(name: 'Date Night', icon: '🍽️'),
    CategoryData(name: 'Wedding Related', icon: '💒'),
    CategoryData(name: 'Joint Savings', icon: '🏦'),
    CategoryData(name: 'Household Items', icon: '🏠'),
    CategoryData(name: 'Kitchen Appliances', icon: '🍳'),
    CategoryData(name: 'Bedroom', icon: '🛏️'),
    CategoryData(name: 'Living Room', icon: '🪑'),
    CategoryData(name: 'Bathroom', icon: '🚿'),
  ];

  // Family categories (includes all + kids/family)
  static final List<CategoryData> familyCategories = [
    ...marriedCategories,
    CategoryData(name: 'Kids Expenses', icon: '👶'),
    CategoryData(name: 'School Fees', icon: '🎒'),
    CategoryData(name: 'School Supplies', icon: '✏️'),
    CategoryData(name: 'Toys', icon: '🧸'),
    CategoryData(name: 'Kids Clothing', icon: '👕'),
    CategoryData(name: 'Kids Food', icon: '🍼'),
    CategoryData(name: 'Daycare', icon: '🏫'),
    CategoryData(name: 'Tuition (Kids)', icon: '📚'),
    CategoryData(name: 'Sports (Kids)', icon: '⚽'),
    CategoryData(name: 'Music Classes', icon: '🎵'),
    CategoryData(name: 'Doctor (Kids)', icon: '👨‍⚕️'),
    CategoryData(name: 'Vaccination', icon: '💉'),
    CategoryData(name: 'Family Outing', icon: '🎪'),
    CategoryData(name: 'Family Vacation', icon: '🏝️'),
    CategoryData(name: 'Elderly Care', icon: '👴'),
    CategoryData(name: 'Parents Support', icon: '👨‍👩‍👧'),
    CategoryData(name: 'Maid/Help', icon: '🧹'),
    CategoryData(name: 'Babysitter', icon: '👩‍🍼'),
    CategoryData(name: 'Family Gifts', icon: '🎀'),
    CategoryData(name: 'Birthday Party', icon: '🎂'),
  ];

  static List<CategoryData> getCategoriesForLifestyle(String lifestyle) {
    switch (lifestyle.toLowerCase()) {
      case 'bachelor':
        return bachelorCategories;
      case 'married':
        return marriedCategories;
      case 'family':
        return familyCategories;
      default:
        return bachelorCategories;
    }
  }
}
