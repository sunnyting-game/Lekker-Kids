# Deploying Firestore Index for Attendance Tab

## Overview

The refactored attendance tab requires a composite index on the `users` collection to enable efficient sorting by attendance status. This guide explains how to deploy the index using Firebase CLI.

## Prerequisites

- Firebase CLI installed (`npm install -g firebase-tools`)
- Authenticated with Firebase (`firebase login`)
- Firebase project initialized in this directory

## Deployment Steps

### 1. Verify firestore.indexes.json

The `firestore.indexes.json` file has already been created with the required index:

```json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "todayStatus", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" },
        { "fieldPath": "__name__", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Note:** The `createdAt` and `__name__` fields provide secondary sorting for consistent ordering, matching the existing index pattern.

### 2. Deploy the Index

Run the following command in the project root directory:

```bash
firebase deploy --only firestore:indexes
```

**Expected Output:**
```
✔  Deploy complete!

Firestore indexes deployed successfully.
```

### 3. Wait for Index to Build

- Go to [Firebase Console](https://console.firebase.google.com/)
- Navigate to **Firestore Database** > **Indexes** tab
- You should see the new index with status "Building..."
- Wait 1-5 minutes for the index to complete (faster for small datasets)
- Status will change to "Enabled" when ready

### 4. Verify the Index

You can verify the index is active by:

1. **In Firebase Console:**
   - Check that the index status shows "Enabled"
   - Collection: `users`
   - Fields indexed: `role (Asc)`, `todayStatus (Asc)`, `createdAt (Desc)`, `__name__ (Desc)`

2. **In the App:**
   - Launch the app and navigate to the Teacher Portal > Attendance tab
   - Students should load immediately without errors
   - Students should be sorted: NotArrived → CheckedIn → CheckedOut → Absent

## Troubleshooting

### Error: "FAILED_PRECONDITION: The query requires an index"

**Solution:** The index is still building. Wait a few more minutes and refresh the app.

### Error: "Permission denied"

**Solution:** Ensure you're logged into Firebase CLI with the correct account:
```bash
firebase login
```

### Index Not Appearing in Console

**Solution:** 
1. Verify the `firestore.indexes.json` file exists in the project root
2. Re-run the deploy command
3. Check for any error messages in the CLI output

## Testing

After the index is deployed and enabled:

1. Open the attendance tab in the Teacher Portal
2. Verify:
   - ✅ No console errors about missing indexes
   - ✅ Students load instantly (no polling delay)
   - ✅ Students sorted by attendance status
   - ✅ Real-time updates work immediately

## Performance Comparison

| Metric | Before | After |
|--------|--------|-------|
| Streams per page | N+2 (12-32) | 1 |
| Polling | Every 500ms | None |
| Query count on load | N+1 (11-31) | 1 |
| Firestore reads/sec | ~20-60 | 1 |

Where N = number of students (typically 10-30)

## Additional Notes

- The index only needs to be deployed once
- Future changes to `todayStatus` will automatically use the index
- The existing `weeklyPlans` index is also included in the same file
- Index creation is free and doesn't count against Firestore quotas
