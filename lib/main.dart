import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set default credentials using AuthService
  await AuthService().setDefaultUser();
  
  runApp(MovieMateApp());
}

class MovieMateApp extends StatelessWidget {
  final Color brandPurple = Color(0xFF1e1e2e);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieMate',
      theme: ThemeData(
        primaryColor: brandPurple,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF9d4edd),
          primary: brandPurple,
        ),
        scaffoldBackgroundColor: brandPurple,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          hintStyle: TextStyle(color: Colors.grey[700]),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashCheck(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}

/// Shows a loading indicator while checking login state, then navigates.
class SplashCheck extends StatefulWidget {
  @override
  State<SplashCheck> createState() => _SplashCheckState();
}

class _SplashCheckState extends State<SplashCheck> {
  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  void _checkLoginState() async {
    await Future.delayed(Duration(milliseconds: 800));
    
    bool loggedIn = await AuthService().isLoggedIn();
    
    if (loggedIn) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9d4edd)),
        ),
      ),
      backgroundColor: Color(0xFF1e1e2e),
    );
  }
}