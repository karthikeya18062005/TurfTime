import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:http/http.dart' as http;

// 1. Define the states
@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAwaitingVerification extends AuthState {
  // For registration
  final String email;
  final String? message;
  AuthAwaitingVerification(this.email, {this.message});
}

class AuthAwaitingLoginVerification extends AuthState {
  // For login
  final String email;
  final String? message;
  AuthAwaitingLoginVerification(this.email, {this.message});
}

class AuthAwaitingPasswordReset extends AuthState {
  // For forgot password
  final String email;
  final String? message;
  AuthAwaitingPasswordReset(this.email, {this.message});
}

class Authenticated extends AuthState {
  final String role;
  Authenticated(this.role);
}

class Unauthenticated extends AuthState {
  final String? message;
  Unauthenticated({this.message});
}

// 2. State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _authRepository.getToken();
    final role = await _authRepository.getRole();
    if (token != null && role != null) {
      state = Authenticated(role);
    } else {
      state = Unauthenticated();
    }
  }

  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      await _authRepository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      state = AuthAwaitingVerification(email);
    } catch (e) {
      state = Unauthenticated(message: e.toString());
    }
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    state = AuthLoading();
    try {
      await _authRepository.verifyOtp(email: email, otp: otp);
      state = Unauthenticated(
        message: 'Email verified successfully! Please log in.',
      );
    } catch (e) {
      state = AuthAwaitingVerification(email, message: e.toString());
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      await _authRepository.resendOtp(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      await _authRepository.login(email: email, password: password);
      state = AuthAwaitingLoginVerification(email);
    } catch (e) {
      state = Unauthenticated(message: e.toString());
    }
  }

  Future<void> verifyLoginOtp({
    required String email,
    required String otp,
  }) async {
    state = AuthLoading();
    try {
      await _authRepository.verifyLoginOtp(email: email, otp: otp);
      final role = await _authRepository.getRole();
      if (role != null) {
        state = Authenticated(role);
      } else {
        throw Exception("Role not found after OTP verification.");
      }
    } catch (e) {
      state = AuthAwaitingLoginVerification(email, message: e.toString());
    }
  }

  Future<void> resendLoginOtp({required String email}) async {
    try {
      await _authRepository.resendLoginOtp(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword({required String email}) async {
    state = AuthLoading();
    try {
      await _authRepository.forgotPassword(email: email);
      state = AuthAwaitingPasswordReset(email);
    } catch (e) {
      state = Unauthenticated(message: e.toString());
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = AuthLoading();
    try {
      await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      state = Unauthenticated(
        message: 'Password reset successfully. Please log in.',
      );
    } catch (e) {
      state = AuthAwaitingPasswordReset(email, message: e.toString());
    }
  }

  Future<void> logoutUser() async {
    await _authRepository.logout();
    state = Unauthenticated();
  }
}

// 3. Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(http.Client());
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
