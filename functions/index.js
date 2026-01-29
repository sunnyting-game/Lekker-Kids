const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function to create user accounts
 * Only callable by admin users
 */
exports.adminCreateUser = onCall({
  cors: true,
}, async (request) => {
  // 1. Validate authentication
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated",
    );
  }

  // 2. Validate admin role OR super admin claim
  const isSuperAdmin = request.auth.token.superAdmin === true;

  if (!isSuperAdmin) {
    // Check Firestore document for org admin role
    const callerUid = request.auth.uid;
    const callerDoc = await admin.firestore()
        .collection("users")
        .doc(callerUid)
        .get();

    const callerRole = callerDoc.data() ? callerDoc.data().role : null;
    if (callerRole !== "admin") {
      throw new HttpsError(
          "permission-denied",
          "Only admins can create users",
      );
    }
  }

  // 3. Validate input
  const {username, password, name, role, organizationId} = request.data;
  if (!username || !password || !role) {
    throw new HttpsError(
        "invalid-argument",
        "Username, password, and role are required",
    );
  }

  if (!["teacher", "student", "admin"].includes(role)) {
    throw new HttpsError(
        "invalid-argument",
        "Invalid role. Must be teacher, student, or admin",
    );
  }

  try {
    // 4. Create user in Firebase Auth
    const email = `${username.toLowerCase()}@daycare.local`;
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      disabled: false,
    });

    console.log("Created user in Auth:", userRecord.uid);

    // 5. Create user document in Firestore
    const userData = {
      uid: userRecord.uid,
      username: username,
      role: role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Add name if provided
    if (name) {
      userData.name = name;
    }

    // Add organizationId if provided (inherits from creating admin)
    if (organizationId) {
      userData.organizationId = organizationId;
    }

    await admin.firestore()
        .collection("users")
        .doc(userRecord.uid)
        .set(userData);

    console.log("Created user document in Firestore:", userRecord.uid);

    // 6. Return success
    return {
      success: true,
      uid: userRecord.uid,
      username: username,
    };
  } catch (error) {
    console.error("Error creating user:", error);
    throw new HttpsError(
        "internal",
        `Failed to create user: ${error.message}`,
    );
  }
});

/**
 * Cloud Function to update user accounts
 * Only callable by admin users
 */
exports.adminUpdateUser = onCall({
  cors: true,
}, async (request) => {
  // 1. Validate authentication
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated",
    );
  }

  // 2. Validate admin role
  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore()
      .collection("users")
      .doc(callerUid)
      .get();

  const callerRole = callerDoc.data() ? callerDoc.data().role : null;
  if (callerRole !== "admin") {
    throw new HttpsError(
        "permission-denied",
        "Only admins can update users",
    );
  }

  // 3. Validate input
  const {uid, username, password, name} = request.data;
  if (!uid) {
    throw new HttpsError(
        "invalid-argument",
        "User UID is required",
    );
  }

  try {
    const updateAuth = {};
    const updateFirestore = {};

    // Handle username update (changes email)
    if (username) {
      updateAuth.email = `${username.toLowerCase()}@daycare.local`;
      updateFirestore.username = username;
    }

    // Handle password update
    if (password) {
      updateAuth.password = password;
    }

    // Handle name update
    if (name) {
      updateFirestore.name = name;
    }

    // 4. Update Firebase Auth if needed
    if (Object.keys(updateAuth).length > 0) {
      await admin.auth().updateUser(uid, updateAuth);
      console.log("Updated user in Auth:", uid);
    }

    // 5. Update Firestore if needed
    if (Object.keys(updateFirestore).length > 0) {
      await admin.firestore()
          .collection("users")
          .doc(uid)
          .update(updateFirestore);
      console.log("Updated user in Firestore:", uid);
    }

    return {
      success: true,
      uid: uid,
    };
  } catch (error) {
    console.error("Error updating user:", error);
    throw new HttpsError(
        "internal",
        `Failed to update user: ${error.message}`,
    );
  }
});

/**
 * Scheduled Cloud Function to clean up old photos
 * Runs daily at midnight UTC
 * Deletes photos older than 14 days from Storage and Firestore
 */
const {onSchedule} = require("firebase-functions/v2/scheduler");

