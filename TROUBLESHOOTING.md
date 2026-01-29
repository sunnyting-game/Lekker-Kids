# Login Troubleshooting Guide

## Issue: Login Fails Silently or Shows "Invalid Credential" Error

### Recent Updates

I've added comprehensive debug logging and improved error handling to help diagnose login issues. The app will now:

1. **Show clear error messages** in a red snackbar for 5 seconds
2. **Print debug information** to the console/logcat
3. **Handle the 'invalid-credential' error** from Firebase Auth

### Debug Information

When you attempt to login, you should see debug output like this in your console/logcat:

```
DEBUG LoginPage: Login button pressed
DEBUG LoginPage: Username: admin
DEBUG AuthProvider: Starting sign in for username: admin
DEBUG: Attempting to sign in with email: admin@daycare.local
DEBUG: FirebaseAuthException - Code: invalid-credential, Message: ...
DEBUG: Handling auth exception - Code: invalid-credential
DEBUG AuthProvider: Sign in failed with error: Invalid username or password
DEBUG LoginPage: Login result: false
DEBUG LoginPage: Error message: Invalid username or password
DEBUG LoginPage: Showing error snackbar: Invalid username or password
```

### Common Causes & Solutions

#### 1. **User Account Not Created in Firebase Authentication**

**Symptom**: Error code `invalid-credential` or `user-not-found`

**Solution**: 
- Go to [Firebase Console](https://console.firebase.google.com/)
- Navigate to Authentication → Users
- Verify the user exists with email format: `username@daycare.local`
- If not, create the user:
  - Email: `admin@daycare.local`
  - Password: `admin123`

#### 2. **User Data Not in Firestore**

**Symptom**: Login succeeds but app doesn't navigate to portal

**Solution**:
- Go to Firebase Console → Firestore Database
- Check if `users` collection exists
- Verify there's a document with the user's UID containing:
  ```json
  {
    "username": "admin",
    "role": "admin",
    "createdAt": "2024-12-01T00:00:00.000Z",
    "uid": "<user-uid>"
  }
  ```

#### 3. **Incorrect Password**

**Symptom**: Error message "Invalid username or password"

**Solution**:
- Verify you're using the correct password
- If you forgot the password, reset it in Firebase Console → Authentication → Users → Click on user → Reset password

#### 4. **Firebase Configuration Issue**

**Symptom**: App crashes or shows Firebase initialization error

**Solution**:
- Verify you ran `flutterfire configure`
- Check that `lib/firebase_options.dart` has real values (not placeholders)
- Ensure Firebase project is properly set up

### Step-by-Step Verification

Run through these steps to verify your setup:

#### Step 1: Check Firebase Authentication

```powershell
# Open Firebase Console
start https://console.firebase.google.com/
```

1. Select your project
2. Go to Authentication → Users
3. Verify these users exist:
   - `admin@daycare.local`
   - `teacher@daycare.local`
   - `student@daycare.local`

#### Step 2: Check Firestore Database

1. Go to Firestore Database
2. Open `users` collection
3. Verify there are 3 documents (one for each user)
4. Each document should have:
   - Document ID = User's UID from Authentication
   - Fields: `username`, `role`, `createdAt`, `uid`

#### Step 3: Test Login with Debug Output

1. Run the app:
   ```powershell
   flutter run -d chrome
   # or
   flutter run -d android
   ```

2. Watch the console output
3. Try logging in with `admin` / `admin123`
4. Look for the debug messages

### Creating Test Accounts Correctly

If you need to create accounts from scratch:

#### Method 1: Firebase Console (Recommended)

1. **Create in Authentication**:
   - Firebase Console → Authentication → Users → Add user
   - Email: `admin@daycare.local`
   - Password: `admin123`
   - Note the UID that's generated

2. **Create in Firestore**:
   - Firestore Database → Start collection → Collection ID: `users`
   - Document ID: [paste the UID from step 1]
   - Fields:
     ```
     username: admin (string)
     role: admin (string)
     createdAt: 2024-12-01T00:00:00.000Z (string)
     uid: [paste the UID] (string)
     ```

Repeat for `teacher` and `student`.

#### Method 2: Using the Helper Script

1. Temporarily modify `lib/main.dart`:
   ```dart
   // Comment out the normal import
   // import 'main.dart';
   
   // Add this import instead
   import 'utils/create_test_accounts.dart' as create_accounts;
   
   void main() async {
     // Call the create accounts main instead
     create_accounts.main();
   }
   ```

2. Run the app once:
   ```powershell
   flutter run -d chrome
   ```

3. The script will create all three accounts

4. Revert `lib/main.dart` back to normal

### Firestore Security Rules

Make sure your Firestore rules allow reading user data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Still Having Issues?

If you're still experiencing problems:

1. **Check the debug output** - The console will show exactly what's happening
2. **Verify Firebase project** - Make sure you're using the correct Firebase project
3. **Check internet connection** - Firebase requires network access
4. **Try a different platform** - Test on web first (easier to debug)

### Expected Behavior

When login is successful, you should see:

1. Loading spinner appears on the login button
2. Debug messages in console showing successful authentication
3. Automatic navigation to the appropriate portal (Admin/Teacher/Student)
4. Welcome message with your username

When login fails, you should see:

1. Loading spinner appears briefly
2. Red snackbar at the bottom with error message
3. Error message stays visible for 5 seconds
4. Debug messages in console showing the error

---

**Updated**: 2024-12-01 - Added comprehensive debug logging and improved error handling
