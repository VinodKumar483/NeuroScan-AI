import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';

import '../database/database_helper.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Please fill in all fields.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showMessage('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      showMessage('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check whether email already exists
      final existingUser = await DatabaseHelper.instance.getUserByEmail(email);

      if (!mounted) return;

      if (existingUser != null) {
        showMessage('This email is already registered.');
        return;
      }

      // Hash password using BCrypt
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      // Save user in SQLite database
      await DatabaseHelper.instance.insertUser(
        name: name,
        email: email,
        passwordHash: passwordHash,
      );

      if (!mounted) return;

      showMessage(
        'Account created successfully! Please login.',
        isError: false,
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      final error = e.toString().toLowerCase();

      if (error.contains('unique') || error.contains('constraint')) {
        showMessage('This email is already registered.');
      } else {
        showMessage('Registration failed. Please try again.');
        debugPrint('REGISTER ERROR: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message, {bool isError = true}) {
    final accentColor = isError ? const Color(0xFFFF5C78) : AppColors.primary;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF102949),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: accentColor,
                  size: 23,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    final isVisible = isConfirmPassword
        ? isConfirmPasswordVisible
        : isPasswordVisible;

    return TextField(
      controller: controller,
      obscureText: (isPassword || isConfirmPassword) && !isVisible,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 21),
        suffixIcon: (isPassword || isConfirmPassword)
            ? IconButton(
                onPressed: () {
                  setState(() {
                    if (isConfirmPassword) {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    } else {
                      isPasswordVisible = !isPasswordVisible;
                    }
                  });
                },
                icon: Icon(
                  isVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.045),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
      ),
    );
  }

  Widget fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Join NeuroScan AI',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 30),

              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.055),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('Full Name'),
                        const SizedBox(height: 12),
                        buildTextField(
                          hint: 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                          controller: nameController,
                        ),

                        const SizedBox(height: 22),

                        fieldLabel('Email Address'),
                        const SizedBox(height: 12),
                        buildTextField(
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          controller: emailController,
                        ),

                        const SizedBox(height: 22),

                        fieldLabel('Password'),
                        const SizedBox(height: 12),
                        buildTextField(
                          hint: 'Create a password',
                          icon: Icons.lock_outline_rounded,
                          controller: passwordController,
                          isPassword: true,
                        ),

                        const SizedBox(height: 22),

                        fieldLabel('Confirm Password'),
                        const SizedBox(height: 12),
                        buildTextField(
                          hint: 'Confirm your password',
                          icon: Icons.lock_outline_rounded,
                          controller: confirmPasswordController,
                          isConfirmPassword: true,
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.82),
                                  const Color(
                                    0xFF168CBF,
                                  ).withValues(alpha: 0.72),
                                  const Color(
                                    0xFF0D2440,
                                  ).withValues(alpha: 0.94),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.42),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 7),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: Colors.white60,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'CREATE ACCOUNT',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
