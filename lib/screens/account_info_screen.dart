import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/auth_repository.dart';
import '../theme/app_theme.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authRepo = context.read<AuthRepository>();
      final user = authRepo.currentUser;

      _usernameController.text = user?.displayName ?? '';
      _emailController.text = user?.email ?? '';
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // ===============================
  // IMAGE PICK & UPLOAD (WEB + MOBILE)
  // ===============================

  Future<void> _pickImage() async {
    // Warn user about web limitations
    if (kIsWeb) {
      _showErrorSnackBar(
        'Profile picture upload is not available on web yet. Please use the mobile app or configure Firebase Storage CORS.',
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
      });

      final bytes = await image.readAsBytes();

      setState(() {
        _imageBytes = bytes;
      });

      final authRepo = context.read<AuthRepository>();
      
      // Add timeout to prevent infinite loading
      await authRepo.uploadProfilePictureBytes(bytes)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Upload timed out. Please check your internet connection.');
            },
          );

      if (mounted) {
        _showSuccessSnackBar('Profile picture updated');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Image upload failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===============================
  // UPDATE USERNAME
  // ===============================

  Future<void> _updateUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      _showErrorSnackBar('Username cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.updateUserProfile(
        displayName: _usernameController.text.trim(),
      );

      _showSuccessSnackBar('Username updated');
    } catch (e) {
      _showErrorSnackBar('Failed to update username: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===============================
  // UPDATE EMAIL
  // ===============================

  Future<void> _updateEmail() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.updateEmail(_emailController.text.trim());

      _showSuccessSnackBar(
        'Verification email sent to new address',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update email: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===============================
  // UPDATE PASSWORD
  // ===============================

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      _showErrorSnackBar('Fill all password fields');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.updatePassword(
        currentPassword: _passwordController.text,
        newPassword: _newPasswordController.text,
      );

      _passwordController.clear();
      _newPasswordController.clear();

      _showSuccessSnackBar('Password updated');
    } catch (e) {
      _showErrorSnackBar('Failed to update password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===============================
  // UI
  // ===============================

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final user = authRepo.currentUser;

    final isEmailAuth = user?.providerData
            .any((p) => p.providerId == 'password') ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Information')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // PROFILE IMAGE
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.lightGrey,
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                        child: (_imageBytes == null &&
                                user?.photoURL == null)
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: AppTheme.textSecondary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.taskBlue,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // USERNAME
                _sectionTitle('USERNAME'),
                _card(
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _fullButton(
                        'Update Username',
                        _updateUsername,
                      ),
                    ],
                  ),
                ),

                if (isEmailAuth) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle('EMAIL'),
                  _card(
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _fullButton(
                          'Update Email',
                          _updateEmail,
                        ),
                      ],
                    ),
                  ),
                ],

                if (isEmailAuth) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle('PASSWORD'),
                  _card(
                    child: Column(
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Current Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'New Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _fullButton(
                          'Update Password',
                          _updatePassword,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // ===============================
  // HELPERS
  // ===============================

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: AppTheme.textSecondary),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }

  Widget _fullButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}
