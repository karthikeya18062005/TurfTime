import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Abstract class defining the contract for our repository
abstract class AuthRepository {
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> verifyOtp({required String email, required String otp});
  Future<void> resendOtp({required String email});

  Future<void> login({required String email, required String password});

  Future<void> verifyLoginOtp({required String email, required String otp});
  Future<void> resendLoginOtp({required String email});

  Future<void> forgotPassword({required String email});
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<void> logout();
  Future<String?> getToken();
  Future<String?> getRole();
}

// Implementation of the repository
class AuthRepositoryImpl implements AuthRepository {
  final http.Client _client;

  final String _baseUrl = "http://10.0.2.2:5000/api/auth";

  AuthRepositoryImpl(this._client);

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed.');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'OTP verification failed.');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resendOtp({required String email}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to resend OTP.');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid credentials.');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> verifyLoginOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/verify-otp-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final role = data['user']?['role'];

        if (token != null && role != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          await prefs.setString('userRole', role);
        } else {
          throw Exception('Token or role not found in response.');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid OTP.');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resendLoginOtp({required String email}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/resend-otp-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to resend OTP.');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send reset email.');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to reset password.');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userRole');
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  @override
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole');
  }
}
