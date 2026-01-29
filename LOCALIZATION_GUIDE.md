# Localization and Theming Guide

## Overview

The app has been refactored to follow best practices by separating all UI strings, colors, spacing, and styles into centralized constant files. This makes the app easier to maintain, translate, and theme.

## Architecture

### 📁 File Structure

```
lib/
├── constants/
│   ├── app_strings.dart    # All UI text and error messages
│   └── app_theme.dart      # Colors, spacing, text styles, durations
├── screens/
│   ├── login_page.dart     # Uses AppStrings & AppTheme
│   └── portals/
│       ├── teacher_portal.dart
│       ├── admin_portal.dart
│       └── student_portal.dart
├── services/
│   └── auth_service.dart   # Uses AppStrings for errors
└── main.dart               # Uses AppTheme for app theme
```

## Localization (app_strings.dart)

### Purpose
Centralizes all user-facing text in one file for easy translation and maintenance.

### Usage

**❌ Before (Hardcoded):**
```dart
Text('Welcome Back')
```

**✅ After (Localized):**
```dart
Text(AppStrings.loginWelcome)
```

### String Categories

#### 1. App Info
- `appName` - Application name

#### 2. Login Page
- `loginWelcome` - Welcome message
- `loginUsername` - Username label
- `loginPassword` - Password label
- `loginButton` - Login button text
- `loginUsernameRequired` - Validation message
- `loginPasswordRequired` - Validation message
- `loginErrorDismiss` - Dismiss button text

#### 3. Portal Screens
- `teacherPortalTitle` / `adminPortalTitle` / `studentPortalTitle`
- `portalSignOut` - Sign out tooltip
- `portalInfoMessage` - Info message template
- `portalFutureFeatures` - Future features message

#### 4. Error Messages
- `errorInvalidCredentials` - Wrong username/password
- `errorInvalidUsername` - Invalid format
- `errorAccountDisabled` - Account disabled
- `errorTooManyRequests` - Rate limited
- `errorNetworkFailed` - Network error
- `errorUserNotConfigured` - Missing Firestore document
- And more...

### String Formatting

For dynamic strings with placeholders:

```dart
// String with placeholder
static const String welcomeMessage = 'Welcome, {0}!';

// Usage
Text(AppStrings.format(AppStrings.welcomeMessage, ['John']))
// Output: "Welcome, John!"
```

## Theming (app_theme.dart)

### Purpose
Centralizes all visual styling constants for consistent UI and easy theme changes.

### Components

#### 1. AppColors

**Color Palette:**
```dart
AppColors.primary          // Primary blue
AppColors.primaryDark      // Darker blue
AppColors.primaryLight     // Light blue
AppColors.error            // Error red
AppColors.errorLight       // Light red background
AppColors.errorBorder      // Red border
AppColors.errorDark        // Dark red text
AppColors.textPrimary      // Black text
AppColors.textSecondary    // Gray text
AppColors.textWhite        // White text
AppColors.iconPrimary      // Primary icon color
AppColors.iconError        // Error icon color
```

**Usage:**
```dart
// ❌ Before
color: Colors.red

// ✅ After
color: AppColors.error
```

#### 2. AppSpacing

**Spacing Values:**
```dart
// Padding
AppSpacing.paddingXSmall    // 4.0
AppSpacing.paddingSmall     // 8.0
AppSpacing.paddingMedium    // 12.0
AppSpacing.paddingLarge     // 16.0
AppSpacing.paddingXLarge    // 24.0
AppSpacing.paddingXXLarge   // 32.0
AppSpacing.paddingHuge      // 48.0

// Margins
AppSpacing.marginSmall      // 8.0
AppSpacing.marginMedium     // 16.0
AppSpacing.marginLarge      // 24.0

// Border Radius
AppSpacing.radiusSmall      // 8.0
AppSpacing.radiusMedium     // 12.0
AppSpacing.radiusLarge      // 16.0

// Icon Sizes
AppSpacing.iconSmall        // 20.0
AppSpacing.iconMedium       // 48.0
AppSpacing.iconLarge        // 80.0
AppSpacing.iconXLarge       // 100.0

// Loading Indicator
AppSpacing.loadingIndicatorSize    // 20.0
AppSpacing.loadingIndicatorStroke  // 2.0
```

