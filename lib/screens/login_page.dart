import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!success && mounted) {
        final errorMsg = authProvider.errorMessage ?? AppStrings.errorGeneric;
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg, 
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            duration: AppDurations.snackBar,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(AppSpacing.paddingMedium),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight,
              AppColors.background,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.paddingXLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Animated Logo
                  Image.asset(
                    'assets/images/logo3.png',
                    height: 188,
                    fit: BoxFit.contain,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(delay: 200.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: AppSpacing.marginLarge),
                  
                  // "Welcome Back" Text (AppName removed)
                  Text(
                    AppStrings.loginWelcome,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: AppSpacing.paddingHuge),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.paddingLarge),
                      decoration: AppDecorations.card,
                      child: Column(
                        children: [
                          // Username Field
                          TextFormField(
                            controller: _usernameController,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                              labelText: AppStrings.loginUsername,
                              hintText: 'Enter your username',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.loginUsernameRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.marginMedium),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                              labelText: AppStrings.loginPassword,
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.loginPasswordRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: AppSpacing.paddingXLarge),

                    // Login Button
                    Selector<AuthProvider, bool>(
                      selector: (_, provider) => provider.isLoading,
                      builder: (context, isLoading, child) {
                        return SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: AppSpacing.loadingIndicatorSize,
                                    width: AppSpacing.loadingIndicatorSize,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppStrings.loginButton,
                                    style: AppTextStyles.button.copyWith(fontSize: 18),
                                  ),
                          ),
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
