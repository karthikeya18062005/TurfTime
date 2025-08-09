import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/utils/snackbar_helper.dart';
import 'package:frontend/features/auth/utils/validators.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authStateProvider.notifier)
          .resetPassword(
            email: widget.email,
            otp: _otpController.text.trim(),
            newPassword: _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAwaitingPasswordReset && next.message != null) {
        SnackBarHelper.showError(context, next.message!);
      } else if (next is Unauthenticated && next.message != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password', style: textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter OTP and New Password',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'OTP',
                      prefixIcon: Icon(Icons.pin),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.length != 6 ? 'Enter a 6-digit OTP' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          );
                        },
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: authState is AuthLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.tertiary,
                      foregroundColor: colorScheme.onTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
                    ),
                    child: authState is AuthLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