**Usage:**
```dart
// ❌ Before
padding: const EdgeInsets.all(24.0)
borderRadius: BorderRadius.circular(12)

// ✅ After
padding: const EdgeInsets.all(AppSpacing.paddingXLarge)
borderRadius: BorderRadius.circular(AppSpacing.radiusMedium)
```

#### 3. AppTextStyles

**Text Style Presets:**
```dart
AppTextStyles.headlineMedium   // Large bold headlines
AppTextStyles.headlineSmall    // Medium bold headlines
AppTextStyles.titleLarge       // Large titles
AppTextStyles.titleMedium      // Medium titles
AppTextStyles.bodyLarge        // Large body text
AppTextStyles.bodyMedium       // Medium body text
AppTextStyles.button           // Button text
AppTextStyles.error            // Error messages
```

**Usage:**
```dart
// ❌ Before
Text(
  'Welcome',
  style: TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ),
)

// ✅ After
Text(
  AppStrings.loginWelcome,
  style: AppTextStyles.headlineMedium,
)
```

#### 4. AppDurations

**Animation & Timing:**
```dart
AppDurations.snackBarDuration    // 5 seconds
AppDurations.shortAnimation      // 200ms
AppDurations.mediumAnimation     // 300ms
```

**Usage:**
```dart
// ❌ Before
duration: const Duration(seconds: 5)

// ✅ After
duration: AppDurations.snackBarDuration
```

## Benefits

### 1. **Easy Localization**
- All strings in one file
- Simple to add new languages
- No need to search through code for text

### 2. **Consistent Theming**
- All colors defined once
- Easy to change app-wide theme
- Consistent spacing throughout app

### 3. **Maintainability**
- Single source of truth
- Easy to update values
- No magic numbers in code

### 4. **Scalability**
- Easy to add new strings/colors
- Simple to create theme variants
- Ready for multi-language support

## Adding New Content

### Adding a New String

1. Open `lib/constants/app_strings.dart`
2. Add your string constant:
   ```dart
   static const String myNewString = 'My Text';
   ```
3. Use it in your widget:
   ```dart
   Text(AppStrings.myNewString)
   ```

### Adding a New Color

1. Open `lib/constants/app_theme.dart`
2. Add to `AppColors` class:
   ```dart
   static const Color myColor = Color(0xFF123456);
   ```
3. Use it in your widget:
   ```dart
   color: AppColors.myColor
   ```

### Adding a New Text Style

1. Open `lib/constants/app_theme.dart`
2. Add to `AppTextStyles` class:
   ```dart
   static const TextStyle myStyle = TextStyle(
     fontSize: 18.0,
     fontWeight: FontWeight.w600,
     color: AppColors.textPrimary,
   );
   ```
3. Use it in your widget:
   ```dart
   Text('Hello', style: AppTextStyles.myStyle)
   ```

## Future Enhancements

### Multi-Language Support

To add multiple languages:

1. Create language-specific files:
   ```
   lib/constants/
   ├── app_strings_en.dart  # English
   ├── app_strings_zh.dart  # Chinese
   └── app_strings.dart     # Current language selector
   ```

2. Use Flutter's built-in localization:
   ```dart
   // Add to pubspec.yaml
   dependencies:
     flutter_localizations:
       sdk: flutter
   ```

3. Implement locale switching based on user preference

### Dark Mode Support

To add dark mode:

1. Create `AppColorsDark` in `app_theme.dart`:
   ```dart
   class AppColorsDark {
     static const Color primary = Color(0xFF90CAF9);
     static const Color background = Color(0xFF121212);
     // ... dark mode colors
   }
   ```

2. Switch colors based on theme mode:
   ```dart
   final isDark = Theme.of(context).brightness == Brightness.dark;
   color: isDark ? AppColorsDark.primary : AppColors.primary
   ```

## Best Practices

### ✅ DO

- Use constants for all user-facing text
- Use constants for all colors
- Use constants for all spacing values
- Use predefined text styles
- Group related constants together

### ❌ DON'T

- Hardcode strings in widgets
- Use literal color values
- Use magic numbers for spacing
- Create inline text styles
- Duplicate constant definitions

## Summary

✅ **All strings** → `app_strings.dart`  
✅ **All colors** → `AppColors` in `app_theme.dart`  
✅ **All spacing** → `AppSpacing` in `app_theme.dart`  
✅ **All text styles** → `AppTextStyles` in `app_theme.dart`  
✅ **All durations** → `AppDurations` in `app_theme.dart`  

The app is now fully refactored for easy maintenance, localization, and theming! 🎨
