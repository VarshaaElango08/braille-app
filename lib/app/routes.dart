import 'package:flutter/material.dart';
import '../features/splash/splash_page.dart';
import '../features/home/home_screen.dart';
import '../features/learning/learning_page.dart';
import '../features/practice/practice_page.dart';
import '../features/challenge/challenge_page.dart';
import '../features/progress/progress_dashboard_page.dart';
import '../features/settings/settings_page.dart';

class AppRoutes {
  static const splash = "/";
  static const home = "/home";
  static const learning = "/learning";
  static const practice = "/practice";
  static const challenge = "/challenge";
  static const dashboard = "/dashboard";
  static const settings = "/settings";

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashPage(),
    home: (_) => const HomeScreen(),
    learning: (_) => const LearningPage(),
    practice: (_) => const PracticePage(),
    challenge: (_) => const ChallengePage(),
    dashboard: (_) => const ProgressDashboardPage(),
    settings: (_) => const SettingsPage(),
  };
}