# Firestore Index Creation Guide - Weekly Plans

## Issue
The Weekly Plan query requires a composite index because it filters on multiple fields:
- `year` (equality filter)
- `weekNumber` (equality filter)
- `createdAt` (orderBy)

## Quick Fix (Recommended)

### Option 1: Use the Error Link
1. When you see the Firestore index error in the console, it will include a clickable link
2. Click the link - it will open Firebase Console with pre-filled index configuration
3. Click "Create Index"
4. Wait 1-2 minutes for index to build
5. Refresh your app

### Option 2: Manual Creation

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com/
   - Select your project

2. **Navigate to Firestore Indexes**
   - Click "Firestore Database" in left sidebar
   - Click "Indexes" tab at the top

3. **Create Composite Index**
   - Click "Create Index" button
   - Configure as follows:

   **Collection ID:** `weeklyPlans`
   
   **Fields to index:**
   | Field Name | Order |
   |------------|-------|
   | year | Ascending |
   | weekNumber | Ascending |
   | createdAt | Ascending |
   
   **Query scope:** Collection

4. **Save and Wait**
   - Click "Create"
   - Status will show "Building..."
   - Wait 1-2 minutes (usually very fast for empty collections)
   - Status will change to "Enabled"

5. **Test**
   - Refresh your app
   - Navigate to Weekly Plan tab
   - Should load without errors

## Index Configuration Details

```
Collection: weeklyPlans
Fields:
  - year (Ascending)
  - weekNumber (Ascending)
  - createdAt (Ascending)
Query Scope: Collection
```

## Why This Index is Needed

The query in `WeeklyPlanService` is:
```dart
_firestore
  .collection('weeklyPlans')
  .where('year', isEqualTo: year)           // Filter 1
  .where('weekNumber', isEqualTo: weekNumber) // Filter 2
  .orderBy('createdAt', descending: false)   // Sort
```

Firestore requires a composite index when:
- Multiple equality filters + orderBy on different field
- Multiple inequality filters
- orderBy on multiple fields

## Troubleshooting

### Index Still Building
- Wait a few more minutes
- Check "Indexes" tab for status
- Should be very fast for new/empty collections

### Wrong Configuration
- Delete the index
- Create new one with exact fields above
- Make sure field names match exactly (case-sensitive)

### Still Getting Errors
1. Check browser console for exact error message
2. Verify index status is "Enabled" not "Building"
3. Try hard refresh (Ctrl+Shift+R)
4. Check that Firestore rules are deployed

## Expected Result

After creating the index, the Weekly Plan tab should:
- ✅ Load without errors
- ✅ Display current week
- ✅ Allow navigation between weeks
- ✅ Filter plans correctly by week
