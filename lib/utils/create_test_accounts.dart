import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

import '../models/user_model.dart';

/// Helper script to create test accounts
/// This should be run once to set up initial test users
/// 
/// To use this:
/// 1. Temporarily change main.dart to call this instead of MyApp
/// 2. Run the app once
/// 3. Revert main.dart back to normal
class CreateTestAccounts extends StatefulWidget {
  const CreateTestAccounts({super.key});

  @override
  State<CreateTestAccounts> createState() => _CreateTestAccountsState();
}

class _CreateTestAccountsState extends State<CreateTestAccounts> {

  final List<String> _logs = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _createAccounts();
  }

  Future<void> _createAccounts() async {
    setState(() {
      _isCreating = true;
      _logs.clear();
    });

    await _createAccount('admin', 'admin123', UserRole.admin);
    await _createAccount('teacher', 'teacher123', UserRole.teacher);
    await _createAccount('student', 'student123', UserRole.student);

    setState(() {
      _isCreating = false;
      _logs.add('\n✅ All accounts created successfully!');
      _logs.add('\nYou can now revert main.dart and run the app normally.');
    });
  }

  Future<void> _createAccount(String username, String password, UserRole role) async {
    setState(() {
      _logs.add('Creating $role account: $username...');
    });

    // NOTE: This script is obsolete with the new Cloud Functions security model.
    // Accounts must now be created via the Admin Portal by an authenticated admin.
    // To create the first admin, use the Firebase Console.
    
    setState(() {
      _logs.add('❌ Script obsolete. Please use Admin Portal to create accounts.');
      _logs.add('   (Requires authenticated admin session)');
    });

    /*
    try {
      final user = await _authService.createUserAccount(
        username: username,
        password: password,
        role: role,
      );

      if (user != null) {
        setState(() {
          _logs.add('✅ Created $role: $username (UID: ${user.uid})');
        });
      } else {
        setState(() {
          _logs.add('❌ Failed to create $role: $username');
        });
      }
    } catch (e) {
      setState(() {
        _logs.add('❌ Error creating $role: $e');
      });
    }

    // Sign out after creating each account
    await _authService.signOut();
    */
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Create Test Accounts'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isCreating)
                const LinearProgressIndicator()
              else
                const SizedBox(height: 4),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main function to run the account creation script
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const CreateTestAccounts());
}
