import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/movie_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MovieService _movieService = MovieService();
  
  Map<String, dynamic> stats = {
    'totalUsers': 0,
    'totalAdmins': 0,
    'activeUsers': 0,
    'disabledUsers': 0,
    'totalMovies': 0,
    'totalReviews': 0,
    'averageRating': 0.0,
    'reviewsThisMonth': 0,
    'usersThisMonth': 0,
    'topRatedMovies': [],
    'recentActivity': [],
    'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
  };
  
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => loading = true);
    
    try {
      // Get all users
      final authService = Provider.of<AuthService>(context, listen: false);
      final allUsers = await authService.getAllUsers();
      
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      int totalUsers = allUsers.length;
      int totalAdmins = allUsers.where((u) => u['role'] == 'admin').length;
      int activeUsers = allUsers.where((u) => u['disabled'] != true).length;
      int disabledUsers = allUsers.where((u) => u['disabled'] == true).length;
      
      // Count users created this month
      int usersThisMonth = allUsers.where((user) {
        final createdAt = user['createdAt'];
        if (createdAt == null) return false;
        try {
          final date = (createdAt as Timestamp).toDate();
          return date.isAfter(firstDayOfMonth);
        } catch (e) {
          return false;
        }
      }).length;
      
      // Get movies count
      final moviesSnapshot = await _movieService.getAllMovies().first;
      int totalMovies = moviesSnapshot.docs.length;
      
      // Get all reviews
      final reviewsSnapshot = await _firestore
          .collection('user_movies')
          .where('rating', isGreaterThan: 0)
          .get();
      
      int totalReviews = reviewsSnapshot.docs.length;
      
      // Calculate rating statistics
      double totalRating = 0;
      Map<int, int> ratingDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      int reviewsThisMonth = 0;
      
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        final rating = data['rating'];
        if (rating != null && rating > 0) {
          final ratingInt = (rating is int ? rating : (rating as double).toInt());
          totalRating += ratingInt;
          ratingDist[ratingInt] = (ratingDist[ratingInt] ?? 0) + 1;
          
          // Check if review is from this month
          final updatedAt = data['updatedAt'];
          if (updatedAt != null) {
            try {
              final date = (updatedAt as Timestamp).toDate();
              if (date.isAfter(firstDayOfMonth)) {
                reviewsThisMonth++;
              }
            } catch (e) {}
          }
        }
      }
      
      double averageRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;
      
      // Get top rated movies (movies with highest average ratings)
      Map<String, Map<String, dynamic>> movieRatings = {};
      
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        final movieId = data['movieId']?.toString();
        final movieTitle = data['movieTitle'] ?? 'Unknown';
        final posterPath = data['posterPath'] ?? '';
        final rating = data['rating'];
        
        if (movieId != null && rating != null && rating > 0) {
          if (!movieRatings.containsKey(movieId)) {
            movieRatings[movieId] = {
              'movieId': movieId,
              'movieTitle': movieTitle,
              'posterPath': posterPath,
              'totalRating': 0.0,
              'count': 0,
            };
          }
          
          movieRatings[movieId]!['totalRating'] += (rating is int ? rating.toDouble() : rating as double);
          movieRatings[movieId]!['count']++;
        }
      }
      
      // Calculate averages and sort
      List<Map<String, dynamic>> topRatedMovies = movieRatings.values.map((movie) {
        movie['averageRating'] = movie['totalRating'] / movie['count'];
        return movie;
      }).toList();
      
      topRatedMovies.sort((a, b) {
        // First sort by average rating
        final ratingCompare = (b['averageRating'] as double).compareTo(a['averageRating'] as double);
        if (ratingCompare != 0) return ratingCompare;
        // Then by number of reviews
        return (b['count'] as int).compareTo(a['count'] as int);
      });
      
      // Take top 5
      topRatedMovies = topRatedMovies.take(5).toList();
      
      // Get recent activity (last 10 reviews)
      final recentReviews = reviewsSnapshot.docs.toList();
      recentReviews.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aTime = aData['updatedAt'] as Timestamp?;
        final bTime = bData['updatedAt'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        return bTime.compareTo(aTime);
      });
      
      List<Map<String, dynamic>> recentActivity = recentReviews
          .take(10)
          .map((doc) => doc.data())
          .toList();
      
      setState(() {
        stats = {
          'totalUsers': totalUsers,
          'totalAdmins': totalAdmins,
          'activeUsers': activeUsers,
          'disabledUsers': disabledUsers,
          'totalMovies': totalMovies,
          'totalReviews': totalReviews,
          'averageRating': averageRating,
          'reviewsThisMonth': reviewsThisMonth,
          'usersThisMonth': usersThisMonth,
          'topRatedMovies': topRatedMovies,
          'recentActivity': recentActivity,
          'ratingDistribution': ratingDist,
        };
        loading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading analytics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A0E27),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE535AB)),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAnalytics,
                color: Color(0xFFE535AB),
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Header
                      Text(
                        'Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Main Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            'Total Movies',
                            stats['totalMovies'].toString(),
                            Icons.movie,
                            Color(0xFF9D4EDD),
                          ),
                          _buildStatCard(
                            'Total Users',
                            stats['totalUsers'].toString(),
                            Icons.people,
                            Color(0xFFE535AB),
                          ),
                          _buildStatCard(
                            'Total Reviews',
                            stats['totalReviews'].toString(),
                            Icons.rate_review,
                            Color(0xFFFF6B9D),
                          ),
                          _buildStatCard(
                            'Avg Rating',
                            stats['averageRating'].toStringAsFixed(1),
                            Icons.star,
                            Color(0xFFFFA726),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Users Stats Section
                      _buildSectionTitle('User Statistics'),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2F4A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow('Total Users', stats['totalUsers'].toString(), Icons.people),
                            Divider(color: Colors.white12, height: 24),
                            _buildStatRow('Active Users', stats['activeUsers'].toString(), Icons.check_circle, valueColor: Colors.green),
                            Divider(color: Colors.white12, height: 24),
                            _buildStatRow('Disabled Users', stats['disabledUsers'].toString(), Icons.block, valueColor: Colors.red),
                            Divider(color: Colors.white12, height: 24),
                            _buildStatRow('Admins', stats['totalAdmins'].toString(), Icons.admin_panel_settings, valueColor: Color(0xFFE535AB)),
                            Divider(color: Colors.white12, height: 24),
                            _buildStatRow('New This Month', stats['usersThisMonth'].toString(), Icons.person_add, valueColor: Color(0xFF9D4EDD)),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Reviews Stats Section
                      _buildSectionTitle('Review Statistics'),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2F4A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow('Total Reviews', stats['totalReviews'].toString(), Icons.rate_review),
                            Divider(color: Colors.white12, height: 24),
                            _buildStatRow('Reviews This Month', stats['reviewsThisMonth'].toString(), Icons.trending_up, valueColor: Color(0xFF9D4EDD)),
                            Divider(color: Colors.white12, height: 24),
                            _buildStatRow('Average Rating', stats['averageRating'].toStringAsFixed(2), Icons.star, valueColor: Colors.amber),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Rating Distribution
                      _buildSectionTitle('Rating Distribution'),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2F4A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            for (int i = 5; i >= 1; i--)
                              Padding(
                                padding: EdgeInsets.only(bottom: i > 1 ? 12 : 0),
                                child: _buildRatingBar(i, stats['ratingDistribution'][i] ?? 0, stats['totalReviews']),
                              ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Top Rated Movies
                      _buildSectionTitle('Top Rated Movies'),
                      SizedBox(height: 12),
                      if (stats['topRatedMovies'].isEmpty)
                        Container(
                          padding: EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2F4A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.movie, color: Colors.white30, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'No rated movies yet',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...stats['topRatedMovies'].map<Widget>((movie) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2F4A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                // Rank
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${stats['topRatedMovies'].indexOf(movie) + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                
                                // Movie Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        movie['movieTitle'] ?? 'Unknown',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${movie['count']} reviews',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Rating
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      movie['averageRating'].toStringAsFixed(1),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      
                      SizedBox(height: 24),
                      
                      // Recent Activity
                      _buildSectionTitle('Recent Activity'),
                      SizedBox(height: 12),
                      if (stats['recentActivity'].isEmpty)
                        Container(
                          padding: EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2F4A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.history, color: Colors.white30, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'No recent activity',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...stats['recentActivity'].map<Widget>((activity) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2F4A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE535AB).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.rate_review,
                                    color: Color(0xFFE535AB),
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(color: Colors.white, fontSize: 14),
                                          children: [
                                            TextSpan(
                                              text: activity['username'] ?? 'Someone',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(text: ' reviewed '),
                                            TextSpan(
                                              text: activity['movieTitle'] ?? 'a movie',
                                              style: TextStyle(color: Color(0xFFE535AB)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          ...List.generate(
                                            activity['rating'] is int
                                                ? activity['rating']
                                                : (activity['rating'] as double).toInt(),
                                            (index) => Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 14,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            _getTimeAgo(activity['updatedAt']),
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2F4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFFE535AB), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Row(
      children: [
        Row(
          children: [
            Text(
              '$stars',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ),
        SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8,
            ),
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}