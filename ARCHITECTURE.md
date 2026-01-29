# Lekker Kids - Daycare Management App

A Flutter-based daycare management application with Firebase backend, role-based access control, and real-time features.

## Overview

Lekker Kids is a comprehensive daycare management system with three portals:
- **Teacher Portal** - Attendance tracking, classroom management, weekly plans, photo sharing
- **Student Portal** - Home dashboard, photo album, chat with teachers, daily status
- **Admin Portal** - User management (create/edit teachers and students)

## Tech Stack

- **Frontend**: Flutter 3.35.7
- **Backend**: Firebase
  - Firebase Authentication (Email/Password)
  - Cloud Firestore (Real-time database)
  - Cloud Storage (Photo storage)
  - Cloud Functions (Scheduled tasks, admin operations)
- **Architecture**: MVVM (Model-View-ViewModel)
- **State Management**: Provider

## Features

### Teacher Portal
- **Attendance Tab** - Track student check-in/check-out/absent status
- **Classroom Tab** - View all students with real-time status display
- **Weekly Plan Tab** - Create and manage weekly activity plans
- **Photo Upload** - Send photos to individual students

### Student Portal
- **Home Tab** - Daily status banner, today's photos gallery
- **Album Tab** - Photo gallery organized by date (14-day retention)
- **Chat** - Real-time messaging with teachers
- **Calendar/Document Tabs** - Placeholder for future features

### Admin Portal
- **User Management** - Create, edit, and manage teacher/student accounts
- **Role Assignment** - Assign roles and classroom associations

### Cloud Functions
- `adminCreateUser` - Create user accounts (admin only)
- `adminUpdateUser` - Update user accounts (admin only)
- `cleanupOldPhotos` - Daily cleanup of photos older than 14 days
- `resetDailyDisplayStatus` - Daily reset of student status at midnight

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── constants/
│   ├── app_strings.dart         # Localized strings
│   ├── app_theme.dart           # Theme configuration
│   └── firestore_collections.dart # Collection name constants
├── models/
│   ├── user_model.dart          # User data model with role enum
│   ├── chat_message.dart        # Chat message model
│   ├── daily_status.dart        # Daily attendance status
│   ├── photo_item.dart          # Photo metadata model
│   ├── today_display_status.dart # Student display status
│   └── weekly_plan.dart         # Weekly plan model
├── services/
│   ├── auth_service.dart        # Authentication service
│   ├── chat_service.dart        # Chat messaging service
│   ├── cloud_functions_service.dart # Cloud Functions caller
│   ├── photo_service.dart       # Photo upload/retrieval
│   ├── student_service.dart     # Student data operations
│   ├── teacher_service.dart     # Teacher data operations
│   └── weekly_plan_service.dart # Weekly plan operations
├── repositories/
│   ├── student_repository.dart  # Student data repository
│   └── user_repository.dart     # User data repository
├── viewmodels/
│   ├── classroom_viewmodel.dart # Classroom state management
│   └── home_viewmodel.dart      # Home tab state management
├── providers/
│   └── auth_provider.dart       # Authentication state
├── screens/
│   ├── login_page.dart          # Login screen
│   ├── admin/                   # Admin portal screens
│   │   ├── create_student_page.dart
│   │   ├── create_teacher_page.dart
│   │   ├── edit_user_page.dart
│   │   ├── student_page.dart
│   │   └── teacher_page.dart
│   └── portals/
│       ├── admin_portal.dart
│       ├── teacher_portal.dart
│       ├── student_portal.dart
│       ├── teacher/
│       │   ├── attendance_tab.dart
│       │   ├── classroom_tab.dart
│       │   └── weekly_plan_tab.dart
│       └── student/
│           ├── home_tab.dart
│           ├── album_tab.dart
│           ├── calendar_tab.dart
│           ├── document_tab.dart
│           ├── parent_chat_tab.dart
│           └── widgets/
├── widgets/
│   ├── chat_window.dart         # Reusable chat widget
│   ├── full_screen_image_viewer.dart
│   ├── photo_gallery_popup.dart
│   └── photo_upload_helper.dart
└── utils/
    ├── create_test_accounts.dart
    └── week_utils.dart

functions/
└── index.js                     # Cloud Functions
```

## Architecture

### MVVM Pattern

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    View     │────▶│  ViewModel  │────▶│ Repository  │
│  (Screens)  │◀────│   (State)   │◀────│  (Data)     │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
                                        ┌─────────────┐
                                        │  Services   │
                                        │ (Firebase)  │
                                        └─────────────┘
```

- **View** - UI components, consumes ViewModel streams
- **ViewModel** - Business logic, state management, exposes streams
- **Repository** - Data access layer, Firestore operations
- **Services** - Firebase SDK interactions

### Authentication Flow

```
User enters username/password
        ↓
AuthService converts to email (username@daycare.local)
        ↓
Firebase Authentication validates
        ↓
AuthService fetches user data from Firestore
        ↓
AuthProvider updates app state
        ↓
AuthWrapper routes to portal based on role
```

## Getting Started

### Prerequisites

- Flutter SDK (3.35.7 or higher)
- Dart SDK (3.9.2 or higher)
- Firebase account
- Node.js (for Firebase CLI and Cloud Functions)

### Quick Start

See [QUICKSTART.md](QUICKSTART.md) for step-by-step setup.

### Running the App

```powershell
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on Windows
flutter run -d windows

# Run on Android
flutter run -d android
```

### Deploy Cloud Functions

```powershell
cd functions
npm install
firebase deploy --only functions
```

## Documentation

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](QUICKSTART.md) | Quick setup guide |
| [FIREBASE_SETUP.md](FIREBASE_SETUP.md) | Detailed Firebase configuration |
| [CLOUD_FUNCTIONS_MIGRATION.md](CLOUD_FUNCTIONS_MIGRATION.md) | Cloud Functions guide |
| [FIRESTORE_INDEX_GUIDE.md](FIRESTORE_INDEX_GUIDE.md) | Firestore indexes |
| [FIRESTORE_RULES_DEPLOYMENT.md](FIRESTORE_RULES_DEPLOYMENT.md) | Security rules |
| [LOCALIZATION_GUIDE.md](LOCALIZATION_GUIDE.md) | Multi-language support |
| [PERFORMANCE_OPTIMIZATION.md](PERFORMANCE_OPTIMIZATION.md) | Performance tips |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues |

## Adding New Features

To add a new feature following MVVM pattern:

1. **Model** - Create data model in `lib/models/`
2. **Repository** - Add Firestore operations in `lib/repositories/`
3. **ViewModel** - Add state management in `lib/viewmodels/`
4. **View** - Create UI in `lib/screens/`
5. **Cloud Function** (if needed) - Add to `functions/index.js`

## Test Accounts

| Username | Password | Portal |
|----------|----------|--------|
| admin | admin123 | Admin Portal |
| teacher | teacher123 | Teacher Portal |
| student | student123 | Student Portal |

## Security Notes

- Usernames converted to email format (`username@daycare.local`)
- User accounts created by administrators only (no self-registration)
- Firestore security rules restrict data access by role
- Cloud Functions validate admin role before user operations

## License

Private project - All rights reserved
