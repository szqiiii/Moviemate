import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_movies_screen.dart';
import 'screens/admin_reviews_screen.dart';
import 'screens/admin_screen_codes.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MovieMateApp(),
    ),
  );
}

class MovieMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieMate',
      theme: ThemeData(
        primaryColor: Color(0xFF0A0E27),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFFE535AB),
          primary: Color(0xFF0A0E27),
        ),
        scaffoldBackgroundColor: Color(0xFF0A0E27),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0A0E27),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/admin': (context) => AdminDashboard(),
        '/admin/users': (context) => AdminUsersScreen(),
        '/admin/movies': (context) => AdminMoviesScreen(),
        '/admin/reviews': (context) => AdminReviewsScreen(),
        '/admin/codes': (context) => AdminCodesScreen(),
      },
    );
  }
}

/// Checks authentication state and role, then redirects accordingly
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        
        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: authService.isAdmin(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }
              
              // Redirect based on role
              if (roleSnapshot.data == true) {
                return AdminDashboard();
              } else {
                return DashboardScreen();
              }
            },
          );
        }
        
        // Not logged in, show login
        return LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_filter, color: Color(0xFFE535AB), size: 64),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE535AB)),
              ),
              SizedBox(height: 16),
              Text(
                'MovieMate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}