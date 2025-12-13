# 🎬 MovieMate - Your Personal Movie Diary

A comprehensive Flutter application for discovering, tracking, rating, and reviewing movies. MovieMate integrates with The Movie Database (TMDB) API to provide real-time movie information and uses Firebase for authentication and data storage.

## 📱 Features

### User Features
- **🔐 Authentication System**
  - Secure email/password registration and login
  - Password reset functionality
  - Role-based access control (User/Admin)
  - Registration code system for admin accounts

- **🎥 Movie Discovery**
  - Browse movies by categories: Trending, Popular, Top Rated, Upcoming
  - Real-time data from TMDB API
  - Beautiful movie posters with ratings
  - Detailed movie information (synopsis, release date, ratings)

- **📝 Personal Movie Diary**
  - Rate movies with a 5-star system
  - Write detailed reviews
  - Mark movies as watched
  - Create and manage a personal watchlist
  - Track your movie watching history

- **🎨 Beautiful UI/UX**
  - Modern gradient-based design
  - Smooth animations and transitions
  - Responsive layout for all screen sizes
  - Dark theme optimized for movie browsing
  - Intuitive navigation with bottom tab bar

### Admin Features
- **👥 User Management**
  - View all registered users
  - Manage user roles
  - Enable/disable user accounts

- **🎟️ Registration Code Management**
  - Generate registration codes for admin access
  - Set usage limits for codes
  - Track code usage statistics
  - Activate/deactivate codes

## 🛠️ Technologies Used

- **Frontend Framework**: Flutter & Dart
- **Backend Services**: 
  - Firebase Authentication
  - Cloud Firestore (NoSQL Database)
- **External APIs**: The Movie Database (TMDB) API
- **State Management**: Provider Pattern
- **Network Requests**: HTTP package
- **Image Caching**: cached_network_image

## 📋 Prerequisites

Before running this project, ensure you have:

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Firebase account
- TMDB API key (free registration at [themoviedb.org](https://www.themoviedb.org/))

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/moviemate.git
cd moviemate
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration

#### Android Setup:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Add an Android app to your Firebase project
4. Download `google-services.json`
5. Place it in `android/app/` directory

#### iOS Setup:
1. Add an iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/` directory

### 4. Enable Firebase Services

In Firebase Console, enable:
- **Authentication** → Email/Password sign-in method
- **Firestore Database** → Create database in production mode

### 5. Configure TMDB API

1. Sign up at [TMDB](https://www.themoviedb.org/signup)
2. Get your API key from account settings
3. Open `lib/services/movie_service.dart`
4. Replace the API key:
```dart
static const String tmdbApiKey = 'YOUR_TMDB_API_KEY_HERE';
```

### 6. Run the Application
```bash
flutter run
```

## 📊 Database Schema

### Firestore Collections

#### `users`
```
{
  "uid": String,
  "email": String,
  "username": String,
  "role": String ("user" | "admin"),
  "disabled": Boolean (optional),
  "createdAt": Timestamp
}
```

#### `user_movies`
```
{
  "userId": String,
  "movieId": String,
  "movieTitle": String,
  "posterPath": String,
  "overview": String,
  "rating": Number (0-5),
  "review": String,
  "watched": Boolean,
  "inWatchlist": Boolean,
  "releaseDate": String,
  "voteAverage": Number,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

#### `registration_codes`
```
{
  "code": String,
  "role": String ("admin" | "user"),
  "maxUses": Number,
  "usedCount": Number,
  "active": Boolean,
  "generatedBy": String,
  "createdAt": Timestamp,
  "lastUsedAt": Timestamp (optional)
}
```

## 🏗️ Project Structure

```
lib/
├── models/              # Data models
│   └── tmdb_movie.dart
├── screens/             # UI screens
│   ├── dashboard_screen.dart
│   ├── discover_tab.dart
│   ├── search_tab.dart
│   ├── diary_tab.dart
│   ├── profile_tab.dart
│   ├── movie_details_screen.dart
│   ├── login_screen.dart
│   └── signup_screen.dart
├── services/            # Business logic & API calls
│   ├── auth_service.dart
│   ├── movie_service.dart
│   └── registration_service.dart
├── widgets/             # Reusable widgets
│   └── bottom_nav_bar.dart
└── main.dart           # App entry point
```

## 🎯 Key Features Explained

### Movie Categories
- **Trending**: Movies trending this week
- **Popular**: Most popular movies currently
- **Top Rated**: Highest-rated movies of all time
- **Upcoming**: Movies coming soon to theaters

### Rating System
- Users can rate movies from 1 to 5 stars
- Ratings are saved to personal diary
- Movies automatically marked as "watched" when rated

### Watchlist
- Add movies to watch later
- Quick toggle on movie details page
- Separate from watched movies

## 🔑 Default Admin Code

For initial setup, use the following admin registration code:
```
MOVIEMATE
```

After creating your first admin account, you can generate additional codes through the admin panel.

## 🎨 Color Scheme

The app uses a modern dark theme with vibrant accents:
- **Primary**: `#E535AB` (Pink)
- **Secondary**: `#9D4EDD` (Purple)
- **Background**: `#0A0E27` to `#1A1F3A` (Dark gradient)
- **Cards**: `#2A2F4A` (Dark blue-gray)

## 📱 Screenshots

### User Flow
1. **Login Screen** - Secure authentication
2. **Discover Tab** - Browse movies by category
3. **Movie Details** - View full information and add ratings
4. **Diary Tab** - Personal collection of watched movies
5. **Profile Tab** - User settings and logout

### Admin Flow
1. **Admin Dashboard** - User management
2. **Registration Codes** - Generate and manage access codes

## 🐛 Troubleshooting

### Common Issues

**Issue**: Build fails with Firebase errors
- **Solution**: Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct directory

**Issue**: Movies not loading
- **Solution**: Verify TMDB API key is correct and active

**Issue**: Cannot create admin account
- **Solution**: Make sure to toggle "Have an admin registration code?" and enter: `MOVIEMATE`

## 🤝 Contributing

This is an academic project. If you'd like to contribute:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 👥 Team Members

- [Steffi Asari] - Developer
- [Pricicive Villocino] - Developer
- [Joshua Kyle Elman] - Developer

## 📝 Course Information

- **Subject**: CCE106 - Flutter Development
- **Project Type**: Mobile Application Development
- **Academic Year**: [2025]

## 📄 License

This project is created for educational purposes.

## 🙏 Acknowledgments

- [The Movie Database (TMDB)](https://www.themoviedb.org/) for providing the movie API
- Firebase for backend services
- Flutter team for the amazing framework
- All open-source packages used in this project

## 📧 Contact

For questions or support, contact:
- Email: [s.asari.550231@gmail.com]
- GitHub: [@szqiiii](https://github.com/szqiiii)

---

