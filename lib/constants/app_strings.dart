class AppStrings {
  // ==========================================================================
  // TERMINOLOGY MAPPING
  // ==========================================================================
  // This app uses a multi-tenant architecture with the following hierarchy:
  //
  // CODE TERM      →  UI/BUSINESS TERM
  // ─────────────────────────────────────
  // Organization   →  Organization (parent entity managing multiple sites)
  // School         →  School (individual childcare site)
  // SchoolId       →  SchoolId (internal identifier)
  //
  // In code: Use "School" classes (SchoolModel, SchoolRepository, etc.)
  // In UI strings: Use "School" for user-facing text
  // ==========================================================================

  // Entity Display Names (for UI)
  static const String dayhomeSingular = 'School';
  static const String dayhomePlural = 'Schools';
  static const String organizationSingular = 'Organization';
  static const String organizationPlural = 'Organizations';

  // App Info
  static const String appName = 'Daycare App';
  
  // Login Page
  static const String loginWelcome = 'Welcome Back';
  static const String loginUsername = 'Username';
  static const String loginPassword = 'Password';
  static const String loginButton = 'Login';
  static const String loginUsernameRequired = 'Please enter your username';
  static const String loginPasswordRequired = 'Please enter your password';
  static const String loginErrorDismiss = 'Dismiss';
  
  // Portal Common
  static const String portalSignOut = 'Sign Out';
  static const String portalInfoMessage = 'This is the {0} portal shell.';
  static const String portalFutureFeatures = 'Features will be added in future phases.';
  
  // Portal Titles
  static const String teacherPortalTitle = 'Teacher Portal';
  static const String adminPortalTitle = 'Admin Portal';
  static const String studentPortalTitle = 'Student Portal';
  
  // Portal Welcome
  static const String welcomeMessage = 'Welcome, {0}!';
  static const String teacherWelcome = 'Teacher';
  static const String adminWelcome = 'Admin';
  static const String studentWelcome = 'Student';
  
  // Phase 2: Admin Account Management
  static const String adminManageTeacher = 'Manage Teacher';
  static const String adminManageStudent = 'Manage Student';
  static const String adminTeacherPageTitle = 'Manage Teachers';
  static const String adminStudentPageTitle = 'Manage Students';
  static const String adminAddTeacher = 'Add Teacher';
  static const String adminAddStudent = 'Add Student';
  static const String adminCreateTeacherTitle = 'Create Teacher Account';
  static const String adminCreateStudentTitle = 'Create Student Account';
  static const String adminTeacherListPlaceholder = 'Teacher list will be displayed here';
  static const String adminStudentListPlaceholder = 'Student list will be displayed here';
  static const String adminCreateButton = 'Create {0}';
  static const String adminUsernameLabel = 'Username';
  static const String adminPasswordLabel = 'Password';
  static const String adminNameLabel = 'Name';
  static const String adminUsernameRequired = 'Please enter username';
  static const String adminPasswordRequired = 'Please enter password';
  static const String adminNameRequired = 'Please enter name';
  static const String adminAccountCreated = '{0} account created successfully';
  static const String adminAccountCreationFailed = 'Failed to create {0} account: {1}';
  static const String adminCreating = 'Creating {0} account...';
  
  // Teacher Portal Navigation
  static const String teacherNavClassroom = 'Classroom';
  static const String teacherNavAttendance = 'Attendance';
  static const String teacherNavWeeklyPlan = 'Weekly Plan';
  static const String teacherNavDocuments = 'Documents';
  static const String teacherNavChat = 'Chat';
  
  // Student Portal Navigation
  static const String studentNavHome = 'Home';
  static const String studentNavCalendar = 'Calendar';
  static const String studentNavParentChat = 'Chat';
  static const String studentNavDocument = 'Document';
  static const String studentNavAlbum = 'Album';
  
  // Chat Feature
  static const String chatWindowTitle = 'Chat';
  static const String chatInputHint = 'Type a message...';
  static const String chatSendButton = 'Send';
  static const String chatEmptyMessage = 'No messages yet. Start a conversation!';
  static const String chatSelectTeacher = 'Select a teacher to chat';
  static const String chatNoTeachers = 'No teachers available';
  
  // Student Portal Home Page
  static const String studentHomeMealLabel = 'Meal';
  static const String studentHomeToiletLabel = 'Toilet';
  static const String studentHomeSleepLabel = 'Sleep';
  static const String studentHomeMealEmoji = '🍚';
  static const String studentHomeToiletEmoji = '🚽';
  static const String studentHomeSleepEmoji = '💤';
  static const String studentHomePhotoGalleryTitle = "Today's Photos";
  static const String studentHomePhotoPlaceholder = 'Photo gallery coming soon';
  
  // Album Tab
  static const String albumTodayPhotosTitle = "Today's Photos";
  static const String albumSectionTitle = 'Album';
  static const String albumNoPhotosToday = 'No photos today';
  static const String albumNoPhotos = 'No photos in the past 2 weeks';
  static const String albumToday = 'Today';
  static const String albumYesterday = 'Yesterday';
  static const String albumPhotoCount = '{0} photo(s)';
  static const String albumLoadingPhotos = 'Loading photos...';
  
  // Classroom Tab
  static const String classroomTitle = 'Classroom';
  static const String classroomNoStudents = 'No students found';
  static const String classroomMealEmoji = '🍽️';
  static const String classroomToiletEmoji = '🚽';
  static const String classroomSleepEmoji = '😴';
  static const String classroomMealLabel = 'Meal';
  static const String classroomToiletLabel = 'Toilet';
  static const String classroomSleepLabel = 'Sleep';
  static const String classroomAbsentLabel = 'Absent';
  
  // Camera Feature
  static const String cameraSelectSource = 'Select Photo Source';
  static const String cameraFromGallery = 'Upload from Gallery';
  static const String cameraFromCamera = 'Take Photo';
  static const String cameraPreviewTitle = 'Photo Preview';
  static const String cameraConfirmUpload = 'Confirm & Upload';
  static const String cameraRetake = 'Retake';
  static const String cameraCancel = 'Cancel';
  static const String cameraUploading = 'Uploading photo...';
  static const String cameraUploadSuccess = 'Photo uploaded successfully';
  static const String cameraUploadError = 'Failed to upload photo';
  static const String cameraFileSizeError = 'File size exceeds 5MB limit';
  static const String cameraPermissionError = 'Camera/Gallery permission denied';
  static const String cameraNoPhotoSelected = 'No photo selected';
  
  // Attendance Tab
  static const String attendanceTitle = 'Attendance';
  static const String attendanceNoStudents = 'No students found';
  static const String attendancePresent = 'Present';
  static const String attendanceAbsent = 'Absent';
  static const String attendancePresentIcon = '✓';
  static const String attendanceAbsentIcon = '✗';
  static const String attendanceCheckIn = 'Check-in';
  static const String attendanceCheckOut = 'Check-out';
  static const String attendanceMarkAbsent = 'Absent';
  static const String attendanceNotArrived = 'Not Arrived';
  static const String attendanceCheckedIn = 'Checked In';
  static const String attendanceCheckedOut = 'Checked Out';
  
  // Weekly Plan Tab
  static const String weeklyPlanTitle = 'Weekly Plan';
  static const String weeklyPlanMonday = 'Monday';
  static const String weeklyPlanTuesday = 'Tuesday';
  static const String weeklyPlanWednesday = 'Wednesday';
  static const String weeklyPlanThursday = 'Thursday';
  static const String weeklyPlanFriday = 'Friday';
  static const String weeklyPlanAddButton = 'Add Plan';
  static const String weeklyPlanDialogTitle = 'Add New Plan';
  static const String weeklyPlanTitleLabel = 'Title';
  static const String weeklyPlanTitleHint = 'Enter plan title';
  static const String weeklyPlanDescriptionLabel = 'Description';
  static const String weeklyPlanDescriptionHint = 'Enter description (optional)';
  static const String weeklyPlanDateLabel = 'Day';
  static const String weeklyPlanSelectDay = 'Select a day';
  static const String weeklyPlanSaveButton = 'Save';
  static const String weeklyPlanCancelButton = 'Cancel';
  static const String weeklyPlanTitleRequired = 'Title is required';
  static const String weeklyPlanDayRequired = 'Please select a day';
  static const String weeklyPlanNoPlans = 'No plans';
  static const String weeklyPlanWeekFormat = 'Week {0}, {1}'; // Week X, YYYY
  static const String weeklyPlanPreviousWeek = 'Previous Week';
  static const String weeklyPlanNextWeek = 'Next Week';
  
  // Error Messages
  static const String errorInvalidCredentials = 'Invalid username or password';
  static const String errorInvalidUsername = 'Invalid username format';
  static const String errorAccountDisabled = 'This account has been disabled';
  static const String errorTooManyRequests = 'Too many failed attempts. Please try again later';
  static const String errorNetworkFailed = 'Network error. Please check your connection';
  static const String errorLoginFailed = 'Login failed: {0}';
  static const String errorUserNotConfigured = 'User account not properly configured. Please contact administrator.';
  static const String errorLoadUserData = 'Failed to load user data: {0}';
  static const String errorUnexpected = 'An unexpected error occurred. Please try again.';
  static const String errorGeneric = 'Login failed';
  
  // Helper method to replace placeholders
  static String format(String template, List<String> args) {
    String result = template;
    for (int i = 0; i < args.length; i++) {
      result = result.replaceAll('{$i}', args[i]);
    }
    return result;
  }
  // Super Admin Portal
  static const String superAdminTitle = 'Super Admin Portal';
  static const String superAdminAccessDenied = 'Access denied. Super Admin only.';
  static const String superAdminAccessDeniedTitle = 'Access Denied';
  static const String superAdminTotal = 'Total';
  static const String superAdminActive = 'Active';
  static const String superAdminTrial = 'Trial';
  static const String superAdminSuspended = 'Suspended';
  static const String superAdminCreateSchool = 'Create School';
  static const String superAdminCreateSchoolTitle = 'Create New School';
  static const String superAdminSchoolName = 'School Name';
  static const String superAdminSchoolNameHint = 'e.g., Sunny Dale Daycare';
  static const String superAdminAdminEmail = 'Admin Email';
  static const String superAdminAdminEmailHint = 'admin@example.com';
  static const String superAdminCreate = 'Create';
  static const String superAdminCancel = 'Cancel';
  static const String superAdminDeleting = 'Delete School';
  static const String superAdminDeleteConfirmTitle = 'Delete School';
  static const String superAdminDeleteConfirmContent = 'Are you sure you want to delete "{0}"?\n\nThis action cannot be undone.';
  static const String superAdminDeleteButton = 'Delete';
  static const String superAdminSchoolDeleted = 'School "{0}" deleted';
  static const String superAdminSchoolCreated = 'School "{0}" created!';
  static const String superAdminSubscriptionUpdated = 'Subscription updated to {0}';
  static const String superAdminSubscriptionUpdateFailed = 'Failed to update subscription: {0}';
  static const String superAdminStudentsRegistered = 'Students registered';
  static const String superAdminStorageUsage = 'Storage usage';
  static const String superAdminSubscriptionStatus = 'Subscription Status';
  static const String superAdminActions = 'Actions';
  static const String superAdminID = 'ID: {0}';
  static const String superAdminNoSchools = 'No schools yet';
  static const String superAdminNoSchoolsHint = 'Create your first school to get started';
  static const String superAdminErrorCreate = 'Failed to create school';
  static const String superAdminEnterSchoolName = 'Please enter a school name';
  static const String superAdminEnterAdminEmail = 'Please enter admin email';
  static const String superAdminEnterValidEmail = 'Please enter a valid email';

  // School Placement Dialog
  static const String schoolPlacementTitle = 'Manage Placement';
  static const String schoolPlacementTeachersTab = 'Teachers';
  static const String schoolPlacementStudentsTab = 'Students';
  static const String schoolPlacementSaveButton = 'Save';
  static const String schoolPlacementCancelButton = 'Cancel';
  static const String schoolPlacementNoTeachersInOrg = 'No teachers in this organization yet';
  static const String schoolPlacementNoStudentsInOrg = 'No students in this organization yet';
  static const String schoolPlacementSaved = 'Placement updated successfully';
  static const String schoolPlacementFailed = 'Failed to update placement: {0}';

  // Checklist Feature
  static const String teacherNavChecklist = 'Checklist';
  static const String checklistNoTemplate = 'No checklist template';
  static const String checklistContactAdmin = 'Please contact your admin to set up a checklist template';
  static const String checklistCompleted = 'Completed';
  static const String checklistSubmitted = 'Submitted';
  static const String checklistDialogTitle = 'Daily Checklist';
  static const String checklistReadOnly = 'Read Only';
  static const String checklistAllCompleted = 'All items completed!';
  static const String checklistSave = 'Save';
  static const String checklistCancel = 'Cancel';
  static const String checklistClose = 'Close';
  static const String checklistSaved = 'Checklist saved';
  static const String checklistSaveError = 'Failed to save checklist';

  // Admin Checklist Management
  static const String checklistManagement = 'Checklist Management';
  static const String checklistTemplateTab = 'Template';
  static const String checklistRecordsTab = 'Records';
  static const String checklistNoItems = 'No checklist items';
  static const String checklistAddItem = 'Add Item';
  static const String checklistEditItem = 'Edit Item';
  static const String checklistItemLabel = 'Item Label';
  static const String checklistItemHint = 'e.g., Checked fire extinguisher';
  static const String checklistSaveTemplate = 'Save Template';
  static const String checklistTemplateSaved = 'Template saved successfully';
  static const String checklistSelectMonth = 'Select Month:';
  static const String checklistNoRecords = 'No submitted records for this month';
  static const String checklistItemsCompleted = 'items completed';
  static const String checklistIncomplete = 'Incomplete';
  
  // Multi-template checklist
  static const String checklistNoTemplates = 'No checklists created yet';
  static const String checklistItems = 'items';
  static const String checklistDelete = 'Delete';
  static const String checklistDeleted = 'Checklist deleted:';
  static const String checklistDeleteConfirmTitle = 'Delete Checklist';
  static const String checklistDeleteConfirm = 'Are you sure you want to delete';
  static const String checklistCreateNew = 'Create New Checklist';
  static const String checklistEditTemplate = 'Edit Checklist';
  static const String checklistNameLabel = 'Checklist Name';
  static const String checklistNameHint = 'e.g., Daily Safety Checklist';
  static const String checklistNameRequired = 'Please enter a checklist name';
  static const String checklistNeedItems = 'Please add at least one item';
  static const String checklistCreateButton = 'Create';
  static const String checklistTemplateCreated = 'Checklist created successfully';
  static const String checklistSelectTemplate = 'Checklist:';
  static const String checklistAllDone = 'All Done';
}
