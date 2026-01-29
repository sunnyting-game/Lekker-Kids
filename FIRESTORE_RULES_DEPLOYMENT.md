# Firestore Security Rules Deployment Guide

## Issue
The Attendance tab is showing a permission error:
```
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

This happens because teachers don't have permission to write to the `dailyStatus` collection in Firestore.

## Solution
Deploy the Firestore security rules to allow teachers to read/write attendance data.

## Option 1: Manual Deployment via Firebase Console (RECOMMENDED)

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com/
   - Select your project

2. **Navigate to Firestore Rules**
   - Click on "Firestore Database" in the left sidebar
   - Click on the "Rules" tab at the top

3. **Copy and Paste the Rules**
   - Copy the entire content from `firestore.rules` file
   - Paste it into the rules editor
   - Click "Publish" button

4. **Verify Deployment**
   - You should see a success message
   - The rules are now active

## Option 2: Deploy via Firebase CLI

If you want to use the CLI, you need to first configure `firebase.json`:

1. **Update firebase.json** (if it exists, or create it)
   ```json
   {
     "firestore": {
       "rules": "firestore.rules"
     },
     "functions": {
       "source": "functions"
     }
   }
   ```

2. **Deploy Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

## Testing After Deployment

1. **Refresh the app** (hot reload or full refresh)
2. **Navigate to Attendance tab**
3. **Click on a student card**
4. **Verify:**
   - No permission error in console
   - Card changes from red ✗ to green ✓
   - Status label changes from "Absent" to "Present"

## Firestore Rules Summary

The rules allow:
- ✅ **Teachers**: Read/write all `dailyStatus` documents
- ✅ **Admins**: Read/write all `dailyStatus` documents  
- ✅ **Students**: Read their own `dailyStatus` documents
- ✅ **Teachers**: Read all `users` documents (to see student list)
- ✅ **Admins**: Full access to `users` collection

## Troubleshooting

If you still see permission errors after deploying:

1. **Check the rules are published**
   - Go to Firebase Console → Firestore → Rules
   - Verify the rules match the `firestore.rules` file

2. **Check user authentication**
   - Make sure you're logged in as a teacher
   - Check the console for the user's role

3. **Clear browser cache**
   - Sometimes Firestore caches the old rules
   - Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
