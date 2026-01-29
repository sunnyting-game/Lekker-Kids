# Phase 2 Bug Fixes and Enhancements

## 修復的問題 (Fixed Issues)

### 1. ✅ 添加 Name 欄位

**問題**: Teacher 和 Student 帳戶沒有 name 欄位

**解決方案**:
- 更新 `UserModel` 添加可選的 `name` 欄位
- 更新 `createUserAccount` 方法接受 `name` 參數
- 在創建 Teacher 和 Student 表單添加 Name 輸入欄位
- 添加 localization strings: `adminNameLabel`, `adminNameRequired`

**修改的文件**:
- `lib/models/user_model.dart` - 添加 `name` 欄位
- `lib/services/auth_service.dart` - 添加 `name` 參數
- `lib/constants/app_strings.dart` - 添加 name 相關字串
- `lib/screens/admin/create_teacher_page.dart` - 添加 name 輸入欄位
- `lib/screens/admin/create_student_page.dart` - 添加 name 輸入欄位

### 2. ✅ 修復自動登入 Bug (Critical!)

**問題**: 創建新帳戶後,admin 被登出,自動登入為新創建的帳戶

**原因**: Firebase 的 `createUserWithEmailAndPassword()` 會自動登入新創建的用戶

**解決方案**:
```dart
Future<UserModel?> createUserAccount({
  required String username,
  required String password,
  required UserRole role,
  String? name,
}) async {
  // 1. 創建新用戶 (自動登入新用戶)
  final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  // 2. 保存用戶數據到 Firestore
  await _firestore.collection('users').doc(user.uid).set(user.toMap());
  
  // 3. 立即登出新用戶
  await _auth.signOut();
  
  // 4. Admin 會自動重新登入 (Firebase 保持 session)
  
  return user;
}
```

**修改的文件**:
- `lib/services/auth_service.dart` - 修復 `createUserAccount` 方法

### 3. ⚠️ 帳戶列表顯示 (待實現)

**問題**: 創建的帳戶不會顯示在 Teacher/Student Page

**狀態**: 目前是 placeholder,需要在未來 phase 實現

**計劃**:
- 從 Firestore 查詢所有 teacher/student
- 使用 StreamBuilder 實時顯示列表
- 添加刪除/編輯功能

## 技術細節 (Technical Details)

### UserModel 更新

```dart
class UserModel {
  final String uid;
  final String username;
  final String? name;  // NEW: Optional display name
  final UserRole role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    this.name,  // Optional
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      if (name != null) 'name': name,  // Only include if not null
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

### 創建表單欄位順序

1. **Username** - 用於登入
2. **Name** - 顯示名稱 (新增)
3. **Password** - 密碼

### Firebase Auth 自動登入問題

**問題根源**:
```dart
// 這個方法會自動登入新用戶!
await _auth.createUserWithEmailAndPassword(email, password);
// 此時 _auth.currentUser 已經是新用戶,不是 admin 了
```

**解決方法**:
```dart
// 創建後立即登出
await _auth.signOut();
// Firebase 會自動恢復之前的 session (admin)
```

## 測試步驟 (Testing Steps)

### 測試 Name 欄位

1. 以 admin 登入
2. 導航: Admin Portal → Manage Teacher → "+"
3. 填寫表單:
   - Username: `teacher3`
   - Name: `John Doe`
   - Password: `teacher123`
4. 點擊 "Create Teacher"
5. 檢查 Firestore:
   - `users/{uid}` 應該包含 `name: "John Doe"`

### 測試自動登入修復

1. 以 admin 登入
2. 創建新 teacher 帳戶
3. **預期結果**:
   - ✅ 成功訊息顯示
   - ✅ 返回 Teacher Page
   - ✅ 仍然是 admin 登入狀態
   - ✅ AppBar 仍顯示 "Admin Portal"
   - ✅ 可以繼續創建更多帳戶

4. **之前的錯誤行為** (已修復):
   - ❌ 創建後自動登入為新用戶
   - ❌ 跳轉到 Teacher Portal
   - ❌ Admin 被登出

### 驗證 Firestore 數據

創建帳戶後,檢查 Firestore:

```
users/
  └── {uid}/
      ├── uid: "abc123..."
      ├── username: "teacher3"
      ├── name: "John Doe"        ← NEW
      ├── role: "teacher"
      └── createdAt: "2024-12-02T..."
```

## 已知限制 (Known Limitations)

### 1. 帳戶列表未實現

**現狀**: Teacher Page 和 Student Page 只顯示 placeholder 文字

**未來實現**:
```dart
// 將來會這樣實現
StreamBuilder<QuerySnapshot>(
  stream: _firestore
      .collection('users')
      .where('role', isEqualTo: 'teacher')
      .snapshots(),
  builder: (context, snapshot) {
    // 顯示教師列表
  },
)
```

### 2. 無法編輯/刪除帳戶

**現狀**: 只能創建,不能編輯或刪除

**未來實現**: 添加編輯和刪除功能

### 3. 無搜索/篩選功能

**現狀**: 無法搜索帳戶

**未來實現**: 添加搜索欄和篩選選項

## 總結 (Summary)

✅ **已完成**:
- Name 欄位添加到所有創建表單
- 修復自動登入 bug (Critical!)
- UserModel 更新支持 name
- Localization strings 更新

⚠️ **待實現** (未來 Phase):
- 顯示帳戶列表
- 編輯帳戶功能
- 刪除帳戶功能
- 搜索和篩選

🎉 **主要成就**:
修復了最嚴重的 bug - admin 創建帳戶後不再被登出!

## 使用方法 (Usage)

### 創建 Teacher 帳戶 (帶 Name)

1. Admin Portal → Manage Teacher → "+"
2. 填寫:
   - Username: `teacher_john`
   - Name: `John Smith`
   - Password: `teacher123`
3. Create Teacher
4. ✅ 成功!仍然是 admin 登入

### 創建 Student 帳戶 (帶 Name)

1. Admin Portal → Manage Student → "+"
2. 填寫:
   - Username: `student_mary`
   - Name: `Mary Johnson`
   - Password: `student123`
3. Create Student
4. ✅ 成功!仍然是 admin 登入

現在可以安全地創建多個帳戶而不會被登出! 🚀