exports.cleanupOldPhotos = onSchedule({
  schedule: "0 0 * * *", // Run daily at midnight UTC
  timeZone: "UTC",
}, async (event) => {
  const admin = require("firebase-admin");
  const db = admin.firestore();
  const storage = admin.storage();

  // Calculate cutoff date (14 days ago)
  const daysToKeep = 14;
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

  // Format as YYYY-MM-DD
  const cutoffDateStr = cutoffDate.toISOString().split("T")[0];

  console.log(`Starting photo cleanup for photos older than ${cutoffDateStr}`);

  try {
    // Query all dailyStatus documents
    const snapshot = await db.collection("dailyStatus").get();

    let deletedPhotos = 0;
    let deletedDocs = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const docDate = data.date;

      if (!docDate) continue;

      // Check if document date is older than cutoff
      if (docDate < cutoffDateStr) {
        const photos = data.photos || [];

        // Delete each photo from Storage
        for (const photo of photos) {
          try {
            const photoUrl = photo.url;
            // Extract storage path from URL
            // URL format: https://firebasestorage.googleapis.com/v0/b/...
            const urlParts = photoUrl.split("/o/");
            if (urlParts.length > 1) {
              const pathPart = urlParts[1].split("?")[0];
              const filePath = decodeURIComponent(pathPart);

              await storage.bucket().file(filePath).delete();
              deletedPhotos++;
              console.log(`Deleted photo: ${filePath}`);
            }
          } catch (error) {
            console.error(`Error deleting photo from storage: ${error.message}`);
            // Continue with other photos even if one fails
          }
        }

        // Delete the Firestore document
        await doc.ref.delete();
        deletedDocs++;
        console.log(`Deleted document: ${doc.id}`);
      }
    }

    console.log(`Cleanup complete. Deleted ${deletedPhotos} photos and ${deletedDocs} documents.`);

    return {
      success: true,
      deletedPhotos: deletedPhotos,
      deletedDocs: deletedDocs,
      cutoffDate: cutoffDateStr,
    };
  } catch (error) {
    console.error("Error during photo cleanup:", error);
    throw error;
  }
});

/**
 * Scheduled Cloud Function to reset todayDisplayStatus at midnight
 * Runs daily at midnight in Mountain Time (America/Denver)
 * Resets all students to NotArrived with empty display status
 */
exports.resetDailyDisplayStatus = onSchedule({
  schedule: "0 0 * * *", // Midnight daily
  timeZone: "America/Denver", // Mountain Time
}, async (event) => {
  const db = admin.firestore();

  // Get today's date in YYYY-MM-DD format
  const now = new Date();
  const today = now.toISOString().split("T")[0];

  console.log(`Starting daily status reset for ${today}`);

  try {
    // Get all students
    const studentsSnapshot = await db
        .collection("users")
        .where("role", "==", "student")
        .get();

    if (studentsSnapshot.empty) {
      console.log("No students found to reset");
      return {success: true, resetCount: 0};
    }

    // Batch update all students
    const batch = db.batch();
    let resetCount = 0;

    for (const doc of studentsSnapshot.docs) {
      batch.update(doc.ref, {
        todayStatus: "NotArrived",
        todayDate: today,
        todayDisplayStatus: {
          mealStatus: false,
          toiletStatus: false,
          sleepStatus: false,
          photosCount: 0,
          isAbsent: false,
        },
        hasUnreadFromStudent: false, // Also clear unread flags
      });
      resetCount++;
    }

    await batch.commit();

    console.log(`Reset status for ${resetCount} students`);

    return {
      success: true,
      resetCount: resetCount,
      resetDate: today,
    };
  } catch (error) {
    console.error("Error resetting daily status:", error);
    throw error;
  }
});

// =============================================================================
// MULTI-TENANCY FUNCTIONS
// =============================================================================

/**
 * Generate a secure random token
 * @param {number} length - Length of token to generate
 * @return {string} Random token string
 */
