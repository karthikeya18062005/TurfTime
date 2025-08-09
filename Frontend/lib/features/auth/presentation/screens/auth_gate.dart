import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/screens/login_otp_verification_screen.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:frontend/features/home/admin_home_screen.dart';
import 'package:frontend/features/home/turf_owner_home_screen.dart';
import 'package:frontend/features/home/user_home_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState is Authenticated) {
      switch (authState.role) {
        case 'user':
          return const UserHomeScreen();
        case 'turfOwner':
          return const TurfOwnerHomeScreen();
        case 'admin':
          return const AdminHomeScreen();
        default:
          return const LoginScreen();
      }
    }

    if (authState is AuthInitial || authState is AuthLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // FIX: AuthGate is now the single source of truth for navigation.
    if (authState is AuthAwaitingVerification) {
      return OtpVerificationScreen(email: authState.email);
    }
    if (authState is AuthAwaitingLoginVerification) {
      return LoginOtpVerificationScreen(email: authState.email);
    }

    return const LoginScreen();
  }
}
