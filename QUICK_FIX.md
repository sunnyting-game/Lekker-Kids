# Quick Fix: Create Firestore User Document

## Problem
You successfully authenticated with Firebase Auth, but the user document doesn't exist in Firestore.

**Your UID**: `BZHxyUCC73Rqt96ShvBRNoFaKkO2`

## Solution

### Option 1: Firebase Console (Fastest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Firestore Database** in the left sidebar
4. Click **Start collection** (if no collections exist) or click the **+** button
5. Collection ID: `users`
6. Click **Next**
7. Document ID: `BZHxyUCC73Rqt96ShvBRNoFaKkO2` (paste your UID)
8. Add these fields:

   | Field | Type | Value |
   |-------|------|-------|
   | username | string | admin |
   | role | string | admin |
   | uid | string | BZHxyUCC73Rqt96ShvBRNoFaKkO2 |
   | createdAt | string | 2024-12-01T00:00:00.000Z |

9. Click **Save**

### Option 2: Copy-Paste JSON (If using Firestore emulator or import)

```json
{
  "username": "admin",
  "role": "admin",
  "uid": "BZHxyUCC73Rqt96ShvBRNoFaKkO2",
  "createdAt": "2024-12-01T00:00:00.000Z"
}
```

## After Creating the Document

1. **Hot restart the app** (press `r` in the terminal, or stop and run again)
2. **Try logging in** with `admin` / `admin123`
3. **You should now see** the Admin Portal!

## For Teacher and Student Accounts

You'll need to:
1. Create the accounts in Firebase Authentication (if not already done)
2. Note their UIDs
3. Create Firestore documents for each with the same structure

**Teacher document**:
```
Document ID: [teacher's UID]
Fields:
  username: teacher
  role: teacher
  uid: [teacher's UID]
  createdAt: 2024-12-01T00:00:00.000Z
```

**Student document**:
```
Document ID: [student's UID]
Fields:
  username: student
  role: student
  uid: [student's UID]
  createdAt: 2024-12-01T00:00:00.000Z
```

## Why This Happened

The Firebase Authentication and Firestore are separate services:
- **Firebase Auth**: Stores login credentials (email/password)
- **Firestore**: Stores user profile data (username, role, etc.)

When you created the account in Firebase Console, it only created the Auth record, not the Firestore document. Both are needed for the app to work.

## Prevention

In the future, use the `createUserAccount` method in `AuthService` which creates both the Auth record AND the Firestore document automatically.
