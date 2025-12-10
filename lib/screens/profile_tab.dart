import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';

class ProfileTab extends StatefulWidget {
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;

  List<DocumentSnapshot> _watchedMovies = [];
  
  // Stats data
  int totalMovies = 0;
  int totalReviews = 0;
  double avgRating = 0.0;
  String totalRuntime = '0h 0m';
  Map<String, int> genreDistribution = {};

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

      final data = await _authService.getUserData();
      if (data != null) {
        setState(() {
          userData = data;
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
    totalMovies = _watchedMovies.length;
    
    final ratedMovies = _watchedMovies.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['rating'] != null && data['rating'] > 0;
    }).toList();
    
    totalReviews = ratedMovies.length;

    // Average rating
    if (totalReviews > 0) {
      double totalRating = 0;
      for (var doc in ratedMovies) {
        final data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] ?? 0).toDouble();
      }
      avgRating = totalRating / totalReviews;
    }

    // Calculate total runtime (assuming average 2h movie)
    int totalMinutes = totalMovies * 120;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    totalRuntime = '${hours}h ${minutes}m';

    // Calculate genre distribution
    _calculateGenreDistribution();
  }

  void _calculateGenreDistribution() {
    genreDistribution.clear();
    for (var doc in _watchedMovies) {
      final data = doc.data() as Map<String, dynamic>;
      final genres = data['genres'] as List<dynamic>?;
      if (genres != null) {
        for (var genre in genres) {
          genreDistribution[genre.toString()] = 
              (genreDistribution[genre.toString()] ?? 0) + 1;
        }
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    final TextEditingController usernameController = TextEditingController(
      text: userData?['username'] ?? '',
    );
    final TextEditingController bioController = TextEditingController(
      text: userData?['bio'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: Color(0xFF0A0E27),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.person, color: Color(0xFFE535AB)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: bioController,
                maxLines: 4,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: Color(0xFF0A0E27),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.description, color: Color(0xFFE535AB)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              final newBio = bioController.text.trim();
              
              if (newUsername.isEmpty) return;

              try {
                final user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).update({
                    'username': newUsername,
                    'bio': newBio,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  setState(() {
                    userData?['username'] = newUsername;
                    userData?['bio'] = newBio;
                  });
                  
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile updated!'),
                      backgroundColor: Color(0xFFE535AB),
                    ),
                  );
                }
              } catch (e) {
                print('Error updating profile: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating profile'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE535AB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save'),
          ),
        ],
      ),
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
              border: Border.all(color: Color(0xFFE535AB), width: 3),
            ),
            child: CircleAvatar(
              radius: 47,
              backgroundColor: Color(0xFF1A1F3A),
              child: userData?['photoURL'] != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: userData!['photoURL'],
                        width: 94,
                        height: 94,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white54,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : Icon(
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
          SizedBox(height: 12),
          // Bio
          if (userData?['bio'] != null && userData!['bio'].isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                userData!['bio'],
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          SizedBox(height: 16),
          // Edit Profile Button
          ElevatedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: Icon(Icons.edit, size: 18),
            label: Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE535AB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  Navigator.of(context).pushNamed('/login');
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
                        icon: Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: _showSettingsDialog,
                      ),
                    ),
                  ),
                  
                  // User Profile Header (Centered)
                  _buildUserProfileHeader(),
                  
                  SizedBox(height: 8),
                  
                  // Top Stats
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTopStat(totalMovies.toString(), 'Films'),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white24,
                        ),
                        _buildTopStat(totalReviews.toString(), 'Reviews'),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white24,
                        ),
                        _buildTopStat(avgRating.toStringAsFixed(1), 'Avg Rating'),
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
    final sortedGenres = genreDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
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
          
          _buildStatRow('Films watched', totalMovies.toString()),
          _buildStatRow('Total runtime', totalRuntime),
          _buildStatRow('Mean rating', avgRating > 0 ? '${avgRating.toStringAsFixed(1)} ★' : '0.0 ★'),
          
          if (genreDistribution.isNotEmpty) ...[
            SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.category, color: Color(0xFF9D4EDD), size: 18),
                SizedBox(width: 8),
                Text(
                  'TOP GENRES',
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
            
            ...sortedGenres.take(5).map((entry) {
              final percentage = entry.value / (totalMovies == 0 ? 1 : totalMovies);
              return _buildGenreBar(entry.key, percentage, entry.value);
            }).toList(),
          ],
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

  Widget _buildGenreBar(String genre, double percentage, int count) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                genre,
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
                    gradient: LinearGradient(
                      colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                    ),
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
        title: Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person, color: Color(0xFFE535AB)),
                title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditProfileDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: Color(0xFF4CAF50)),
                title: Text('Privacy Settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  // Implement privacy settings
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications, color: Color(0xFF2196F3)),
                title: Text('Notifications', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  // Implement notification settings
                },
              ),
              ListTile(
                leading: Icon(Icons.help, color: Color(0xFFFF9800)),
                title: Text('Help & Support', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  // Implement help & support
                },
              ),
              Divider(color: Colors.white24, height: 20),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _authService.logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  } catch (e) {
                    print('Error logging out: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out'),
                        backgroundColor: Colors.red,
                      ),
                    );
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