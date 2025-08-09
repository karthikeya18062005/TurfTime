import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/utils/snackbar_helper.dart';
import 'package:frontend/features/auth/utils/validators.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authStateProvider.notifier)
          .loginUser(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  Future<void> _launchTurfOwnerForm() async {
    final Uri url = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSfTaULGOia-4ims8ci4-q69Kt2pQJ0lCL31axzsrGgVOYS3Vg/viewform?usp=header',
    );
    if (!await launchUrl(url)) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Could not open the form.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAwaitingLoginVerification) {
        Navigator.of(
          context,
        ).pushNamed('/verify-otp-login', arguments: next.email);
      } else if (next is Unauthenticated && next.message != null) {
        if (previous is AuthLoading) {
          SnackBarHelper.showError(context, next.message!);
        } else if (next.message!.startsWith('Email verified') ||
            next.message!.startsWith('Password reset')) {
          SnackBarHelper.showSuccess(context, next.message!);
        }
      }
    });

    final authState = ref.watch(authStateProvider);

    return Scaffold(
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
                  Icon(
                    Icons.sports_soccer,
                    size: 60,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login to TurfTime',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                    validator: (value) =>
                        value!.isEmpty ? 'Password cannot be empty' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value!),
                          ),
                          Text('Remember me', style: textTheme.bodySmall),
                        ],
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                        child: Text(
                          'Forgot Password?',
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Register Now',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  InkWell(
                    onTap: _launchTurfOwnerForm,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '🏟️ Own a turf? Apply to list it here.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.grey[600],
                        ),
                      ),
                    ),
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
