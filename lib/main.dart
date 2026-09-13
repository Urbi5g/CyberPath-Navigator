import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'features/stages/stages_progress_screen.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/auth/login/login_screen.dart';
import 'features/roadmaps/roadmaps_explorer_screen.dart';
import 'features/profile/profile_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CyberPathApp());
}

class CyberPathApp extends StatelessWidget {
  const CyberPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CyberPath Navigator',
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/roadmaps_explorer': (context) => const RoadmapsExplorerScreen(),
        '/profile_badges':(context) => const ProfileScreen(),
        '/stages_progress_screen':(context) => const StagesProgressScreen(),
      },
    );
  }
}
