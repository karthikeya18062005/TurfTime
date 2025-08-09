import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/utils/snackbar_helper.dart';
import 'package:frontend/features/auth/utils/validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authStateProvider.notifier)
          .forgotPassword(email: _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAwaitingPasswordReset) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/reset-password', arguments: next.email);
      } else if (next is Unauthenticated &&
          next.message != null &&
          previous is AuthLoading) {
        SnackBarHelper.showError(context, next.message!);
      }
    });

    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password', style: textTheme.titleLarge),
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
                    'Reset Your Password',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your email and we will send you an OTP to reset your password.',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
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
                        : const Text('Send OTP'),
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
