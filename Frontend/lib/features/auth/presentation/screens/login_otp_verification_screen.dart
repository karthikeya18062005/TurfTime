import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/screens/auth_gate.dart';
import 'package:frontend/features/auth/utils/snackbar_helper.dart';
import 'package:pinput/pinput.dart';

class LoginOtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const LoginOtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<LoginOtpVerificationScreen> createState() =>
      _LoginOtpVerificationScreenState();
}

class _LoginOtpVerificationScreenState
    extends ConsumerState<LoginOtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isResending = false;

  void _verifyOtp() {
    if (_otpController.text.length == 6) {
      ref
          .read(authStateProvider.notifier)
          .verifyLoginOtp(email: widget.email, otp: _otpController.text);
    }
  }

  void _resendOtp() async {
    setState(() => _isResending = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .resendLoginOtp(email: widget.email);
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'New OTP sent to ${widget.email}');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // FIX: This listener now handles navigating to the home screen on success.
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAwaitingLoginVerification && next.message != null) {
        SnackBarHelper.showError(context, next.message!);
      } else if (next is Authenticated) {
        // On successful login, clear the stack and go to the AuthGate,
        // which will then build the correct home page.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (Route<dynamic> route) => false,
        );
      }
    });

    final authState = ref.watch(authStateProvider);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('2-Step Verification', style: textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter Security Code',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'A 6-digit code has been sent to\n${widget.email}',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Pinput(
                  length: 6,
                  controller: _otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                  onCompleted: (pin) => _verifyOtp(),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authState is AuthLoading ? null : _verifyOtp,
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
                      : const Text('Verify Login'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: textTheme.bodyMedium,
                    ),
                    _isResending
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : TextButton(
                            onPressed: _resendOtp,
                            child: Text(
                              'Resend OTP',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
