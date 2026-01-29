# Firebase Setup Guide

This guide will help you configure Firebase for the Daycare App.

## Prerequisites

- Flutter SDK installed
- Node.js installed (for Firebase CLI)
- A Google account

## Step 1: Install Firebase CLI

Open PowerShell and run:

```powershell
npm install -g firebase-tools
```

## Step 2: Install FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

Make sure the Dart global bin directory is in your PATH.

## Step 3: Login to Firebase

```powershell
firebase login
```

This will open a browser window for you to authenticate with your Google account.

## Step 4: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `daycare-app` (or your preferred name)
4. Disable Google Analytics (optional for this project)
5. Click "Create project"

## Step 5: Configure FlutterFire

Navigate to your project directory and run:

```powershell
cd "c:\Users\Ting\project\Lekker Kids"
flutterfire configure
```

This will:
- Prompt you to select your Firebase project
- Automatically register your Flutter app with Firebase
- Generate `lib/firebase_options.dart` with your configuration
- Create platform-specific configuration files

When prompted:
- Select the Firebase project you created
- Select platforms: **Android**, **iOS**, **Web**, **Windows** (as needed)

## Step 6: Enable Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click "Authentication" in the left sidebar
4. Click "Get started"
5. Click on "Email/Password" under Sign-in providers
6. Enable "Email/Password" (first toggle)
7. Click "Save"

## Step 7: Create Firestore Database

1. In Firebase Console, click "Firestore Database" in the left sidebar
2. Click "Create database"
3. Select "Start in **test mode**" (for development)
4. Choose a location (select closest to you)
5. Click "Enable"

## Step 8: Set Up Firestore Security Rules

In the Firestore Database console:
1. Click on "Rules" tab
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - authenticated users can read their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click "Publish"

## Step 9: Create Test Accounts

You have two options to create test accounts:

### Option A: Using Firebase Console (Recommended for initial setup)

1. Go to Firebase Console → Authentication → Users
2. Click "Add user"
3. Create three accounts:
   - **Admin**: 
     - Email: `admin@daycare.local`
     - Password: `admin123`
   - **Teacher**:
     - Email: `teacher@daycare.local`
     - Password: `teacher123`
   - **Student**:
     - Email: `student@daycare.local`
     - Password: `student123`

4. After creating each user, note their UID
5. Go to Firestore Database
6. Create a collection called `users`
7. For each user, create a document with their UID as the document ID:

**Admin document (use admin's UID as document ID):**
```json
{
  "username": "admin",
  "role": "admin",
  "createdAt": "2024-12-01T00:00:00.000Z",
  "uid": "<admin-uid>"
}
```

**Teacher document (use teacher's UID as document ID):**
```json
{
  "username": "teacher",
  "role": "teacher",
  "createdAt": "2024-12-01T00:00:00.000Z",
  "uid": "<teacher-uid>"
}
```

**Student document (use student's UID as document ID):**
```json
{
  "username": "student",
  "role": "student",
  "createdAt": "2024-12-01T00:00:00.000Z",
  "uid": "<student-uid>"
}
```

### Option B: Using the App's Create Account Function (Future)

The `AuthService` includes a `createUserAccount` method that can be called from an admin interface in future phases.

## Step 10: Test the App

Run the app:

```powershell
flutter run -d chrome
```

Or for Windows:

```powershell
flutter run -d windows
```

Try logging in with:
- Username: `admin`, Password: `admin123`
- Username: `teacher`, Password: `teacher123`
- Username: `student`, Password: `student123`

## Troubleshooting

### Firebase initialization error
- Make sure you ran `flutterfire configure`
- Check that `lib/firebase_options.dart` exists and has valid configuration

### Login fails with "user-not-found"
- Verify the user exists in Firebase Console → Authentication
- Check that the email format is correct (`username@daycare.local`)

### User data not found
- Verify the Firestore document exists in the `users` collection
- Check that the document ID matches the user's UID from Authentication
- Verify the Firestore security rules allow reading user data

### Developer Mode warning (Windows)
- This is optional for development
- To enable: Press Win+I → Privacy & Security → For developers → Developer Mode → On

## Next Steps

Once Firebase is configured and test accounts are created:
1. Test login with each account type
2. Verify role-based routing works correctly
3. Begin implementing business features in future phases
