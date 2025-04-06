import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/edit_screen.dart';
import '../db/idea_database.dart';

/// Named route constants
class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String edit = '/edit';
}

/// Route generator to manage named navigation
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case AppRoutes.resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());

      case AppRoutes.home:
        // ✅ No longer need to pass db here — HomeScreen fetches it from ModalRoute
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(), 
          settings: settings, // still pass settings so it can read arguments
        );

      case AppRoutes.edit:
        if (args is Map<String, dynamic>) {
          final db = args['db'] as IdeaDatabase;
          final existingIdea = args['idea'] as Idea?;
          return MaterialPageRoute(
            builder: (_) => EditScreen(db: db, existingIdea: existingIdea),
          );
        }
        return _errorRoute('Invalid arguments for EditScreen');

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
