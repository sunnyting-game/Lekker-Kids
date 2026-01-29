# Firebase Storage Rules Setup Guide

## Issue
Photos are not uploading to Firebase Storage. This is likely due to missing or incorrect Firebase Storage security rules.

## Solution
Add Firebase Storage rules to allow teachers to upload photos.

## Steps to Add Storage Rules

### 1. Open Firebase Console
- Go to https://console.firebase.google.com/
- Select your project

### 2. Navigate to Storage Rules
- Click **Storage** in the left sidebar
- Click **Rules** tab at the top

### 3. Add the Following Rules

Replace the existing rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to get user role from Firestore
    function getUserRole() {
      return firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role;
    }
    
    // Helper function to check if user is teacher
    function isTeacher() {
      return isAuthenticated() && getUserRole() == 'teacher';
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() && getUserRole() == 'admin';
    }
    
    // Student photos
    match /student_photos/{studentId}/{date}/{filename} {
      // Allow teachers to upload (write)
      allow write: if isTeacher() || isAdmin();
      
      // Allow teachers and admins to read
      allow read: if isTeacher() || isAdmin();
    }
    
    // Default deny all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 4. Publish Rules
- Click **Publish** button
- Wait for confirmation message

## Testing After Deployment

1. **Check Console Logs**
   - Open browser DevTools (F12)
   - Go to Console tab
   - Try uploading a photo
   - Look for the debug messages:
     ```
     📸 Starting photo upload for student: ...
     🗜️ Compressing image...
     ✅ Image compressed
     📏 Compressed file size: ... KB
     ☁️ Uploading to Storage: ...
     ✅ Upload to Storage complete
     🔗 Download URL obtained: ...
     💾 Saving photo reference to Firestore...
     ✅ Photo reference saved to Firestore
     ```

2. **Verify Upload**
   - If you see all ✅ messages, upload succeeded
   - If you see ❌ error, check the error message
   - Common errors:
     - `permission-denied` → Storage rules not deployed
     - `network-error` → Check internet connection
     - `File size exceeds 5MB` → Image too large

3. **Check Firebase Storage**
   - Go to Firebase Console → Storage
   - Navigate to `student_photos/{studentId}/{date}/`
   - Verify photo files exist

4. **Check Firestore**
   - Go to Firebase Console → Firestore
   - Open `dailyStatus` collection
   - Find document `{studentId}_{date}`
   - Verify `photos` array contains photo data

## Troubleshooting

### Error: permission-denied
**Cause:** Storage rules not deployed or incorrect

**Solution:**
1. Verify rules are published in Firebase Console
2. Check that `getUserRole()` function can access Firestore
3. Verify user is logged in as teacher
4. Hard refresh browser (Ctrl+Shift+R)

### Error: File size exceeds 5MB
**Cause:** Image is too large even after compression

**Solution:**
1. Try a smaller image
2. Or increase limit in `PhotoService`:
   ```dart
   static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
   ```

### Photos Not Showing in Gallery
**Cause:** Firestore reference not saved

**Solution:**
1. Check console for "✅ Photo reference saved to Firestore"
2. Verify Firestore document has `photos` array
3. Check that photo count badge appears after upload

### Upload Stuck on Loading
**Cause:** Network issue or large file

**Solution:**
1. Check internet connection
2. Try smaller image
3. Check browser console for errors

## Photo Count Badge & Gallery

### Photo Count Badge
- Shows number next to camera button
- Only visible when photos exist
- Blue background with white text
- Clickable to open gallery

### Photo Gallery Popup
- Grid view of all photos (2 columns)
- Tap photo to view full size
- Pinch to zoom in full view
- Click outside or X button to close
- Shows loading indicator while loading
- Shows error icon if image fails to load

## Summary

**Required:**
- ✅ Firebase Storage rules deployed
- ✅ User logged in as teacher
- ✅ Internet connection

**Features:**
- ✅ Photo upload with compression
- ✅ Photo count badge
- ✅ Photo gallery popup
- ✅ Full-size image viewer
- ✅ Debug logging
