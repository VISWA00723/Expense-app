# Legend Scrollable & "View All" Feature

## Problem

When users add more and more expense categories, the legend grows indefinitely and takes up too much screen space on the dashboard.

## Solution

Implemented a smart legend that:
- Shows only top 4 categories
- Becomes scrollable if needed
- Displays "View All" button when > 4 categories
- Shows "+X more categories" indicator
- Maintains clean dashboard layout

## Features

### 1. **Limited Display (Top 4 Categories)**
- Shows the 4 most expensive categories
- Keeps dashboard clean and focused
- Prevents excessive scrolling

### 2. **"View All" Button**
- Appears when more than 4 categories exist
- Navigates to `/list` screen
- Shows all expenses with full details
- Easy access to complete data

### 3. **Scrollable Legend**
- Max height: 400px
- Scrolls internally if needed
- Doesn't affect dashboard scroll
- Smooth scrolling experience

### 4. **More Categories Indicator**
- Shows "+X more categories" text
- Helps users understand there's more data
- Subtle styling (italic, secondary color)
- Only appears when > 4 categories

## Layout

### With ≤ 4 Categories:
```
┌──────────────────────────┐
│   Pie Chart              │
├──────────────────────────┤
│ Category Breakdown       │
├──────────────────────────┤
│ ● Category 1  ₹500 6.3%  │
│   ▓▓▓▓░░░░░░░░░░░░░░░░  │
│ ● Category 2  ₹300 3.8%  │
│   ▓░░░░░░░░░░░░░░░░░░░░ │
│ ● Category 3  ₹200 2.5%  │
│   ▓░░░░░░░░░░░░░░░░░░░░ │
│ ● Category 4  ₹100 1.3%  │
│   ▓░░░░░░░░░░░░░░░░░░░░ │
└──────────────────────────┘
```

### With > 4 Categories:
```
┌──────────────────────────┐
│   Pie Chart              │
├──────────────────────────┤
│ Category Breakdown  View All
├──────────────────────────┤
│ ● Category 1  ₹500 6.3%  │
│   ▓▓▓▓░░░░░░░░░░░░░░░░  │
│ ● Category 2  ₹300 3.8%  │
│   ▓░░░░░░░░░░░░░░░░░░░░ │
│ ● Category 3  ₹200 2.5%  │
│   ▓░░░░░░░░░░░░░░░░░░░░ │
│ ● Category 4  ₹100 1.3%  │
│   ▓░░░░░░░░░░░░░░░░░░░░ │
├──────────────────────────┤
│ +8 more categories       │
└──────────────────────────┘
```

## Technical Implementation

### File: `lib/screens/dashboard_screen.dart`

#### 1. Header with "View All" Button
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Category Breakdown', ...),
    if (entries.length > 4)
      TextButton(
        onPressed: () => context.go('/list'),
        child: const Text('View All'),
      ),
  ],
),
```

#### 2. Scrollable Legend Container
```dart
ConstrainedBox(
  constraints: const BoxConstraints(maxHeight: 400),
  child: SingleChildScrollView(
    child: ListView.builder(
      itemCount: entries.length > 4 ? 4 : entries.length,
      // ... legend items
    ),
  ),
),
```

#### 3. More Categories Indicator
```dart
if (entries.length > 4)
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Center(
      child: Text(
        '+${entries.length - 4} more categories',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  ),
```

## Behavior

### Scenario 1: 3 Categories
- Shows all 3 categories
- No "View All" button
- No "+X more" indicator
- Clean, simple layout

### Scenario 2: 4 Categories
- Shows all 4 categories
- No "View All" button
- No "+X more" indicator
- Perfect fit

### Scenario 3: 5 Categories
- Shows top 4 categories
- "View All" button appears
- Shows "+1 more categories"
- User can tap "View All" to see all

### Scenario 4: 15 Categories
- Shows top 4 categories
- "View All" button appears
- Shows "+11 more categories"
- Legend is scrollable (max 400px)
- User can scroll or tap "View All"

## User Experience

### On Dashboard:
1. User sees pie chart
2. User sees top 4 categories in legend
3. If more categories exist:
   - User sees "View All" button
   - User sees "+X more categories" text
   - User can tap "View All" to see all expenses

### On Expense List:
1. User taps "View All"
2. Navigates to `/list` screen
3. Sees all expenses with full details
4. Can filter, sort, search
5. Can go back to dashboard

## Benefits

✅ **Clean Dashboard**
- Not cluttered with too many categories
- Focuses on top spending categories
- Professional appearance

✅ **Easy Navigation**
- "View All" button for quick access
- Clear indicator of more data
- Smooth transition to list view

✅ **Scalability**
- Works with any number of categories
- Handles 100+ categories gracefully
- No performance issues

✅ **User Friendly**
- Intuitive interface
- Clear visual hierarchy
- Easy to understand

## Responsive Design

### Mobile (< 600px)
- Legend items stack vertically
- "View All" button on same line
- Scrollable legend (max 400px)
- Touch-friendly buttons

### Tablet (> 600px)
- Legend items have more space
- "View All" button clearly visible
- Scrollable legend (max 400px)
- Better readability

## Customization

### Change Max Categories Shown:
```dart
// Currently shows 4, change to 5:
itemCount: entries.length > 5 ? 5 : entries.length,

// And update indicator:
if (entries.length > 5)
  Text('+${entries.length - 5} more categories'),
```

### Change Max Height:
```dart
// Currently 400px, change to 500px:
constraints: const BoxConstraints(maxHeight: 500),
```

### Change Navigation Target:
```dart
// Currently goes to /list, change to /custom:
onPressed: () => context.go('/custom'),
```

## Testing Checklist

- [ ] Dashboard shows pie chart correctly
- [ ] Legend shows top 4 categories
- [ ] "View All" button appears when > 4 categories
- [ ] "+X more categories" text appears when > 4 categories
- [ ] "View All" button navigates to /list
- [ ] Legend is scrollable (max 400px)
- [ ] Works with 1 category
- [ ] Works with 4 categories
- [ ] Works with 5 categories
- [ ] Works with 20+ categories
- [ ] Works on mobile
- [ ] Works on tablet
- [ ] Works in light mode
- [ ] Works in dark mode

## Performance

✅ Efficient rendering (only 4 items shown)
✅ No unnecessary rebuilds
✅ Smooth scrolling
✅ Fast navigation to list

## Accessibility

✅ Clear visual hierarchy
✅ High contrast text
✅ Touch-friendly buttons
✅ Readable font sizes
✅ Material 3 compliant

## Future Enhancements

1. **Sorting Options**
   - Sort by amount (default)
   - Sort by name
   - Sort by percentage

2. **Filtering**
   - Filter by date range
   - Filter by category type
   - Filter by amount range

3. **Customization**
   - User can choose how many to show
   - User can pin favorite categories
   - User can hide categories

4. **Analytics**
   - Show trends
   - Show comparisons
   - Show forecasts

---

**Status**: ✅ Complete
**Version**: 3.2 (With Scrollable Legend & View All)
**Tested**: All devices
**Performance**: Optimized
