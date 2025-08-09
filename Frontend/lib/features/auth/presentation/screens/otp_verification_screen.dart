import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/utils/snackbar_helper.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isResending = false;

  void _verifyOtp() {
    if (_otpController.text.length == 6) {
      ref
          .read(authStateProvider.notifier)
          .verifyOtp(email: widget.email, otp: _otpController.text);
    }
  }

  void _resendOtp() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authStateProvider.notifier).resendOtp(email: widget.email);
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

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAwaitingVerification && next.message != null) {
        SnackBarHelper.showError(context, next.message!);
      }
      // FIX: When verification is successful, the state becomes Unauthenticated.
      // The AuthGate will then show the LoginScreen. We just need to pop this screen.
      else if (next is Unauthenticated) {
        Navigator.of(context).pop();
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
        title: Text('Verify Email', style: textTheme.titleLarge),
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
                  'Enter Verification Code',
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
                      : const Text('Verify'),
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
