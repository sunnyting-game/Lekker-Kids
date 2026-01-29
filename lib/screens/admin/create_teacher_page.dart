import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloud_functions_service.dart';
import '../../models/user_model.dart';

class CreateTeacherPage extends StatefulWidget {
  const CreateTeacherPage({super.key});

  @override
  State<CreateTeacherPage> createState() => _CreateTeacherPageState();
}

class _CreateTeacherPageState extends State<CreateTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _cloudFunctions = CloudFunctionsService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createTeacher() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the current user's organizationId
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final organizationId = authProvider.currentUser?.organizationId;

        await _cloudFunctions.createUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: UserRole.teacher,
          organizationId: organizationId,
        );

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.format(
                  AppStrings.adminAccountCreated,
                  [AppStrings.teacherWelcome],
                ),
              ),
              backgroundColor: Colors.green,
              duration: AppDurations.snackBarDuration,
            ),
          );

          // Navigate back
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.format(
                  AppStrings.adminAccountCreationFailed,
                  [AppStrings.teacherWelcome, e.toString()],
                ),
              ),
              backgroundColor: AppColors.error,
              duration: AppDurations.snackBarDuration,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminCreateTeacherTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: AppStrings.adminUsernameLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.adminUsernameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.marginMedium),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppStrings.adminNameLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.adminNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.marginMedium),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: AppStrings.adminPasswordLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                obscureText: true,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.adminPasswordRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.paddingXLarge),
              ElevatedButton(
                onPressed: _isLoading ? null : _createTeacher,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingXXLarge,
                    vertical: AppSpacing.paddingLarge,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: AppSpacing.loadingIndicatorSize,
                        width: AppSpacing.loadingIndicatorSize,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSpacing.loadingIndicatorStroke,
                          color: AppColors.textWhite,
                        ),
                      )
                    : Text(
                        AppStrings.format(
                          AppStrings.adminCreateButton,
                          [AppStrings.teacherWelcome],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
