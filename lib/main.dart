import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'repositories/task_repository.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 MUST be awaited before using any Firebase service
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 Notifications (skip for Web)
  if (!kIsWeb) {
    await NotificationService().initialize();
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        Provider<TaskRepository>(
          create: (_) => TaskRepository(),
        ),
      ],
      child: MaterialApp(
        title: 'TaskWask',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(AppAnimations.splashDuration, () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    final authRepo = context.read<AuthRepository>();

    return StreamBuilder(
      stream: authRepo.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.taskBlue,
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return FutureBuilder<bool>(
            future: authRepo.isSessionValid(),
            builder: (context, sessionSnapshot) {
              if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.taskBlue,
                    ),
                  ),
                );
              }

              if (sessionSnapshot.data == true) {
                return const HomeScreen();
              } else {
                // Session expired → sign out safely
                Future.microtask(() async {
                  await authRepo.signOut();
                });
                return const LoginScreen();
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}