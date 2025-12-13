🎬 MovieMate - Personal Movie Tracker
A Flutter app for discovering, rating, and reviewing movies using TMDB API and Firebase.

✨ Features
For Users:

📱 Browse movies by category (Trending, Popular, etc.)

⭐ Rate movies (1-5 stars) and write reviews

📋 Create watchlists and mark movies as watched

📊 View personal statistics (watched films, average rating)

👤 Edit profile with bio and username

For Admins:

👥 Manage all users

🔧 Enable/disable user accounts

🎟️ Generate registration codes

🛠️ Tech Stack
Flutter - Cross-platform app framework

Firebase - Authentication & database

TMDB API - Movie information

Provider - State management

🚀 Quick Setup
Clone & Install:

bash
git clone [repository-url]
flutter pub get
Firebase Setup:

Create Firebase project

Add google-services.json (Android) or GoogleService-Info.plist (iOS)

Enable Email/Password auth

Create Firestore database

TMDB Setup:

Get free API key from TMDB

Add to movie_service.dart:

dart
static const String tmdbApiKey = 'YOUR_KEY_HERE';
Run:

bash
flutter run
📁 Project Structure
text
lib/
├── models/           # Data models (Movie, User)
├── screens/          # All app screens
├── services/         # Firebase & API logic
└── main.dart         # App entry point
🔐 Default Admin Code
Use MOVIEMATE when signing up for your first admin account.

🎨 Design
Dark theme with purple/pink accents

Gradient backgrounds

Card-based layouts

Responsive for all screen sizes

🗂️ Database Collections
Users:

json
{
  "username": "John",
  "email": "john@email.com",
  "role": "user",
  "disabled": false,
  "bio": "Movie lover"
}
User Movies:

json
{
  "userId": "abc123",
  "movieId": 12345,
  "rating": 4,
  "watched": true,
  "review": "Great movie!"
}
🎯 Key Screens
Login/Register - Secure access

Discover - Browse TMDB movies

Movie Details - View info and rate

Profile - Stats and settings

Admin Panel - User management (admins only)

🐛 Common Issues
Movies not loading?

Check TMDB API key is valid

Can't login?

Verify Firebase auth is enabled

Build errors?

Ensure Firebase config files are in correct folders
