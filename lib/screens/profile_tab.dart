import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';

class ProfileTab extends StatefulWidget {
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  List<DocumentSnapshot> _watchedMovies = [];
  List<DocumentSnapshot> _watchlistMovies = [];
  
  // Stats data
  int totalWatched = 0;
  int totalWatchlist = 0;
  int totalReviews = 0;
  double avgRating = 0.0;
  int moviesRated5Stars = 0;
  int moviesRated4Stars = 0;
  int moviesRated3Stars = 0;
  int moviesRated2Stars = 0;
  int moviesRated1Star = 0;
  String favoriteYear = 'N/A';
  String mostWatchedMonth = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMoviesData();
  }

  Future<void> _loadUserData() async {
    try {
      if (_auth.currentUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch user data directly from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
        });
      } else {
        // If user doc doesn't exist, create it
        await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
          'email': _auth.currentUser!.email,
          'username': _auth.currentUser!.displayName ?? 'User',
          'bio': '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Reload user data
        final newDoc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();
        setState(() {
          userData = newDoc.data();
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadMoviesData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final snapshot = await _firestore
          .collection('user_movies')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _watchedMovies = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['watched'] == true;
        }).toList();

        _watchlistMovies = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['inWatchlist'] == true && data['watched'] != true;
        }).toList();

        // Calculate stats
        _calculateStats();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading movies data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateStats() {
    // Basic counts
    totalWatched = _watchedMovies.length;
    totalWatchlist = _watchlistMovies.length;
    
    // Reviews count (movies with written reviews)
    totalReviews = _watchedMovies.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final review = data['review']?.toString() ?? '';
      return review.trim().isNotEmpty;
    }).length;

    // Rating statistics
    final ratedMovies = _watchedMovies.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['rating'] != null && data['rating'] > 0;
    }).toList();

    if (ratedMovies.isNotEmpty) {
      double totalRating = 0;
      
      // Reset counters
      moviesRated5Stars = 0;
      moviesRated4Stars = 0;
      moviesRated3Stars = 0;
      moviesRated2Stars = 0;
      moviesRated1Star = 0;
      
      for (var doc in ratedMovies) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = (data['rating'] ?? 0);
        totalRating += rating.toDouble();

        // Count by rating
        if (rating == 5) moviesRated5Stars++;
        else if (rating == 4) moviesRated4Stars++;
        else if (rating == 3) moviesRated3Stars++;
        else if (rating == 2) moviesRated2Stars++;
        else if (rating == 1) moviesRated1Star++;
      }
      avgRating = totalRating / ratedMovies.length;
    }

    // Calculate favorite year
    _calculateFavoriteYear();

    // Calculate most watched month
    _calculateMostWatchedMonth();
  }

  void _calculateFavoriteYear() {
    Map<String, int> yearCounts = {};
    
    for (var doc in _watchedMovies) {
      final data = doc.data() as Map<String, dynamic>;
      final releaseDate = data['releaseDate']?.toString() ?? '';
      if (releaseDate.isNotEmpty) {
        final year = releaseDate.split('-')[0];
        yearCounts[year] = (yearCounts[year] ?? 0) + 1;
      }
    }

    if (yearCounts.isNotEmpty) {
      final sortedYears = yearCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      favoriteYear = sortedYears.first.key;
    }
  }

  void _calculateMostWatchedMonth() {
    Map<String, int> monthCounts = {};
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    for (var doc in _watchedMovies) {
      final data = doc.data() as Map<String, dynamic>;
      final updatedAt = data['updatedAt'] as Timestamp?;
      if (updatedAt != null) {
        final date = updatedAt.toDate();
        final monthKey = monthNames[date.month - 1];
        monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;
      }
    }

    if (monthCounts.isNotEmpty) {
      final sortedMonths = monthCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostWatchedMonth = sortedMonths.first.key;
    }
  }

  Future<void> _showEditProfileDialog() async {
    final TextEditingController usernameController = TextEditingController(
      text: userData?['username'] ?? '',
    );
    final TextEditingController bioController = TextEditingController(
      text: userData?['bio'] ?? '',
    );

    // Save the context before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) => AlertDialog(
            backgroundColor: Color(0xFF1A1F3A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.edit, color: Color(0xFFE535AB)),
                SizedBox(width: 12),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username Field
                  Text(
                    'Username',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Color(0xFF0A0E27),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFE535AB),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(Icons.person, color: Color(0xFFE535AB)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Bio Field
                  Text(
                    'Bio',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: bioController,
                    style: TextStyle(color: Colors.white),
                    maxLines: 4,
                    maxLength: 150,
                    decoration: InputDecoration(
                      hintText: 'Tell us about yourself...',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Color(0xFF0A0E27),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFE535AB),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.info_outline, color: Color(0xFFE535AB)),
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () {
                  usernameController.dispose();
                  bioController.dispose();
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: isSaving ? null : () async {
                    final newUsername = usernameController.text.trim();
                    final newBio = bioController.text.trim();
                    
                    if (newUsername.isEmpty) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Username cannot be empty'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    if (newUsername.length < 3) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Username must be at least 3 characters'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    try {
                      final user = _auth.currentUser;
                      if (user != null) {
                        // Update Firestore
                        await _firestore.collection('users').doc(user.uid).update({
                          'username': newUsername,
                          'bio': newBio,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        
                        // Update local state immediately
                        setState(() {
                          if (userData == null) {
                            userData = {};
                          }
                          userData!['username'] = newUsername;
                          userData!['bio'] = newBio;
                        });
                        
                        usernameController.dispose();
                        bioController.dispose();
                        Navigator.pop(dialogContext);
                        
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error updating profile: $e');
                      setDialogState(() => isSaving = false);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserProfileHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
              ),
            ),
            child: Container(
              margin: EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1F3A),
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white54,
              ),
            ),
          ),
          SizedBox(height: 16),
          // Username
          Text(
            userData?['username'] ?? 'No username',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          // Email
          Text(
            userData?['email'] ?? '',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Bio
          if (userData?['bio'] != null && userData!['bio'].toString().isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF1A1F3A).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                userData!['bio'],
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          SizedBox(height: 12),
          // Role Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: userData?['role'] == 'admin'
                    ? [Colors.amber, Colors.orange]
                    : [Color(0xFFE535AB), Color(0xFF9D4EDD)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userData?['role'] == 'admin' ? 'ADMIN' : 'USER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text('Please login to view profile', 
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE535AB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0E27),
            Color(0xFF1A1F3A),
          ],
        ),
      ),
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE535AB)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Settings Button
                  Padding(
                    padding: EdgeInsets.only(top: 40, right: 16),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                        onPressed: _showSettingsDialog,
                      ),
                    ),
                  ),
                  
                  // User Profile Header
                  _buildUserProfileHeader(),
                  
                  SizedBox(height: 8),
                  
                  // Top Stats
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTopStat(totalWatched.toString(), 'Watched'),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white24,
                        ),
                        _buildTopStat(totalWatchlist.toString(), 'Watchlist'),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white24,
                        ),
                        _buildTopStat(totalReviews.toString(), 'Reviews'),
                      ],
                    ),
                  ),
                  
                  // Stats Section
                  _buildStatSection(),
                  
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStatSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F3A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFE535AB).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFFE535AB), size: 20),
              SizedBox(width: 8),
              Text(
                'STATISTICS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          _buildStatRow('Films watched', totalWatched.toString()),
          _buildStatRow('Watchlist', totalWatchlist.toString()),
          _buildStatRow('Reviews written', totalReviews.toString()),
          _buildStatRow('Mean rating', avgRating > 0 ? '${avgRating.toStringAsFixed(1)} ★' : '0.0 ★'),
          _buildStatRow('Favorite year', favoriteYear),
          _buildStatRow('Most active month', mostWatchedMonth),
          
          SizedBox(height: 24),
          
          // Rating Distribution
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                'RATING DISTRIBUTION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildRatingBar('5 Stars', moviesRated5Stars, Colors.green),
          _buildRatingBar('4 Stars', moviesRated4Stars, Colors.lightGreen),
          _buildRatingBar('3 Stars', moviesRated3Stars, Colors.orange),
          _buildRatingBar('2 Stars', moviesRated2Stars, Colors.deepOrange),
          _buildRatingBar('1 Star', moviesRated1Star, Colors.red),
        ],
      ),
    );
  }

  Widget _buildTopStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, int count, Color color) {
    final total = totalWatched > 0 ? totalWatched : 1;
    final percentage = count / total;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'film' : 'films'}',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Color(0xFF0A0E27),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.settings, color: Color(0xFFE535AB)),
            SizedBox(width: 12),
            Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person, color: Color(0xFFE535AB)),
                title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
                subtitle: Text('Update your username and bio', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditProfileDialog();
                },
              ),
              Divider(color: Colors.white24, height: 20),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
                subtitle: Text('Sign out of your account', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Color(0xFF1A1F3A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Logout', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Logout', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldLogout == true) {
                    try {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      await authService.logout();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    } catch (e) {
                      print('Error logging out: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error logging out'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}