function generateToken(length = 32) {
  const chars =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let token = "";
  for (let i = 0; i < length; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return token;
}

/**
 * Create an invitation for a user to join a school
 * Callable by school admins
 */
exports.createInvitation = onCall({
  cors: true,
}, async (request) => {
  // 1. Validate authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 2. Validate input
  const {email, role, schoolId} = request.data;
  if (!email || !role || !schoolId) {
    throw new HttpsError(
        "invalid-argument",
        "Email, role, and schoolId are required",
    );
  }

  if (!["admin", "teacher", "parent"].includes(role)) {
    throw new HttpsError(
        "invalid-argument",
        "Invalid role. Must be admin, teacher, or parent",
    );
  }

  try {
    const db = admin.firestore();
    const callerUid = request.auth.uid;

    // 3. Verify caller is admin of the school
    const memberDoc = await db
        .collection("schools")
        .doc(schoolId)
        .collection("members")
        .doc(callerUid)
        .get();

    if (!memberDoc.exists || memberDoc.data().role !== "admin") {
      throw new HttpsError(
          "permission-denied",
          "Only school admins can create invitations",
      );
    }

    // 4. Get school info
    const schoolDoc = await db.collection("schools").doc(schoolId).get();
    if (!schoolDoc.exists) {
      throw new HttpsError("not-found", "School not found");
    }
    const schoolName = schoolDoc.data().name;

    // 5. Check for existing pending invitation
    const existingInvites = await db
        .collection("invitations")
        .where("email", "==", email.toLowerCase())
        .where("schoolId", "==", schoolId)
        .where("status", "==", "pending")
        .get();

    if (!existingInvites.empty) {
      throw new HttpsError(
          "already-exists",
          "A pending invitation already exists for this email",
      );
    }

    // 6. Create invitation
    const token = generateToken();
    const invitation = {
      email: email.toLowerCase(),
      schoolId: schoolId,
      schoolName: schoolName,
      role: role,
      token: token,
      status: "pending",
      createdBy: callerUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const docRef = await db.collection("invitations").add(invitation);

    console.log(`Created invitation ${docRef.id} for ${email} to ${schoolName}`);

    // TODO: Send email with invite link
    // For now, return the token for manual distribution

    return {
      success: true,
      invitationId: docRef.id,
      token: token,
    };
  } catch (error) {
    console.error("Error creating invitation:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to create invitation: ${error.message}`);
  }
});

/**
 * Accept an invitation and create user account
 * Called when a new user registers via invite link
 */
exports.acceptInvitation = onCall({
  cors: true,
}, async (request) => {
  // 1. Validate input
  const {token, password, displayName} = request.data;
  if (!token || !password) {
    throw new HttpsError(
        "invalid-argument",
        "Token and password are required",
    );
  }

  try {
    const db = admin.firestore();

    // 2. Find and validate invitation
    const inviteQuery = await db
        .collection("invitations")
        .where("token", "==", token)
        .where("status", "==", "pending")
        .limit(1)
        .get();

    if (inviteQuery.empty) {
      throw new HttpsError("not-found", "Invalid or expired invitation");
    }

    const inviteDoc = inviteQuery.docs[0];
    const invite = inviteDoc.data();

    // 3. Check if user already exists with this email
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(invite.email);
      // User exists - add them to the school
    } catch (error) {
      // User doesn't exist - create new account
      userRecord = await admin.auth().createUser({
        email: invite.email,
        password: password,
        displayName: displayName || null,
      });

      // Create user document
      await db.collection("users").doc(userRecord.uid).set({
        uid: userRecord.uid,
        email: invite.email,
        username: invite.email.split("@")[0], // Legacy field
        displayName: displayName || null,
        role: "user", // Generic role, specific roles are in memberships
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        schoolIds: [invite.schoolId],
      });
    }

    // 4. Create school membership
    await db
        .collection("schools")
        .doc(invite.schoolId)
        .collection("members")
        .doc(userRecord.uid)
        .set({
          uid: userRecord.uid,
          schoolId: invite.schoolId,
          role: invite.role,
          displayName: displayName || null,
          invitedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    // 5. Update user's schoolIds if they already existed
    await db.collection("users").doc(userRecord.uid).update({
      schoolIds: admin.firestore.FieldValue.arrayUnion(invite.schoolId),
    });

    // 6. Mark invitation as accepted
    await inviteDoc.ref.update({
      status: "accepted",
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`User ${userRecord.uid} accepted invitation to ${invite.schoolName}`);

    return {
      success: true,
      uid: userRecord.uid,
      schoolId: invite.schoolId,
      role: invite.role,
    };
  } catch (error) {
    console.error("Error accepting invitation:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to accept invitation: ${error.message}`);
  }
});

/**
 * Create a new school (tenant)
 * Only callable by super admins
 */
exports.createSchool = onCall({
  cors: true,
}, async (request) => {
  // 1. Validate authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 2. Validate input
  const {name, adminEmail} = request.data;
  const organizationId = request.data.organizationId; // Optional: Link to org

  if (!name || !adminEmail) {
    throw new HttpsError(
        "invalid-argument",
        "School name and admin email are required",
    );
  }

  // 3. Permission Check
  // Allow if Super Admin OR if Organization Admin (and creating for their org)
  const isSuperAdmin = request.auth.token.superAdmin === true;

  if (organizationId) {
    // Check if caller is admin of this organization
    if (!isSuperAdmin) {
      const userDoc = await admin.firestore().collection("users").doc(request.auth.uid).get();
      if (!userDoc.exists || userDoc.data().organizationId !== organizationId) {
        throw new HttpsError("permission-denied", "You are not authorized to create a dayhome for this organization.");
      }
      // Caller is org admin - permission granted
    }
  } else {
    // If no org ID, must be super admin (legacy behavior)
    if (!isSuperAdmin) {
      throw new HttpsError("permission-denied", "Only super admins can create standalone schools.");
    }
  }

  try {
    const db = admin.firestore();

    // 4. Generate School ID (slug + organizationId)
    const nameSlug = name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "");

    // Combine with organizationId if provided: "name-slug_orgId"
    const schoolId = organizationId ?
      `${nameSlug}_${organizationId}` :
      nameSlug;

    const existingSchool = await db.collection("schools").doc(schoolId).get();
    if (existingSchool.exists) {
      throw new HttpsError("already-exists", "A school with this name already exists");
    }

    // 5. Create School Document
    const schoolData = {
      name: name,
      config: request.data.config || {},
      subscription: {
        status: "trial",
        trialEndsAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        ),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (organizationId) {
      schoolData.organizationId = organizationId;
    }

    await db.collection("schools").doc(schoolId).set(schoolData);

    console.log(`Created school: ${schoolId}`);

    // 6. Create Invitation
    const token = generateToken();
    const invitation = {
      email: adminEmail.toLowerCase(),
      schoolId: schoolId,
      schoolName: name,
      role: "admin",
      token: token,
      status: "pending",
      createdBy: request.auth.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (organizationId) {
      invitation.organizationId = organizationId; // Link invitation to org too
    }

    const inviteRef = await db.collection("invitations").add(invitation);

    console.log(`Created admin invitation for ${adminEmail}`);

    return {
      success: true,
      schoolId: schoolId,
      invitationId: inviteRef.id,
      adminInviteToken: token,
    };
  } catch (error) {
    console.error("Error creating school:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to create school: ${error.message}`);
  }
});

/**
 * Create a new organization
 * Only callable by super admins
 */
exports.createOrganization = onCall({
  cors: true,
}, async (request) => {
  // 1. Validate authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // 2. Check for super admin claim
  const isSuperAdmin = request.auth.token.superAdmin === true;
  if (!isSuperAdmin) {
    throw new HttpsError(
        "permission-denied",
        "Only super admins can create organizations",
    );
  }

  // 3. Validate input
  const {name, adminEmail, password} = request.data;
  if (!name || !adminEmail || !password) {
    throw new HttpsError(
        "invalid-argument",
        "Organization name, admin email, and password are required",
    );
  }

  try {
    const db = admin.firestore();

    // 4. Generate organization ID (slug from name)
    const orgId = name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "");

    // Check if org ID already exists
    const existingOrg = await db.collection("organizations").doc(orgId).get();
    if (existingOrg.exists) {
      throw new HttpsError("already-exists", "An organization with this name already exists");
    }

    // 5. Create or Get User
    let userRecord;
    let isNewUser = false;

    try {
      userRecord = await admin.auth().getUserByEmail(adminEmail);
      console.log(`Found existing user: ${userRecord.uid}`);
    } catch (error) {
      if (error.code === "auth/user-not-found") {
        // Create new user
        userRecord = await admin.auth().createUser({
          email: adminEmail,
          password: password,
          displayName: "Admin", // Default display name
        });
        isNewUser = true;
        console.log(`Created new user: ${userRecord.uid}`);
      } else {
        throw error;
      }
    }

    // 6. Create organization document
    const orgData = {
      name: name,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: request.auth.uid,
    };

    await db.collection("organizations").doc(orgId).set(orgData);
    console.log(`Created organization: ${orgId}`);

    // 7. Update User Document
    // Set user as admin of this organization
    const userUpdate = {
      organizationId: orgId,
      role: "admin",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (isNewUser) {
      // Set initial fields for new user
      await db.collection("users").doc(userRecord.uid).set({
        uid: userRecord.uid,
        email: adminEmail,
        username: adminEmail.split("@")[0],
        name: "Admin",
        role: "admin",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        organizationId: orgId,
        schoolIds: [],
      });
    } else {
      // Update existing user
      await db.collection("users").doc(userRecord.uid).set(userUpdate, {merge: true});
    }

    console.log(`Assigned user ${userRecord.uid} as admin for ${orgId}`);

    return {
      success: true,
      organizationId: orgId,
      uid: userRecord.uid,
    };
  } catch (error) {
    console.error("Error creating organization:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", `Failed to create organization: ${error.message}`);
  }
});

// =============================================================================
// DOCUMENT SIGNING FCM NOTIFICATIONS
// =============================================================================

const {onDocumentCreated} = require("firebase-functions/v2/firestore");

/**
 * Send FCM notification when a new signature request is created
 * Triggered automatically when document is created in signatureRequests collection
 */
exports.notifyUserOfNewDocument = onDocumentCreated(
    "signatureRequests/{requestId}",
    async (event) => {
      const requestData = event.data.data();
      const userId = requestData.userId;
      const documentId = requestData.documentId;

      console.log(`New signature request for user ${userId}, document ${documentId}`);

      try {
        const db = admin.firestore();
        const messaging = admin.messaging();

        // Get document details
        const docSnapshot = await db.collection("documents").doc(documentId).get();
        if (!docSnapshot.exists) {
          console.log("Document not found:", documentId);
          return;
        }
        const docData = docSnapshot.data();

        // Get user's FCM token
        const userSnapshot = await db.collection("users").doc(userId).get();
        if (!userSnapshot.exists) {
          console.log("User not found:", userId);
          return;
        }
        const userData = userSnapshot.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          console.log(`User ${userId} has no FCM token, skipping notification`);
          return;
        }

        // Send FCM notification
        const message = {
          notification: {
            title: "New Document to Sign",
            body: `You have a new document: ${docData.title}`,
          },
          data: {
            type: "new_document",
            documentId: documentId,
            requestId: event.params.requestId,
          },
          token: fcmToken,
        };

        const response = await messaging.send(message);
        console.log(`Sent FCM notification to user ${userId}:`, response);
      } catch (error) {
        console.error("Error sending FCM notification:", error);
      // Don't throw - we don't want to fail the document creation if FCM fails
      }
    },
);

// =============================================================================
// CHECKLIST AUTO-SUBMISSION
// =============================================================================

/**
 * Scheduled Cloud Function to auto-submit all checklist records at month-end
 * Runs at 23:59 on the last day of each month in Mountain Time
 * Marks all checklist records for the current month as submitted
 */
exports.autoSubmitMonthlyChecklists = onSchedule({
  schedule: "59 23 28-31 * *", // 23:59 on days 28-31 (we check if it's actually last day)
  timeZone: "America/Denver",
}, async (event) => {
  const db = admin.firestore();
  const now = new Date();

  // Check if today is actually the last day of the month
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  if (tomorrow.getMonth() === now.getMonth()) {
    // Not the last day of the month, skip
    console.log("Not last day of month, skipping auto-submit");
    return {success: true, skipped: true};
  }

  // Get current month in YYYY-MM format
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const currentMonth = `${year}-${month}`;

  console.log(`Starting checklist auto-submission for ${currentMonth}`);

  try {
    // Query all unsubmitted checklist records for this month
    const recordsSnapshot = await db
        .collection("checklist_records")
        .where("month", "==", currentMonth)
        .where("isSubmitted", "==", false)
        .get();

    if (recordsSnapshot.empty) {
      console.log("No unsubmitted records found for this month");
      return {success: true, submittedCount: 0};
    }

    // Batch update all records to submitted
    const batchSize = 500;
    let submittedCount = 0;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of recordsSnapshot.docs) {
      batch.update(doc.ref, {
        isSubmitted: true,
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        submittedBy: "system",
      });
      batchCount++;
      submittedCount++;

      // Commit batch if it reaches the limit
      if (batchCount >= batchSize) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    // Commit any remaining updates
    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`Auto-submitted ${submittedCount} checklist records for ${currentMonth}`);

    return {
      success: true,
      month: currentMonth,
      submittedCount: submittedCount,
    };
  } catch (error) {
    console.error("Error during checklist auto-submission:", error);
    throw error;
  }
});
