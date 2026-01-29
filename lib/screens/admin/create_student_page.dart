import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../viewmodels/admin/create_student_view_model.dart';
import '../../widgets/admin/avatar_picker_widget.dart';

class CreateStudentPage extends StatefulWidget {
  const CreateStudentPage({super.key});

  @override
  State<CreateStudentPage> createState() => _CreateStudentPageState();
}

class _CreateStudentPageState extends State<CreateStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateStudent(CreateStudentViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    // Get the current user's organizationId
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final organizationId = authProvider.currentUser?.organizationId;

    // Update ViewModel with form data
    viewModel.username = _usernameController.text;
    viewModel.password = _passwordController.text;
    viewModel.name = _nameController.text;
    viewModel.organizationId = organizationId;

    final user = await viewModel.createStudent();

    if (!mounted) return;

    if (user != null) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.format(
              AppStrings.adminAccountCreated,
              [AppStrings.studentWelcome],
            ),
          ),
          backgroundColor: Colors.green,
          duration: AppDurations.snackBarDuration,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } else if (viewModel.errorMessage != null) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.format(
              AppStrings.adminAccountCreationFailed,
              [AppStrings.studentWelcome, viewModel.errorMessage!],
            ),
          ),
          backgroundColor: AppColors.error,
          duration: AppDurations.snackBarDuration,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateStudentViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.adminCreateStudentTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingLarge),
          child: Consumer<CreateStudentViewModel>(
            builder: (context, viewModel, _) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar picker
                    AvatarPickerWidget(
                      selectedAvatar: viewModel.selectedAvatar,
                      onPickAvatar: viewModel.pickAvatar,
                      isLoading: viewModel.isCreating,
                      showUploadButton: false,
                    ),
                    const SizedBox(height: AppSpacing.marginLarge),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: AppStrings.adminUsernameLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                      ),
                      enabled: !viewModel.isCreating,
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
                      enabled: !viewModel.isCreating,
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
                      enabled: !viewModel.isCreating,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.adminPasswordRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.paddingXLarge),
                    ElevatedButton(
                      onPressed: viewModel.isCreating
                          ? null
                          : () => _handleCreateStudent(viewModel),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingXXLarge,
                          vertical: AppSpacing.paddingLarge,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                      ),
                      child: viewModel.isCreating
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
                                [AppStrings.studentWelcome],
                              ),
                            ),
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
