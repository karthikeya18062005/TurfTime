import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:frontend/features/auth/presentation/screens/login_otp_verification_screen.dart';
import 'package:frontend/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the new auth screens and providers
import 'features/auth/presentation/screens/auth_gate.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/registration_screen.dart';
import 'features/auth/presentation/screens/otp_verification_screen.dart';
// Import the new role-based home screens

// --- THEME DATA DEFINITIONS (from previous step, unchanged) ---
final _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFF006A60),
  onPrimary: const Color(0xFFFFFFFF),
  secondary: const Color(0xFF00897B),
  onSecondary: const Color(0xFFFFFFFF),
  tertiary: const Color(0xFFFE8F00), // Accent Color for CTAs
  onTertiary: const Color(0xFFFFFFFF),
  error: const Color(0xFFB00020),
  onError: const Color(0xFFFFFFFF),
  surface: const Color(0xFFFCFCFC),
  onSurface: const Color(0xFF1A1C1C),
  surfaceContainerHighest: const Color(0xFFDAE5E2),
  outline: const Color(0xFFBDBDBD),
);

final _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xFF4DDAC8),
  onPrimary: const Color(0xFF003731),
  secondary: const Color(0xFF00A99D),
  onSecondary: const Color(0xFF004D40),
  tertiary: const Color(0xFFFFB300), // Accent Color for CTAs
  onTertiary: const Color(0xFF432C00),
  error: const Color(0xFFCF6679),
  onError: const Color(0xFF000000),
  surface: const Color(0xFF1A1C1C),
  onSurface: const Color(0xFFE2E3E2),
  surfaceContainerHighest: const Color(0xFF3F4947),
  outline: const Color(0xFF424242),
);

final _textTheme = TextTheme(
  displayLarge: GoogleFonts.tourney(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  ),
  headlineLarge: GoogleFonts.tourney(fontSize: 32, fontWeight: FontWeight.w400),
  headlineMedium: GoogleFonts.tourney(
    fontSize: 28,
    fontWeight: FontWeight.w400,
  ),
  titleLarge: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.w500),
  titleMedium: GoogleFonts.oswald(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  ),
  titleSmall: GoogleFonts.oswald(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  ),
  bodyLarge: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  ),
  bodyMedium: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  ),
  bodySmall: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  ),
  labelLarge: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  ),
  labelMedium: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  ),
  labelSmall: GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  ),
);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TurfTime',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: _lightColorScheme,
        textTheme: _textTheme,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: _darkColorScheme,
        textTheme: _textTheme,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/forgot-password': (context) =>
            const ForgotPasswordScreen(), // <-- NEW
        '/reset-password': (context) {
          // <-- NEW
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return ResetPasswordScreen(email: email);
        },
        '/verify-otp': (context) {
          // For registration
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return OtpVerificationScreen(email: email);
        },
        '/verify-otp-login': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return LoginOtpVerificationScreen(email: email);
        },
      },
    );
  }
}
