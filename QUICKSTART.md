# Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Configure Firebase (Required)

```powershell
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure your project
cd "c:\Users\Ting\project\Lekker Kids"
flutterfire configure
```

Follow the prompts to select/create your Firebase project.

### Step 2: Set Up Firebase Services

1. **Enable Authentication**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Authentication → Get Started
   - Enable "Email/Password"

2. **Create Firestore Database**:
   - Firestore Database → Create Database
   - Start in test mode
   - Choose a location

3. **Create Test Accounts**:
   
   In Firebase Console → Authentication → Users, add:
   
   | Email | Password | Role |
   |-------|----------|------|
   | admin@daycare.local | admin123 | (see below) |
   | teacher@daycare.local | teacher123 | (see below) |
   | student@daycare.local | student123 | (see below) |
   
   Then in Firestore Database → users collection, create documents:
   
   **Document ID: [admin's UID]**
   ```json
   {
     "username": "admin",
     "role": "admin",
     "createdAt": "2024-12-01T00:00:00.000Z",
     "uid": "[admin's UID]"
   }
   ```
   
   **Document ID: [teacher's UID]**
   ```json
   {
     "username": "teacher",
     "role": "teacher",
     "createdAt": "2024-12-01T00:00:00.000Z",
     "uid": "[teacher's UID]"
   }
   ```
   
   **Document ID: [student's UID]**
   ```json
   {
     "username": "student",
     "role": "student",
     "createdAt": "2024-12-01T00:00:00.000Z",
     "uid": "[student's UID]"
   }
   ```

### Step 3: Run the App

```powershell
# For web (recommended for testing)
flutter run -d chrome

# For Windows
flutter run -d windows

# For Android (requires device/emulator)
flutter run -d android
```

## 🔐 Test Login

| Username | Password | Portal |
|----------|----------|--------|
| admin | admin123 | Admin Portal |
| teacher | teacher123 | Teacher Portal |
| student | student123 | Student Portal |

## 📚 Need More Help?

- **Detailed Setup**: See [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- **Project Info**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Troubleshooting**: See FIREBASE_SETUP.md → Troubleshooting section

## ⚡ Common Commands

```powershell
# Install dependencies
flutter pub get

# Check for issues
flutter analyze

# Run tests
flutter test

# Build for production
flutter build windows --release
flutter build apk --release
```

## 🎯 What's Next?

After completing the setup:
1. Test login with all three account types
2. Verify role-based routing works
3. Start planning Phase 2 features!

---

**Note**: Firebase configuration is required before the app will work. The placeholder `firebase_options.dart` will be replaced when you run `flutterfire configure`.
