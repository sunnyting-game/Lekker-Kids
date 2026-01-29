import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../viewmodels/admin/edit_user_view_model.dart';
import '../../widgets/admin/avatar_picker_widget.dart';

class EditUserPage extends StatefulWidget {
  final UserModel user;

  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _nameController = TextEditingController(text: widget.user.name ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateUser(EditUserViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    // Update ViewModel with form data
    viewModel.username = _usernameController.text;
    viewModel.name = _nameController.text;
    viewModel.password = _passwordController.text;

    final success = await viewModel.updateUser();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
      Navigator.pop(context);
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditUserViewModel(user: widget.user),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit ${widget.user.role.toString().split('.').last}'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLarge),
          child: Consumer<EditUserViewModel>(
            builder: (context, viewModel, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar section (students only)
                    if (widget.user.role == UserRole.student) ...[
                      Center(
                        child: AvatarPickerWidget(
                          selectedAvatar: viewModel.selectedAvatar,
                          currentAvatarUrl: viewModel.currentAvatarUrl,
                          onPickAvatar: viewModel.pickAvatar,
                          onUploadAvatar: viewModel.uploadAvatar,
                          isLoading: viewModel.isUpdating,
                          isUploading: viewModel.isUploadingAvatar,
                          showUploadButton: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.marginLarge),
                    ],
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: AppStrings.adminUsernameLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                      ),
                      enabled: !viewModel.isUpdating,
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
                      enabled: !viewModel.isUpdating,
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
                        labelText: 'New Password (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                        helperText: 'Leave blank to keep current password',
                      ),
                      obscureText: true,
                      enabled: !viewModel.isUpdating,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.marginLarge),
                    ElevatedButton(
                      onPressed: viewModel.isUpdating
                          ? null
                          : () => _handleUpdateUser(viewModel),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.paddingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                      ),
                      child: viewModel.isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update User'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
