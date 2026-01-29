const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

// 初始化 Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

// 要設定為 Super Admin 的 UID (請在這裡填入你的 UID)
const targetUid = "D3cA2pt5ltbboEtmy8xrmbvWi563";

async function setSuperAdmin() {
  try {
    console.log(`正在為使用者 ${targetUid} 設定 Super Admin 權限...`);

    // 設定 custom claims
    await admin.auth().setCustomUserClaims(targetUid, {superAdmin: true});

    // 驗證是否設定成功
    const user = await admin.auth().getUser(targetUid);
    console.log("--- 設定成功！ ---");
    console.log(`User Email: ${user.email}`);
    console.log(`Claims:`, user.customClaims);

    console.log("\n請注意：使用者必須「登出再重新登入」才會生效！");
  } catch (error) {
    console.error("設定失敗:", error);
  }
}

setSuperAdmin();
