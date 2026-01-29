# Phase 2 Troubleshooting

## 問題: App Crash 和 UI 沒有更新

### 症狀
1. 點擊 "Create Teacher" 後 app crash
2. 重開 app 後沒有看到 "Manage Teacher" 和 "Manage Student" 按鈕
3. Admin portal 變回舊的樣子

### 原因分析

#### 1. Hot Restart 不夠
Hot restart (`r`) 有時候不會完全重新加載所有代碼,特別是:
- 新增的文件
- 修改的 imports
- 結構性改變

#### 2. 可能的 Crash 原因
創建帳戶時 crash 可能是因為:
- Firebase 權限問題
- Firestore 規則限制
- 網絡連接問題

### 解決方案

#### Step 1: Full Restart (完全重啟)

**停止當前 app:**
```powershell
# 在 terminal 按 q 停止 app
```

**完全重新運行:**
```powershell
flutter run -d chrome
# 或
flutter run -d windows
```

**不要用 hot restart (`r`),要完全重新啟動!**

#### Step 2: 驗證代碼

確認 `lib/screens/portals/admin_portal.dart` 包含按鈕:

```dart
body: Center(
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.paddingXLarge),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherPage(),
              ),
            );
          },
          child: const Text(AppStrings.adminManageTeacher),
        ),
        const SizedBox(height: AppSpacing.marginLarge),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentPage(),
              ),
            );
          },
          child: const Text(AppStrings.adminManageStudent),
        ),
      ],
    ),
  ),
),
```

#### Step 3: 檢查 Firebase 權限

如果創建帳戶時 crash,檢查 Firestore 規則:

**Firebase Console → Firestore Database → Rules**

應該是:
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

**問題**: Admin 創建其他用戶時,會寫入不是自己 UID 的文檔!

**修復**: 更新規則允許 admin 寫入:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

**或更安全的版本** (只允許 admin):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.auth.uid == userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

#### Step 4: 檢查 Console 錯誤

在 Chrome DevTools 或 terminal 查看錯誤訊息:

**Chrome:**
1. 按 F12 打開 DevTools
2. 查看 Console tab
3. 尋找紅色錯誤訊息

**Terminal:**
查看 `flutter run` 的輸出

#### Step 5: 測試步驟

1. **完全重啟 app**
   ```powershell
   flutter run -d chrome
   ```

2. **登入 admin**
   - Username: `admin`
   - Password: `admin123`

3. **確認看到兩個按鈕**
   - "Manage Teacher"
   - "Manage Student"

4. **測試創建帳戶**
   - 點擊 "Manage Teacher"
   - 點擊右上角 "+"
   - 輸入 username: `teacher2`
   - 輸入 password: `teacher123`
   - 點擊 "Create Teacher"

5. **查看結果**
   - 如果成功: 綠色 snackbar + 返回 Teacher Page
   - 如果失敗: 紅色 snackbar 顯示錯誤訊息

### 常見錯誤和解決方法

#### 錯誤 1: "Permission denied"
**原因**: Firestore 規則不允許寫入
**解決**: 更新 Firestore 規則 (見 Step 3)

#### 錯誤 2: "Network error"
**原因**: 沒有網絡連接或 Firebase 配置錯誤
**解決**: 
- 檢查網絡連接
- 確認 `firebase_options.dart` 配置正確

#### 錯誤 3: "email-already-in-use"
**原因**: Username 已經存在
**解決**: 使用不同的 username

#### 錯誤 4: 看不到按鈕
**原因**: Hot restart 沒有完全更新代碼
**解決**: 
1. 停止 app (按 `q`)
2. 完全重新運行: `flutter run -d chrome`

### 調試技巧

#### 1. 添加 Debug Print

在 `create_teacher_page.dart` 的 `_createTeacher` 方法開始添加:

```dart
Future<void> _createTeacher() async {
  print('DEBUG: Create teacher button pressed');
  print('DEBUG: Username: ${_usernameController.text}');
  
  if (_formKey.currentState!.validate()) {
    print('DEBUG: Form validated');
    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Calling createUserAccount...');
      final user = await _authService.createUserAccount(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        role: UserRole.teacher,
      );
      print('DEBUG: User created: ${user?.username}');
      // ...
```

#### 2. 檢查 AuthService

確認 `lib/services/auth_service.dart` 的 `createUserAccount` 方法存在並正常工作。

### 快速檢查清單

- [ ] 完全重啟 app (不是 hot restart)
- [ ] 確認 `admin_portal.dart` 有按鈕代碼
- [ ] 更新 Firestore 規則允許寫入
- [ ] 檢查 Console 錯誤訊息
- [ ] 確認 Firebase 配置正確
- [ ] 測試網絡連接

### 如果還是不行

請提供:
1. Console 的完整錯誤訊息
2. Firestore 規則截圖
3. `flutter run` 的完整輸出

這樣我可以更準確地診斷問題!
